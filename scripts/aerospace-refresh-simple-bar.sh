#!/usr/bin/env bash

set -euo pipefail

widget_dir="${HOME}/Library/Application Support/Übersicht/widgets/simple-bar"

if [[ ! -d "${widget_dir}" ]]; then
  exit 0
fi

/usr/bin/osascript -e 'tell application id "tracesOf.Uebersicht" to refresh widget id "simple-bar-index-jsx"' >/dev/null 2>&1 || true
