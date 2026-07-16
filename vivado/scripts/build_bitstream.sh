#!/usr/bin/env bash
set -euo pipefail

# Wrapper to run Vivado in batch mode to synth/impl/bitstream and export XSA
# Usage: ./build_bitstream.sh [path/to/project_xpr]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_XPR_DEFAULT="${SCRIPT_DIR}/../project_1.xpr"

PROJECT_XPR="${1:-$PROJECT_XPR_DEFAULT}"

if [ ! -f "$PROJECT_XPR" ]; then
  echo "Project file not found: $PROJECT_XPR" >&2
  exit 2
fi

echo "Running Vivado batch build for project: $PROJECT_XPR"
vivado -mode batch -source "$SCRIPT_DIR/build_bitstream.tcl" -- "$PROJECT_XPR"

echo "Vivado batch completed. Check the project log and the XSA file in the project directory."
