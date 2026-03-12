#!/bin/bash
# Deprecated: use `dotfiles rebuild` instead
exec "$(dirname "$0")/dotfiles.sh" rebuild "$@"
