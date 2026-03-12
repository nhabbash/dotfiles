#!/bin/bash
# Deprecated: use `dotfiles bootstrap` instead
exec "$(dirname "$0")/dotfiles.sh" bootstrap "$@"
