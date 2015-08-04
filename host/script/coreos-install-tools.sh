#!/bin/bash +x
set -e

# Execute each of the tools installation scripts in order
find "<%= getenv!(:config_directory) %>/tools.d" -type f | sort | while read f; do "$f"; done
