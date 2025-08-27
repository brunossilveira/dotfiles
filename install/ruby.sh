#!/usr/bin/env bash
set -Eeuo pipefail
. "$(cd "$(dirname "$0")" && pwd)/preflight/lib.sh"

mise settings set ruby.ruby_build_opts "CC=gcc-14 CXX=g++-14"

# Trust .ruby-version
mise settings add idiomatic_version_file_enable_tools ruby