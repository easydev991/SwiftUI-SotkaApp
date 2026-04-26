import json
import tempfile
import unittest
from pathlib import Path

from scripts import get_video_titles


class GetVideoTitlesTests(unittest.TestCase):
    def test_extract_video_id_from_supported_formats(self) -> None:
        self.assertEqual(
            get_video_titles.extract_video_id("https://www.youtube.com/embed/OM0m9CEjq2Y"),
            "OM0m9CEjq2Y"
        )
        self.assertEqual(
            get_video_titles.extract_video_id("https://www.youtube.com/watch?v=OM0m9CEjq2Y&t=10s"),
            "OM0m9CEjq2Y"
        )
        self.assertEqual(
            get_video_titles.extract_video_id("https://youtu.be/OM0m9CEjq2Y?si=abc"),
            "OM0m9CEjq2Y"
        )

    def test_extract_video_id_from_edge_cases(self) -> None:
        self.assertEqual(
            get_video_titles.extract_video_id("https://www.youtube.com/shorts/OM0m9CEjq2Y?si=abc"),
            "OM0m9CEjq2Y"
        )
        self.assertEqual(
            get_video_titles.extract_video_id("https://youtube.com/watch?v=OM0m9CEjq2Y"),
            "OM0m9CEjq2Y"
        )
        self.assertIsNone(get_video_titles.extract_video_id("https://example.com/watch?v=OM0m9CEjq2Y"))
        self.assertIsNone(get_video_titles.extract_video_id("not a url"))

    def test_collect_youtube_urls_from_html(self) -> None:
        html = """
        <html><body>
            <iframe src="https://www.youtube.com/embed/AAA111?si=1"></iframe>
            <a href='https://youtu.be/BBB222?t=10'>Watch</a>
            <a href="https://www.youtube.com/watch?v=CCC333&amp;t=1">Watch 2</a>
            <a href="https://example.com/watch?v=DDD444">Nope</a>
        </body></html>
        """

        urls = get_video_titles.collect_youtube_urls_from_html(html)

        self.assertEqual(
            sorted(urls),
            sorted(
                [
                    "https://www.youtube.com/embed/AAA111?si=1",
                    "https://youtu.be/BBB222?t=10",
                    "https://www.youtube.com/watch?v=CCC333&t=1"
                ]
            )
        )

    def test_collect_unique_video_ids_from_book_and_list(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            book = root / "book"
            book.mkdir(parents=True)
            (book / "a.html").write_text(
                '<iframe src="https://www.youtube.com/embed/AAA111"></iframe>',
                encoding="utf-8"
            )
            (book / "b.html").write_text(
                '<a href="https://youtu.be/BBB222">Watch</a>',
                encoding="utf-8"
            )
            youtube_list = root / "youtube_list.txt"
            youtube_list.write_text(
                "\n".join(
                    [
                        "https://www.youtube.com/embed/AAA111",
                        "https://www.youtube.com/watch?v=CCC333"
                    ]
                ),
                encoding="utf-8"
            )

            video_ids = get_video_titles.collect_video_ids(book, youtube_list)

            self.assertEqual(video_ids, ["AAA111", "BBB222", "CCC333"])

    def test_parse_titles_from_api_payload(self) -> None:
        payload = {
            "items": [
                {"id": "AAA111", "snippet": {"title": "Title A"}},
                {"id": "BBB222", "snippet": {"title": "Title B"}},
                {"id": "CCC333", "snippet": {"title": ""}},
                {"id": "DDD444", "snippet": {}}
            ]
        }

        result = get_video_titles.parse_titles_from_api_payload(payload)

        self.assertEqual(result, {"AAA111": "Title A", "BBB222": "Title B"})

    def test_build_payload_has_deterministic_item_order(self) -> None:
        payload = get_video_titles.build_payload(
            {"CCC333": "C", "AAA111": "A", "BBB222": "B"},
            generated_at="2026-04-26T12:00:00Z"
        )

        self.assertEqual(list(payload["items"].keys()), ["AAA111", "BBB222", "CCC333"])
        self.assertEqual(payload["version"], 1)

    def test_generate_payload_handles_partial_failures_and_writes_file(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            book = root / "book"
            book.mkdir(parents=True)
            (book / "a.html").write_text(
                """
                <iframe src="https://www.youtube.com/embed/AAA111"></iframe>
                <iframe src="https://www.youtube.com/embed/BBB222"></iframe>
                <iframe src="https://www.youtube.com/embed/CCC333"></iframe>
                """,
                encoding="utf-8"
            )
            youtube_list = root / "youtube_list.txt"
            youtube_list.write_text("", encoding="utf-8")
            output = root / "youtube_video_titles.json"

            def fake_fetch(video_ids, api_key, batch_size):
                self.assertEqual(api_key, "test-key")
                self.assertEqual(batch_size, 2)
                self.assertEqual(video_ids, ["AAA111", "BBB222", "CCC333"])
                return {"AAA111": "Title A", "CCC333": "Title C"}

            payload = get_video_titles.generate_payload(
                book_dir=book,
                youtube_list_path=youtube_list,
                api_key="test-key",
                batch_size=2,
                generated_at="2026-04-26T12:00:00Z",
                fetch_titles=fake_fetch
            )
            get_video_titles.write_payload(output, payload)

            self.assertEqual(payload["items"], {"AAA111": "Title A", "CCC333": "Title C"})
            saved = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(saved["items"], {"AAA111": "Title A", "CCC333": "Title C"})

    def test_write_payload_replaces_old_content(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            output = Path(temp_dir) / "youtube_video_titles.json"

            first_payload = get_video_titles.build_payload(
                {"AAA111": "Title A", "BBB222": "Title B"},
                generated_at="2026-04-26T12:00:00Z"
            )
            get_video_titles.write_payload(output, first_payload)

            second_payload = get_video_titles.build_payload(
                {"BBB222": "Title B"},
                generated_at="2026-04-26T12:05:00Z"
            )
            get_video_titles.write_payload(output, second_payload)

            saved = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(saved["items"], {"BBB222": "Title B"})
            self.assertNotIn("AAA111", saved["items"])


if __name__ == "__main__":
    unittest.main()
