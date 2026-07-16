Simulation helper files

Files:
- pl_uart_receiver.v       -- behavioral DUT (simulation-only)
- pl_uart_tb.v             -- single-case testbench
- pl_uart_tb_multi.v       -- multi-case testbench (zero-length, normal, truncated, oversized)
- run_sim.sh               -- run with Icarus Verilog (iverilog + vvp)
- run_sim_multi.sh         -- run multi-test with Icarus Verilog
- run_xsim.tcl            -- Vivado Tcl helper: source it in Vivado and call run_xsim tb or run_xsim tb_multi

Using Vivado XSIM (inside Vivado Tcl console):

1. Open Vivado and set the project to your Vivado project folder (project_1).
2. In the Tcl console, source this script from the sim folder:
   cd <path-to-project>/project_1/sim
   source run_xsim.tcl
3. Run:
   run_xsim tb        ;# single test
   run_xsim tb_multi  ;# multi-test

Waveform output: `<sim>/pl_uart_tb.wdb` or `<sim>/tb_multi.wdb` depending on the test.
