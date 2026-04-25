#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Использование:
  simulator_ui_preflight.sh (--destination "<xcode destination>" | --device "<simulator name>") \
    --bundle-id "<bundle id>" \
    [--permissions "notifications,photos"]

Примеры:
  simulator_ui_preflight.sh --destination "platform=iOS Simulator,name=iPhone 17" \
    --bundle-id "com.oleg991.SwiftUI-SotkaApp" \
    --permissions "notifications"

  simulator_ui_preflight.sh --device "iPhone 15 Pro Max" \
    --bundle-id "com.oleg991.SwiftUI-SotkaApp"
EOF
}

destination=""
device=""
bundle_id=""
permissions="notifications"

while [[ $# -gt 0 ]]; do
    case "$1" in
    --destination)
        destination="${2:-}"
        shift 2
        ;;
    --device)
        device="${2:-}"
        shift 2
        ;;
    --bundle-id)
        bundle_id="${2:-}"
        shift 2
        ;;
    --permissions)
        permissions="${2:-}"
        shift 2
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "Ошибка: неизвестный аргумент '$1'" >&2
        usage
        exit 1
        ;;
    esac
done

if [[ -z "$bundle_id" ]]; then
    echo "Ошибка preflight: отсутствует --bundle-id" >&2
    exit 1
fi

if [[ -n "$destination" && -n "$device" ]]; then
    echo "Ошибка preflight: используйте только один из аргументов --destination или --device" >&2
    exit 1
fi

if [[ -z "$destination" && -z "$device" ]]; then
    echo "Ошибка preflight: требуется --destination или --device" >&2
    exit 1
fi

if [[ -n "$destination" ]]; then
    if [[ "$destination" == *"name="* ]]; then
        device="${destination##*name=}"
    else
        echo "Ошибка preflight: не удалось извлечь имя симулятора из destination '$destination'" >&2
        echo "Подсказка: используйте формат destination с параметром name=..., например 'platform=iOS Simulator,name=iPhone 17'" >&2
        exit 1
    fi
fi

if ! command -v xcrun >/dev/null 2>&1; then
    echo "Ошибка preflight: не найден xcrun. Установите Xcode Command Line Tools." >&2
    exit 1
fi

devices_json="$(xcrun simctl list devices available -j)"

udid="$(/usr/bin/python3 - "$device" "$devices_json" <<'PY'
import json
import sys

target = sys.argv[1]
data = json.loads(sys.argv[2])
candidates = []
for runtime, devices in data.get("devices", {}).items():
    for device in devices:
        if device.get("name") != target:
            continue
        if device.get("isAvailable") is False:
            continue
        state = device.get("state", "")
        score = 0 if state == "Booted" else 1
        candidates.append((score, runtime, device.get("udid", "")))

if not candidates:
    print("")
    sys.exit(0)

candidates.sort()
print(candidates[0][2])
PY
)"

if [[ -z "$udid" ]]; then
    echo "Ошибка preflight: не найден доступный симулятор '$device'." >&2
    echo "Подсказка: установите нужный runtime/device в Xcode Settings > Platforms." >&2
    exit 1
fi

echo "Preflight: preparing simulator '$device' ($udid) for bundle '$bundle_id'"
xcrun simctl boot "$udid" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$udid" -b >/dev/null

IFS=',' read -r -a permission_items <<<"$permissions"
for permission in "${permission_items[@]}"; do
    normalized="$(echo "$permission" | xargs)"
    if [[ -z "$normalized" ]]; then
        continue
    fi
    if ! xcrun simctl privacy "$udid" grant "$normalized" "$bundle_id" >/dev/null 2>&1; then
        echo "Ошибка preflight: не удалось выдать permission '$normalized' для '$bundle_id' на '$device'." >&2
        echo "Подсказка: проверьте корректность имени permission для simctl privacy или обновите Xcode runtime." >&2
        exit 1
    fi
    echo "Preflight: granted '$normalized'"
done

echo "Preflight: simulator '$device' is ready."
