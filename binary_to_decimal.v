module BinaryToDecimalConverter (
    input wire clk,            // FPGA clock (50MHz or 100MHz)
    input wire [9:0] sw,      // 10-bit binary input from switches
    output reg [6:0] seg,      // 7-segment display segments (A-G)
    output reg [3:0] an,       // 4-digit display enable (active-low)
    output reg [9:0] led       // LEDs to match the input switches
);

    reg [3:0] bcd_digits [3:0];  // BCD storage for 4 digits
    reg [15:0] refresh_counter = 0; // Refresh rate counter
    reg [1:0] digit_select = 0; // Which digit to display
    
    // **Binary to BCD conversion (Double-Dabble Algorithm)**
    integer i;
    reg [19:0] shift_reg; // 10-bit binary + 10-bit BCD

    always @(sw) begin
        shift_reg = {10'b0, sw}; // Initialize shift register
        for (i = 0; i < 10; i = i + 1) begin
            // If any BCD digit is >= 5, add 3
            if (shift_reg[13:10] >= 5) shift_reg[13:10] = shift_reg[13:10] + 3;
            if (shift_reg[17:14] >= 5) shift_reg[17:14] = shift_reg[17:14] + 3;
            if (shift_reg[19:18] >= 5) shift_reg[19:18] = shift_reg[19:18] + 3;
            // Shift left
            shift_reg = shift_reg << 1;
        end
        // Store BCD digits
        bcd_digits[0] = shift_reg[13:10]; // Ones
        bcd_digits[1] = shift_reg[17:14]; // Tens
        bcd_digits[2] = shift_reg[19:18]; // Hundreds
        bcd_digits[3] = 4'b0000;          // Thousands (Always 0, max number is 1023)
        
        // **Mirror switch input to LEDs**
        led = sw; // Directly assign input switches to LEDs
    end

    // **Clock division for 7-segment refresh (slow down display switching)**
    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
        if (refresh_counter == 50000) begin
            refresh_counter <= 0;
            digit_select <= digit_select + 1;
        end
    end

    // **Multiplexing 7-segment display**
    always @(digit_select) begin
        case (digit_select)
            2'b00: begin seg = bcd_to_7seg(bcd_digits[0]); an = 4'b1110; end // Ones place
            2'b01: begin seg = bcd_to_7seg(bcd_digits[1]); an = 4'b1101; end // Tens place
            2'b10: begin seg = bcd_to_7seg(bcd_digits[2]); an = 4'b1011; end // Hundreds place
            2'b11: begin seg = bcd_to_7seg(bcd_digits[3]); an = 4'b0111; end // Thousands place
        endcase
    end

    // **7-Segment Display Lookup Table**
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
