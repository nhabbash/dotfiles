#!/usr/bin/env bash
set -euo pipefail

aerospace list-windows --all --json \
  | jq -r '.[] | select(."window-title" == "") | ."window-id"' \
  | xargs -n1 aerospace close --window-id
