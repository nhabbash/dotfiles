#!/bin/bash
# Deprecated: use `dotfiles pull` instead
exec "$(dirname "$0")/dotfiles.sh" pull "$@"
