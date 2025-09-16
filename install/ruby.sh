#!/usr/bin/env bash
set -Eeuo pipefail
. "$(cd "$(dirname "$0")" && pwd)/preflight/lib.sh"

mise settings set ruby.ruby_build_opts "CC=clang CXX=clang++"

# Trust .ruby-version
mise settings add idiomatic_version_file_enable_tools ruby

mise use --global ruby@latest 
