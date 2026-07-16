#!/usr/bin/env bash
set -euo pipefail

# CI runner: compile and run the multi testbench. Exit non-zero on failures.
SIM_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SIM_DIR"

echo "Compiling with iverilog..."
iverilog -g2012 -o sim_multi.vvp pl_uart_receiver.v pl_uart_tb_multi.v

echo "Running simulation..."
if vvp sim_multi.vvp | tee sim_run.log; then
    echo "Simulation finished (exit 0)."
else
    echo "Simulation returned non-zero (sim likely used $fatal). Check sim_run.log"
    exit 1
fi

# As a fallback, scan the log for FAIL markers
if grep -q "FAIL" sim_run.log; then
    echo "Detected FAIL in sim_run.log"
    exit 1
fi

echo "All good: no FAIL markers found."
exit 0
