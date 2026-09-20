#!/usr/bin/env bash
# App launcher: desktop entries from /usr/share/applications and ~/.local/share/applications.
set -euo pipefail
exec rofi -show drun
