#!/usr/bin/env python3
from pathlib import Path
import os
import subprocess
import sys


ROOT = Path(os.environ.get("DOTFILES_DIR", Path(__file__).resolve().parent.parent))
TARGET = ROOT / "scripts" / "generated" / "sync-keymaps.py"

raise SystemExit(subprocess.call([sys.executable, str(TARGET), *sys.argv[1:]]))
