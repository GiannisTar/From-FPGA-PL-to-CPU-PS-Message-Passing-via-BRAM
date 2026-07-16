`timescale 1ns/1ps
module tb;
    reg clk;
    reg rstn;
    reg serial_rx;
    integer idx;
    reg [31:0] len_word;
    reg pass;
    reg [7:0] expected_payload [0:15];

    // Instantiate DUT
    pl_uart_receiver dut(
        .clk(clk),
        .rstn(rstn),
        .serial_rx(serial_rx)
    );

    // Clock: 50 MHz (20 ns period) for this sim
    initial clk = 0;
    always #10 clk = ~clk;

    // Bit timing: DUT samples every 8 clock cycles. Use cycles_per_bit=8 and synchronize to posedge clk.
    localparam integer CYCLES_PER_BIT = 8;

    task send_byte(input [7:0] b);
        integer i, j;
        begin
            // align to clock
            @(posedge clk);
            // UART frame: start(0), LSB..MSB, stop(1)
            serial_rx <= 1'b0; // start
            for (j = 0; j < CYCLES_PER_BIT; j = j + 1) @(posedge clk);
            for (i = 0; i < 8; i = i + 1) begin
                serial_rx <= b[i];
                for (j = 0; j < CYCLES_PER_BIT; j = j + 1) @(posedge clk);
            end
            serial_rx <= 1'b1; // stop
            for (j = 0; j < CYCLES_PER_BIT; j = j + 1) @(posedge clk);
            // small inter-byte gap
            for (j = 0; j < CYCLES_PER_BIT * 2; j = j + 1) @(posedge clk);
        end
    endtask

    initial begin
        // initialize
        rstn = 0;
        serial_rx = 1'b1;
        #100;
        rstn = 1;
        // dump waveform for debugging
        $dumpfile("pl_uart_tb.vcd");
        $dumpvars(0, tb);

        // Prepare a message "Hello" (5 bytes). Length = 5 (0x05 0x00 0x00 0x00 little endian)
        send_byte(8'h05);
        send_byte(8'h00);
        send_byte(8'h00);
        send_byte(8'h00);

        // send payload 'H' 'e' 'l' 'l' 'o'
        send_byte(8'h48); // H
        send_byte(8'h65); // e
        send_byte(8'h6C); // l
        send_byte(8'h6C); // l
        send_byte(8'h6F); // o

        // wait for DUT to settle writes
        #2000;

        // dump a few memory bytes to the console by reading hierarchical memory
        $display("BRAM[0..7] = %02x %02x %02x %02x | %02x %02x %02x %02x",
            dut.mem[0], dut.mem[1], dut.mem[2], dut.mem[3],
            dut.mem[4], dut.mem[5], dut.mem[6], dut.mem[7]);

        // Validate the 4-byte little-endian length word and payload contents

        // build expected payload ("Hello")
        expected_payload[0] = 8'h48; // H
        expected_payload[1] = 8'h65; // e
        expected_payload[2] = 8'h6C; // l
        expected_payload[3] = 8'h6C; // l
        expected_payload[4] = 8'h6F; // o

        // assemble length word from mem[0..3] (little-endian)
        len_word = {dut.mem[3], dut.mem[2], dut.mem[1], dut.mem[0]};
        $display("Length read from BRAM = %0d", len_word);

        pass = 1;
        if (len_word != 5) begin
            $display("TEST FAIL: length mismatch (expected 5, got %0d)", len_word);
            pass = 0;
        end else begin
            // check payload bytes
            for (idx = 0; idx < len_word; idx = idx + 1) begin
                if (dut.mem[4+idx] !== expected_payload[idx]) begin
                    $display("TEST FAIL: payload byte %0d mismatch: expected %02x got %02x", idx, expected_payload[idx], dut.mem[4+idx]);
                    pass = 0;
                end
            end
        end

        if (pass) $display("TEST PASS: full message and length verified in BRAM");

        $finish;
    end

endmodule
