#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter command not found. Please ensure Flutter SDK is installed and on PATH." >&2
  exit 1
fi

flutter pub get

PORT="${PORT:-5000}"
flutter run -d web-server --web-hostname=localhost --web-port="$PORT" "$@"
