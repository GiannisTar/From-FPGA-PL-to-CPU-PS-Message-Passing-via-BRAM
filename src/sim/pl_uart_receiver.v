// Simple behavioral UART receiver that writes a length-prefixed message into an internal BRAM model.
// Protocol used by this testbench:
// - First 4 bytes received over UART (little-endian) = payload length (N)
// - Next N bytes = payload, written starting at byte offset 4 in the BRAM
// After full payload received, the receiver writes the 32-bit length word into BRAM[0..3].
`timescale 1ns/1ps
module pl_uart_receiver(
    input  wire clk,
    input  wire rstn,
    input  wire serial_rx
);

    // Simple BRAM model (byte-addressable)
    parameter BRAM_BYTES = 8192;
    reg [7:0] mem [0:BRAM_BYTES-1];

    // helper
    localparam integer MAX_PAYLOAD = BRAM_BYTES - 4;
    reg [31:0] expected_len_temp;

    // UART sampling
    // For simulation we sample edges by detecting falling edge (start bit)
    integer i;
    reg [12:0] sample_cnt;
    reg receiving;
    reg [3:0] bit_idx;
    reg [7:0] shift_reg;
    reg [31:0] expected_len;
    reg [31:0] received_count;
    reg [2:0] len_byte_idx;
    reg [7:0] len_bytes [0:3];
    reg [31:0] write_addr;

    initial begin
        // initialize mem and state
        for (i = 0; i < BRAM_BYTES; i = i + 1) mem[i] = 8'h00;
        sample_cnt = 0;
        receiving = 0;
        bit_idx = 0;
        shift_reg = 0;
        expected_len = 0;
        received_count = 0;
        len_byte_idx = 0;
        write_addr = 4; // payload starts at offset 4
    end

    // detect start bit by sampling serial_rx when idle
    reg serial_rx_d;
    always @(posedge clk) begin
        if (!rstn) begin
            serial_rx_d <= 1'b1;
            receiving <= 0;
            sample_cnt <= 0;
            bit_idx <= 0;
        end else begin
            serial_rx_d <= serial_rx;
            if (!receiving && serial_rx_d && !serial_rx) begin
                // falling edge detected -> start bit
                receiving <= 1;
                sample_cnt <= 0;
                bit_idx <= 0;
                $display("%0t: Start bit detected", $time);
            end else if (receiving) begin
                // advance sampling in this simple behavioral model
                sample_cnt <= sample_cnt + 1;
                // Sample a bit every 8 cycles (we trigger when sample_cnt == 7 to sample near the middle)
                if (sample_cnt == 7) begin
                    sample_cnt <= 0;
                    if (bit_idx < 8) begin
                        // capture data bit (LSB first)
                        shift_reg[bit_idx] <= serial_rx;
                        bit_idx <= bit_idx + 1;
                    end else begin
                        $display("%0t: Byte assembled: %02x (len_idx=%0d)", $time, shift_reg, len_byte_idx);
                        // stop bit received, deliver the assembled byte
                        bit_idx <= 0;
                        receiving <= 0;
                        // process received byte
                        if (len_byte_idx < 3) begin
                            // store first three length bytes
                            len_bytes[len_byte_idx] <= shift_reg;
                            len_byte_idx <= len_byte_idx + 1;
                        end else if (len_byte_idx == 3) begin
                            // store the 4th length byte
                            len_bytes[3] <= shift_reg;
                            // assemble expected length (little endian) using shift_reg as MSB
                            expected_len_temp = {shift_reg, len_bytes[2], len_bytes[1], len_bytes[0]};
                            if (expected_len_temp > MAX_PAYLOAD) begin
                                expected_len <= MAX_PAYLOAD;
                                $display("%0t: Expected length %0d > capacity %0d, clamping to %0d", $time, expected_len_temp, MAX_PAYLOAD, MAX_PAYLOAD);
                            end else begin
                                expected_len <= expected_len_temp;
                                $display("%0t: Expected length assembled = %0d", $time, expected_len_temp);
                            end
                            len_byte_idx <= len_byte_idx + 1; // move to payload state
                            // reset counters to receive payload
                            received_count <= 0;
                            write_addr <= 4;
                            // special case: zero-length -> immediately write length word to mem
                            if (expected_len_temp == 0) begin
                                mem[0] <= len_bytes[0];
                                mem[1] <= len_bytes[1];
                                mem[2] <= len_bytes[2];
                                mem[3] <= shift_reg;
                                $display("%0t: Zero-length message; wrote length word to mem[0..3]", $time);
                                // reset for next message
                                len_byte_idx <= 0;
                                expected_len <= 0;
                                received_count <= 0;
                                write_addr <= 4;
                            end
                        end else begin
                            // payload byte: write to mem
                            mem[write_addr] <= shift_reg;
                            $display("%0t: Writing payload byte %02x to mem[%0d]", $time, shift_reg, write_addr);
                            write_addr <= write_addr + 1;
                            received_count <= received_count + 1;
                            if (received_count + 1 == expected_len) begin
                                // write length into mem[0..3] little-endian
                                mem[0] <= len_bytes[0];
                                mem[1] <= len_bytes[1];
                                mem[2] <= len_bytes[2];
                                mem[3] <= len_bytes[3];
                                $display("%0t: Completed payload; wrote length bytes to mem[0..3]", $time);
                                // reset for next message
                                len_byte_idx <= 0;
                                expected_len <= 0;
                                received_count <= 0;
                                write_addr <= 4;
                            end
                        end
                    end
                end
            end
        end
    end

    // Expose memory for simulation via hierarchical reference: tb.dut.mem[...]
    // Nothing else to synthesize in this test-only module.

endmodule
