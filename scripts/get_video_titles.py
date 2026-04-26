#!/usr/bin/env python3
import argparse
import json
import math
import os
import re
import sys
from datetime import datetime, timezone
from html import unescape
from pathlib import Path
from typing import Callable, Dict, List, Optional
from urllib import error, parse, request

YOUTUBE_API_URL = "https://www.googleapis.com/youtube/v3/videos"
URL_ATTR_PATTERN = re.compile(r"<(?:iframe|a)\b[^>]*\b(?:src|href)\s*=\s*['\"]([^'\"]+)['\"]", re.IGNORECASE)
VIDEO_ID_PATTERN = re.compile(r"^[A-Za-z0-9_-]{6,}$")


def extract_video_id(url: str) -> Optional[str]:
    url = url.strip()
    if not url:
        return None

    parsed = parse.urlparse(url)
    if parsed.scheme not in {"http", "https"}:
        return None

    host = parsed.netloc.lower()
    if host.startswith("www."):
        host = host[4:]
    if host.startswith("m."):
        host = host[2:]

    video_id: Optional[str] = None

    if host == "youtu.be":
        path_parts = [part for part in parsed.path.split("/") if part]
        if path_parts:
            video_id = path_parts[0]

    elif host in {"youtube.com", "youtube-nocookie.com"}:
        path_parts = [part for part in parsed.path.split("/") if part]
        query = parse.parse_qs(parsed.query)

        if path_parts and path_parts[0] in {"embed", "shorts", "v", "live"}:
            if len(path_parts) > 1:
                video_id = path_parts[1]
        elif path_parts and path_parts[0] == "watch":
            video_id = query.get("v", [None])[0]
        else:
            video_id = query.get("v", [None])[0]

    if not video_id:
        return None

    video_id = video_id.strip().split("?")[0].split("&")[0]
    if not VIDEO_ID_PATTERN.match(video_id):
        return None

    return video_id


def collect_youtube_urls_from_html(html: str) -> List[str]:
    urls: List[str] = []
    seen = set()

    for match in URL_ATTR_PATTERN.finditer(html):
        candidate = unescape(match.group(1).strip())
        if not candidate:
            continue

        if extract_video_id(candidate) is None:
            continue

        if candidate in seen:
            continue

        seen.add(candidate)
        urls.append(candidate)

    return urls


def collect_video_ids(book_dir: Path, youtube_list_path: Path) -> List[str]:
    video_ids = set()

    for html_file in sorted(book_dir.rglob("*.html")):
        html = html_file.read_text(encoding="utf-8")
        for url in collect_youtube_urls_from_html(html):
            video_id = extract_video_id(url)
            if video_id:
                video_ids.add(video_id)

    if youtube_list_path.exists():
        for line in youtube_list_path.read_text(encoding="utf-8").splitlines():
            video_id = extract_video_id(line)
            if video_id:
                video_ids.add(video_id)

    return sorted(video_ids)


def parse_titles_from_api_payload(payload: dict) -> Dict[str, str]:
    titles: Dict[str, str] = {}

    for item in payload.get("items", []):
        if not isinstance(item, dict):
            continue

        video_id = item.get("id")
        snippet = item.get("snippet", {})
        title = snippet.get("title") if isinstance(snippet, dict) else None

        if not isinstance(video_id, str) or not isinstance(title, str):
            continue

        normalized_title = title.strip()
        if not normalized_title:
            continue

        titles[video_id] = normalized_title

    return titles


def fetch_json(url: str) -> dict:
    req = request.Request(url=url, headers={"Accept": "application/json"})
    with request.urlopen(req, timeout=30) as response:
        body = response.read().decode("utf-8")
    return json.loads(body)


