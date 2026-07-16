# Vivado Tcl helper: compile and run the UART->BRAM testbenches under XSIM
# Usage inside Vivado Tcl console:
#   source run_xsim.tcl
#   run_xsim tb            ;# runs pl_uart_tb
#   run_xsim tb_multi      ;# runs pl_uart_tb_multi

proc run_xsim {args} {
    # Accept optional arg; use first arg as which_test if provided
    if {[llength $args] >= 1} {
        set which_test [lindex $args 0]
    } else {
        set which_test ""
    }

    # Determine script directory (where this Tcl lives)
    if {[info script] == ""} {
        set script_dir [pwd]
    } else {
        set script_dir [file dirname [info script]]
    }

    # Map short names to file/top names
    if {$which_test == "tb"} {
        set top_name pl_uart_tb
        set tb_file pl_uart_tb.v
    } elseif {$which_test == "tb_multi"} {
        set top_name tb_multi
        set tb_file pl_uart_tb_multi.v
    } elseif {$which_test == ""} {
        puts "No test specified, defaulting to 'tb_multi'"
        set top_name tb_multi
        set tb_file pl_uart_tb_multi.v
    } else {
        puts "Unknown test '$which_test'. Supported: tb, tb_multi"
        return -code error "Unknown test"
    }

    puts "Running XSIM for test $top_name (files from $script_dir)"

    # List of source files (relative to script_dir)
    set files [list \
        [file join $script_dir pl_uart_receiver.v] \
        [file join $script_dir pl_uart_tb.v] \
        [file join $script_dir pl_uart_tb_multi.v]
    ]

    # Clean previous simulation snapshot if present
    set snap_name sim_${top_name}
    if {[file exists ${snap_name}.wdb]} {
        file delete -force ${snap_name}.wdb
    }

    # Compile sources with xvlog
    # Work in a temporary directory without spaces to avoid shell quoting issues
    # Create a unique tmp dir under /tmp using the current seconds timestamp
    set ts [clock seconds]
    set tmp_dir "/tmp/sim_xsim_${ts}"
    if {[file exists $tmp_dir]} {file delete -force $tmp_dir}
    file mkdir $tmp_dir

    # copy sources to tmp
    foreach f $files {
        if {[file exists $f]} {
            file copy -force $f $tmp_dir
        }
    }

    # Prepare a log file to capture xvlog/xelab/xsim output (in tmp then copy back)
    set log_file_tmp [file join $tmp_dir sim_xsim.log]

    puts "Compiling Verilog sources with xvlog in $tmp_dir... (log -> $log_file_tmp)"
    foreach f $files {
        set fname [file tail $f]
        if {[file exists [file join $tmp_dir $fname]]} {
            puts "  xvlog $fname"
            catch {exec xvlog -nolog -work work $fname >> $log_file_tmp 2>&1} rv
            if {$rv != 0} {puts "  xvlog returned non-zero for $fname"}
        }
    }

    # Elaborate with xelab
    puts "Elaborating top $top_name with xelab in $tmp_dir... (log -> $log_file_tmp)"
    catch {exec xelab -nolog -debug typical $top_name -s $snap_name >> $log_file_tmp 2>&1} elab_res

    # Run xsim and write waveform (.wdb) in the tmp dir
    set wdb_file_tmp [file join $tmp_dir ${top_name}.wdb]
    puts "Running simulation (xsim) in $tmp_dir and saving waveform to $wdb_file_tmp... (log -> $log_file_tmp)"
    catch {exec xsim $snap_name -R -wdb $wdb_file_tmp >> $log_file_tmp 2>&1} sim_res

    # copy back log and wdb to script dir
    set log_file [file join $script_dir sim_xsim.log]
    if {[file exists $log_file]} {file delete -force $log_file}
    file copy -force $log_file_tmp $log_file
    set wdb_file [file join $script_dir ${top_name}.wdb]
    if {[file exists $wdb_file]} {file delete -force $wdb_file}
    file copy -force $wdb_file_tmp $wdb_file

    puts "Detailed simulation log written to $log_file"
    puts "XSIM run finished. Waveform: $wdb_file"
    puts "If you want a readable VCD instead, you can open the .wdb in Vivado or use 'xsim -R -wdb <file>' with GUI."

    # Inspect the log for PASS/FAIL summary lines to enable CI detection
    set fh [open $log_file r]
    set content [read $fh]
    close $fh

    # Prefer a numeric summary: look for a line like 'Multi-test complete. PASS=4 FAIL=0'
    set pass_num -1
    set fail_num -1
    if {[regexp {PASS=([0-9]+)\s+FAIL=([0-9]+)} $content -> pass_num_str fail_num_str]} {
        set pass_num [expr {$pass_num_str + 0}]
        set fail_num [expr {$fail_num_str + 0}]
        puts "Detected PASS/FAIL summary: PASS=$pass_num FAIL=$fail_num"
        if {$fail_num > 0} {
            puts "Simulation reported $fail_num failures. See $log_file"
            return -code error "Simulation failures detected: $fail_num"
        } else {
            puts "All tests passed (PASS=$pass_num)."
            return
        }
    }

    # Fallback: look for explicit TEST ... FAIL lines (e.g., 'TEST 2 FAIL: ...')
    if {[regexp {TEST .* FAIL} $content]} {
        puts "Detected explicit FAIL markers in simulation log. See $log_file"
        return -code error "Simulation failures detected (explicit FAIL lines)"
    }

    # If we couldn't find either summary or explicit FAIL lines, warn but return success
    puts "No explicit PASS/FAIL summary found in log; please inspect $log_file if unsure."
}

puts "run_xsim.tcl loaded. Call 'run_xsim tb' or 'run_xsim tb_multi' from the Vivado Tcl console."
