#!/usr/bin/env bash
set -euo pipefail

workspace="${1:-}"
if [[ -z "$workspace" ]]; then
  echo "usage: aerospace-summon-workspace-here.sh <workspace>" >&2
  exit 1
fi

monitor_id="$({ aerospace list-monitors --mouse --format '%{monitor-id}'; } 2>/dev/null | head -n 1 | tr -d '[:space:]')"
if [[ -z "$monitor_id" ]]; then
  echo "could not determine monitor under mouse" >&2
  exit 1
fi

aerospace workspace "$workspace"
aerospace move-workspace-to-monitor "$monitor_id"
aerospace focus-monitor "$monitor_id"
