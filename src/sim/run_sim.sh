#!/usr/bin/env bash
set -euo pipefail

# Simple runner for the behavioral UART->BRAM testbench.
# Requires: iverilog, vvp

TOPDIR="$(cd "$(dirname "$0")" && pwd)"
cd "$TOPDIR"

if ! command -v iverilog >/dev/null 2>&1; then
    echo "iverilog not found. On Ubuntu: sudo apt install iverilog"
    exit 2
fi

OUT=sim.vvp
LOG=sim.log

echo "Compiling testbench..."
iverilog -g2012 -o "$OUT" pl_uart_receiver.v pl_uart_tb.v
echo "Running simulation... (output -> $LOG)"
vvp "$OUT" | tee "$LOG"
echo "Simulation complete. See $LOG for output."
