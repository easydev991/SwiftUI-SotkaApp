import os
import stat
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path
from typing import Dict, List, Optional


REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_PATH = REPO_ROOT / "scripts" / "simulator_ui_preflight.sh"


class SimulatorUiPreflightScriptTests(unittest.TestCase):
    def run_script(
        self,
        args: List[str],
        env: Optional[Dict[str, str]] = None
    ) -> subprocess.CompletedProcess[str]:
        test_env = os.environ.copy()
        if env:
            test_env.update(env)
        return subprocess.run(
            [str(SCRIPT_PATH), *args],
            capture_output=True,
            text=True,
            env=test_env,
            check=False
        )

    def test_fails_without_bundle_id(self) -> None:
        result = self.run_script(["--device", "iPhone 17"])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("отсутствует --bundle-id", result.stderr)

    def test_fails_when_destination_and_device_passed_together(self) -> None:
        result = self.run_script(
            [
                "--destination",
                "platform=iOS Simulator,name=iPhone 17",
                "--device",
                "iPhone 17",
                "--bundle-id",
                "com.test.app"
            ]
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("используйте только один из аргументов", result.stderr)

    def test_succeeds_with_stubbed_xcrun_and_multiple_permissions(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            fake_xcrun = temp_path / "xcrun"
            calls_log = temp_path / "xcrun_calls.log"

            fake_xcrun.write_text(
                textwrap.dedent(
                    f"""\
                    #!/usr/bin/env bash
                    set -euo pipefail
                    echo "$@" >> "{calls_log}"

                    if [[ "$1" == "simctl" && "$2" == "list" && "$3" == "devices" && "$4" == "available" && "$5" == "-j" ]]; then
                      cat <<'JSON'
                    {{"devices":{{"com.apple.CoreSimulator.SimRuntime.iOS-26-0":[{{"name":"iPhone 17","udid":"TEST-UDID","state":"Shutdown","isAvailable":true}}]}}}}
                    JSON
                      exit 0
                    fi

                    if [[ "$1" == "simctl" && "$2" == "boot" && "$3" == "TEST-UDID" ]]; then
                      exit 0
                    fi

                    if [[ "$1" == "simctl" && "$2" == "bootstatus" && "$3" == "TEST-UDID" && "$4" == "-b" ]]; then
                      exit 0
                    fi

                    if [[ "$1" == "simctl" && "$2" == "privacy" && "$3" == "TEST-UDID" && "$4" == "grant" ]]; then
                      exit 0
                    fi

                    echo "unexpected_call:$@" >&2
                    exit 1
                    """
                ),
                encoding="utf-8"
            )
            fake_xcrun.chmod(fake_xcrun.stat().st_mode | stat.S_IXUSR)

            result = self.run_script(
                [
                    "--destination",
                    "platform=iOS Simulator,name=iPhone 17",
                    "--bundle-id",
                    "com.oleg991.SwiftUI-SotkaApp",
                    "--permissions",
                    "photos,microphone"
                ],
                env={"PATH": f"{temp_dir}:{os.environ['PATH']}"}
            )

            self.assertEqual(result.returncode, 0, msg=result.stderr)
            self.assertIn("granted 'photos'", result.stdout)
            self.assertIn("granted 'microphone'", result.stdout)
            self.assertIn("is ready", result.stdout)

            calls = calls_log.read_text(encoding="utf-8")
            self.assertIn("simctl list devices available -j", calls)
            self.assertIn("simctl privacy TEST-UDID grant photos", calls)
            self.assertIn("simctl privacy TEST-UDID grant microphone", calls)


if __name__ == "__main__":
    unittest.main()