def fetch_titles(
    video_ids: List[str],
    api_key: str,
    batch_size: int = 50,
    http_get_json: Callable[[str], dict] = fetch_json
) -> Dict[str, str]:
    if not video_ids:
        return {}

    if batch_size <= 0:
        raise ValueError("batch_size must be greater than zero")

    titles: Dict[str, str] = {}
    total_batches = math.ceil(len(video_ids) / batch_size)

    for index in range(0, len(video_ids), batch_size):
        batch = video_ids[index:index + batch_size]
        batch_number = index // batch_size + 1

        query = parse.urlencode(
            {
                "part": "snippet",
                "id": ",".join(batch),
                "maxResults": len(batch),
                "key": api_key
            }
        )
        url = f"{YOUTUBE_API_URL}?{query}"

        payload = None
        for attempt in range(1, 4):
            try:
                payload = http_get_json(url)
                break
            except (error.HTTPError, error.URLError, TimeoutError, json.JSONDecodeError) as exc:
                if attempt == 3:
                    print(
                        f"[warn] Batch {batch_number}/{total_batches} failed after {attempt} attempts: {exc}",
                        file=sys.stderr
                    )
                else:
                    print(
                        f"[warn] Batch {batch_number}/{total_batches} attempt {attempt} failed: {exc}",
                        file=sys.stderr
                    )

        if payload is None:
            continue

        batch_titles = parse_titles_from_api_payload(payload)
        titles.update(batch_titles)

    return dict(sorted(titles.items()))


def build_payload(titles: Dict[str, str], generated_at: Optional[str] = None) -> dict:
    if generated_at is None:
        generated_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

    sorted_items = {key: titles[key] for key in sorted(titles)}

    return {
        "version": 1,
        "generatedAt": generated_at,
        "items": sorted_items
    }


def generate_payload(
    book_dir: Path,
    youtube_list_path: Path,
    api_key: str,
    batch_size: int = 50,
    generated_at: Optional[str] = None,
    fetch_titles: Callable[[List[str], str, int], Dict[str, str]] = fetch_titles
) -> dict:
    video_ids = collect_video_ids(book_dir, youtube_list_path)
    total_video_ids = len(video_ids)
    estimated_quota = math.ceil(total_video_ids / batch_size) if total_video_ids else 0

    print(f"[info] videoIds found: {total_video_ids}")
    print(f"[info] estimated quota units: {estimated_quota}")

    titles = fetch_titles(video_ids, api_key, batch_size)

    print(f"[info] titles resolved: {len(titles)}")
    print(f"[info] titles missing: {max(total_video_ids - len(titles), 0)}")

    return build_payload(titles, generated_at=generated_at)


def write_payload(output_path: Path, payload: dict) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8"
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Fetch YouTube titles and build a local JSON artifact.")
    parser.add_argument(
        "--book-dir",
        default="SwiftUI-SotkaApp/SupportingFiles/book",
        help="Path to folder with html infopost files"
    )
    parser.add_argument(
        "--youtube-list",
        default="SwiftUI-SotkaApp/SupportingFiles/youtube_list.txt",
        help="Path to youtube_list.txt"
    )
    parser.add_argument(
        "--output",
        default="SwiftUI-SotkaApp/SupportingFiles/youtube_video_titles.json",
        help="Output path for generated JSON"
    )
    parser.add_argument(
        "--api-key-env",
        default="YOUTUBE_API_KEY",
        help="Environment variable name for YouTube API key"
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=50,
        help="YouTube API batch size (max 50 for videos.list)"
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    api_key = os.environ.get(args.api_key_env)

    if not api_key:
        print(
            f"[error] Missing API key. Set {args.api_key_env} and retry.",
            file=sys.stderr
        )
        return 1

    if args.batch_size <= 0 or args.batch_size > 50:
        print("[error] --batch-size must be in range 1...50", file=sys.stderr)
        return 1

    book_dir = Path(args.book_dir)
    youtube_list_path = Path(args.youtube_list)
    output_path = Path(args.output)

    if not book_dir.exists():
        print(f"[error] Book directory not found: {book_dir}", file=sys.stderr)
        return 1

    if not youtube_list_path.exists():
        print(f"[error] youtube_list.txt not found: {youtube_list_path}", file=sys.stderr)
        return 1

    payload = generate_payload(
        book_dir=book_dir,
        youtube_list_path=youtube_list_path,
        api_key=api_key,
        batch_size=args.batch_size
    )
    write_payload(output_path, payload)

    print(f"[info] JSON written to: {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
