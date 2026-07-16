#!/usr/bin/env tclsh
# build_bitstream.tcl
# Usage (from project root):
#   vivado -mode batch -source project_1/scripts/build_bitstream.tcl -- "<project_xpr_path>"
# If no argument is given, the script looks for project_1/project_1.xpr relative to current dir.

proc usage {} {
    puts stderr "Usage: vivado -mode batch -source build_bitstream.tcl -- <project_xpr_path>"
    exit 1
}

# Accept optional project path via tclargs
set args [lindex $argv 0]
if {$args eq ""} {
    set proj_xpr "[file join [pwd] project_1 project_1.xpr]"
} else {
    set proj_xpr $args
}

puts "Using project file: $proj_xpr"

if {![file exists $proj_xpr]} {
    puts stderr "Project file not found: $proj_xpr"
    usage
}

puts "Opening project..."
open_project $proj_xpr

puts "Checking current project..."
set proj_name [get_property NAME [current_project]]
puts "Project opened: $proj_name"

# Save project before runs
puts "Saving project..."
save_project

# Launch synthesis
puts "Launching synthesis..."
if {[catch {launch_runs synth_1 -jobs 4} res]} {
    puts stderr "Failed to launch synthesis: $res"
    exit 2
}
wait_on_run synth_1

if {[get_property STATUS [get_runs synth_1]] ne "succeeded"} {
    puts stderr "Synthesis failed. Check the logs in the Vivado GUI or run 'open_run synth_1'."
    exit 3
}

# Launch implementation
puts "Launching implementation..."
if {[catch {launch_runs impl_1 -to_step write_bitstream -jobs 4} res2]} {
    puts stderr "Failed to launch implementation: $res2"
    exit 4
}
wait_on_run impl_1

if {[get_property STATUS [get_runs impl_1]] ne "succeeded"} {
    puts stderr "Implementation failed. Check the logs in the Vivado GUI or run 'open_run impl_1'."
    exit 5
}

# Write bitstream
puts "Writing bitstream..."
if {[catch {write_bitstream -force} res3]} {
    puts stderr "write_bitstream failed: $res3"
    exit 6
}

# Export hardware (XSA) with bitstream included
set out_xsa [file join [file dirname $proj_xpr] "pl_ps_bd_wrapper.xsa"]
puts "Exporting hardware to $out_xsa"
if {[catch {export_hw -force -include_bit -file $out_xsa} res4]} {
    puts stderr "export_hw failed: $res4"
    exit 7
}

puts "Bitstream and XSA export complete. XSA: $out_xsa"
puts "Done."

close_project
exit 0
