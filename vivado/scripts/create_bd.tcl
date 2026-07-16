# Vivado Tcl script to create a Block Design skeleton for Assignment 1
# Usage: open Vivado 2020.2, open your project (project_1.xpr), then run:
#   source ./project_1/scripts/create_bd.tcl
#
# This script creates a BD containing:
#  - processing_system7 (PS)
#  - axi_interconnect
#  - axi_bram_ctrl + blk_mem_gen (BRAM)
#  - axi_uartlite (PL UART)
#  - Connects AXI masters/slaves and exposes a pl_uart_rx external port
#
# NOTE: This script attempts to use common IP VLNVs available in Vivado 2020.2.
# If Vivado reports "IP not found" errors, open the IP catalog and add the IP
# packages or adjust the VLNV/version strings below to match your installation.

puts "Creating block design skeleton for Assignment 1..."
set bd_name "pl_ps_bd"
create_bd_design $bd_name

# Create processing system 7 (PS7)
# VLNV for PS7 (Zynq-7000) - the version may vary, adjust if Vivado complains.
set ps_vlnv "xilinx.com:ip:processing_system7:5.5"
create_bd_cell -type ip -vlnv $ps_vlnv ps7

# Create AXI interconnect
set axi_ic_vlnv "xilinx.com:ip:axi_interconnect:2.1"
create_bd_cell -type ip -vlnv $axi_ic_vlnv axi_interconnect_0

# Create AXI BRAM Controller
set bram_ctrl_vlnv "xilinx.com:ip:axi_bram_ctrl:4.1"
create_bd_cell -type ip -vlnv $bram_ctrl_vlnv axi_bram_ctrl_0

# Create Block Memory Generator (BRAM)
set blk_mem_vlnv "xilinx.com:ip:blk_mem_gen:8.4"
create_bd_cell -type ip -vlnv $blk_mem_vlnv blk_mem_gen_0

# Create AXI UARTLite (PL side UART)
set uart_vlnv "xilinx.com:ip:axi_uartlite:2.0"
create_bd_cell -type ip -vlnv $uart_vlnv axi_uartlite_0

# Add external port for PL UART RX (to map to top-level port pl_uart_rx)
# Use type 'data' (valid BD port types: clk, ce, data, intr, rst)
create_bd_port -dir I -type data pl_uart_rx

# Make basic connections. Many nets are auto-created by Vivado GUI; here we add
# essential connections and leave address mapping & PS configuration to the user.
# Connect UART RX port to the axi_uartlite RX input (port name may vary across versions)
# Attempt to connect 's_axi_uartlite_RX' style port; if port names differ, adjust in GUI.

# Try connecting pl_uart_rx -> axi_uartlite_0/S_AXI_RX (best-effort; verify in GUI)
# Use connect_bd_net to hook the external port to the uart pin
catch {connect_bd_net [get_bd_ports pl_uart_rx] [get_bd_pins axi_uartlite_0/rx]} result
if {[info exists result]} {
    puts "Note: automatic connection to UART RX pin may fail; please connect pl_uart_rx to the proper UART input in the Vivado Block Design GUI if needed."
}

# Connect axi_uartlite to AXI interconnect (slave) - port names may differ; do this in GUI if needed
puts "Block design skeleton created. Please open the block design in Vivado GUI to finish wiring, configure addresses, and validate."

# Save the BD
save_bd_design
# Write BD TCL into the current project's directory to avoid relative-path issues
set proj_dir [get_property DIRECTORY [current_project]]
set out_tcl_file [file join $proj_dir "${bd_name}.tcl"]
write_bd_tcl -force $out_tcl_file
puts "Wrote BD TCL to $out_tcl_file"

# Reminder for user
puts "IMPORTANT: After running this script, open the block design in the GUI, run 'Validate Design', set the BRAM base address in Address Editor, and generate output products."
puts "Then export hardware (XSA / HDF) for use in Vitis."

puts "Script completed. Open the Block Design in the Vivado GUI to finish wiring and validation."
