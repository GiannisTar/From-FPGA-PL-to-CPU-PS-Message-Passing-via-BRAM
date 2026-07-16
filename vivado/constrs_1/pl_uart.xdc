# Placeholder constraints for PL UART RX (PMOD B)
#
# Wiring recommendation (default):
#  - Connect UMFT234XD TX -> PMOD_B pin JB1
#  - Connect UMFT234XD GND -> PMOD_B pin JB2
#  - Use 3.3V TTL signalling only. DO NOT connect 5V directly.
#
# PMOD_B pin mapping (from board part file):
#  JB1 -> package pin W14
#  JB2 -> package pin Y14
#  JB3 -> package pin T11
#  JB4 -> package pin T10
#  JB7 -> package pin V16
#  JB8 -> package pin W16
#  JB9 -> package pin V12
#  JB10-> package pin W13
#
# If you want to use JB1 (package pin W14) as PL_UART_RX, set the PACKAGE_PIN and IOSTANDARD below.
# This is set to the port name `pl_uart_rx` used in the placeholder RTL module supplied in
# `project_1/sources_1/pl_uart_if.v`.

set_property PACKAGE_PIN W14 [get_ports {pl_uart_rx}]
set_property IOSTANDARD LVCMOS33 [get_ports {pl_uart_rx}]

# Note: PMOD JB2 (package pin Y14) is recommended for GND. No PACKAGE_PIN constraint is
# required for a ground wire. Ensure the UMFT234XD GND is connected to the board GND.

# NOTE: PMOD ground pin mappings can vary between board revisions and silkscreen
# conventions. Some schematics/boards label the PMOD ground as a different physical
# pin (for example, the second-to-last bottom pin on some PYNQ-Z2 schematics). Do NOT
# assume JB2/Y14 is always the PMOD ground on your specific board.
#
# To be safe:
#  - Identify a PMOD ground by visual inspection of the board silkscreen or by
#    continuity testing with a multimeter: probe the suspected PMOD pin and a known
#    board ground (for example, a GND test pad or a GND pin on the Arduino header); the
#    multimeter should show near-zero ohms.
#  - Connect UMFT234XD GND to any verified board GND pin on the PMOD connector.
#
# IMPORTANT: the UMFT234XD datasheet states the UART I/Os operate at 3.3V TTL and are
# 5V-tolerant; however, always verify your specific module configuration before wiring.
