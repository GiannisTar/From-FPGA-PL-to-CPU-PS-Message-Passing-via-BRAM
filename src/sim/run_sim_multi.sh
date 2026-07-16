#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if ! command -v iverilog >/dev/null 2>&1; then
    echo "iverilog not found. Install with: sudo apt install iverilog"
    exit 2
fi
iverilog -g2012 -o sim_multi.vvp pl_uart_receiver.v pl_uart_tb_multi.v
vvp sim_multi.vvp | tee sim_multi.log
echo "Done. See sim_multi.log and pl_uart_multi.vcd"
