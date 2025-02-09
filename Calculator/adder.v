module Calculator (
    input wire clk,            // FPGA clock
    input wire [9:0] bin,      // 10-bit binary input from switches
    input wire buttonU,        // Save first number
    input wire buttonR,        // Add numbers
    output reg [6:0] seg,      // 7-segment display segments (A-G)
    output reg [3:0] an,       // 4-digit display enable
    output reg [9:0] led       // LEDs to match the input switches
);

    reg [9:0] num1 = 0;         // First saved number
    reg [9:0] num2 = 0;         // Second number (current input)
    reg [9:0] result = 0;       // Result of addition
    reg save_flag = 0;          // Track if num1 is saved
    reg add_flag = 0;           // Track if addition is done
    
    reg [3:0] bcd_digits [3:0]; // BCD storage for 4 digits
    reg [15:0] refresh_counter = 0; // Refresh rate counter
    reg [1:0] digit_select = 0; // Digit selection
    
    // Binary to BCD conversion using Double-Dabble
    integer i;
    reg [19:0] shift_reg;

    always @(bin, result, save_flag, add_flag) begin
        shift_reg = {10'b0, (add_flag ? result : bin)}; // Convert bin or result to BCD
        for (i = 0; i < 10; i = i + 1) begin
            if (shift_reg[13:10] >= 5) shift_reg[13:10] = shift_reg[13:10] + 3;
            if (shift_reg[17:14] >= 5) shift_reg[17:14] = shift_reg[17:14] + 3;
            if (shift_reg[19:18] >= 5) shift_reg[19:18] = shift_reg[19:18] + 3;
            shift_reg = shift_reg << 1;
        end
        bcd_digits[0] = shift_reg[13:10]; // Ones
        bcd_digits[1] = shift_reg[17:14]; // Tens
        bcd_digits[2] = shift_reg[19:18]; // Hundreds
        bcd_digits[3] = 4'b0000;          // Thousands

        led = bin; // Show switch input on LEDs
    end

    // Button Debouncing
    reg last_buttonU = 0, last_buttonR = 0;

    always @(posedge clk) begin
        if (buttonU && !last_buttonU) begin
            num1 <= bin;
            save_flag <= 1;
            add_flag <= 0;
        end
        if (buttonR && !last_buttonR && save_flag) begin
            num2 <= bin;
            result <= num1 + bin;
            add_flag <= 1;
        end
        last_buttonU <= buttonU;
        last_buttonR <= buttonR;
    end

    // Refresh 7-segment display
    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
        if (refresh_counter == 50000) begin
            refresh_counter <= 0;
            digit_select <= digit_select + 1;
        end
    end

    always @(digit_select) begin
        case (digit_select)
            2'b00: begin seg = bcd_to_7seg(bcd_digits[0]); an = 4'b1110; end // Ones
            2'b01: begin seg = bcd_to_7seg(bcd_digits[1]); an = 4'b1101; end // Tens
            2'b10: begin seg = bcd_to_7seg(bcd_digits[2]); an = 4'b1011; end // Hundreds
            2'b11: begin seg = bcd_to_7seg(bcd_digits[3]); an = 4'b0111; end // Thousands
        endcase
    end

    // 7-Segment Decoder
    function [6:0] bcd_to_7seg;
        input [3:0] bcd;
        case (bcd)
            4'b0000: bcd_to_7seg = 7'b1000000; // 0
            4'b0001: bcd_to_7seg = 7'b1111001; // 1
            4'b0010: bcd_to_7seg = 7'b0100100; // 2
            4'b0011: bcd_to_7seg = 7'b0110000; // 3
            4'b0100: bcd_to_7seg = 7'b0011001; // 4
            4'b0101: bcd_to_7seg = 7'b0010010; // 5
            4'b0110: bcd_to_7seg = 7'b0000010; // 6
            4'b0111: bcd_to_7seg = 7'b1111000; // 7
            4'b1000: bcd_to_7seg = 7'b0000000; // 8
            4'b1001: bcd_to_7seg = 7'b0010000; // 9
            default: bcd_to_7seg = 7'b1111111; // Blank
        endcase
    endfunction

endmodule
