#!/usr/bin/env bash
set -Eeuo pipefail

yellow(){ tput setaf 3; echo "$*"; tput sgr0; }
info(){ echo; yellow "$@"; }
is_osx(){ [[ "$(uname -s)" == "Darwin" ]]; }
dwrite(){ defaults write "$@" || echo "defaults failed: $*"; }
