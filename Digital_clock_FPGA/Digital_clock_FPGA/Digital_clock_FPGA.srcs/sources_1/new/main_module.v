module Top_Module(
    input clk,            // Main clock input
    input sw,             // Switch input for enabling/disabling clock
    input btnC,           // Button C for resetting clock
    input btnU,           // Button U for incrementing minute
    output [6:0] seg,     // 7-segment display segments
    output [3:0] an,      // 7-segment display anodes
    output [7:0] led,     // 8 LEDs output
    input btnR            // Button R for incrementing hour
    );
    
    // Declare wires for time representation: hours, minutes, and seconds
    wire [3:0] s1, s2, m1, m2, h1, h2;

    // Declare registers for hour and minute increment control
    reg hrup, minup;
    
    // Wires for debounced button signals
    wire btnCclr, btnUclr, btnRclr;
    
    // Registers to store the previous states of the debounced buttons
    reg btnCclr_prev, btnUclr_prev, btnRclr_prev;
    
    // Debounce the input buttons to prevent glitches
    debounce dbC (clk, btnC, btnCclr);  // Reset button (btnC)
    debounce dbU (clk, btnU, btnUclr);  // Minute increment button (btnU)
    debounce dbR (clk, btnR, btnRclr);  // Hour increment button (btnR)
    
    // Control signals for incrementing hour and minute
    always @(posedge clk) begin
        if (btnUclr && !btnUclr_prev) minup <= 1;  // Minute button pressed, enable minute increment
        else minup <= 0;
        
        if (btnRclr && !btnRclr_prev) hrup <= 1;   // Hour button pressed, enable hour increment
        else hrup <= 0;
        
        // Store previous button states
        btnCclr_prev <= btnCclr;
        btnUclr_prev <= btnUclr;
        btnRclr_prev <= btnRclr;
    end
    
    // Instantiate the 7-segment display driver to display time
    sevenseg_driver seg7 (
        .clk(clk), 
        .clr(1'b0), 
        .in1(h2), 
        .in2(h1), 
        .in3(m2), 
        .in4(m1), 
        .seg(seg), 
        .an(an)
    );
    
    // Instantiate the digital clock to track time and handle button presses
    digital_clock clock (
        .clk(clk), 
        .en(sw), 
        .rst(btnCclr),  // Reset the clock when button C is pressed
        .hrup(hrup),    // Hour increment signal
        .minup(minup),  // Minute increment signal
        .h1(h1), 
        .h2(h2), 
        .m1(m1), 
        .m2(m2), 
        .s1(s1), 
        .s2(s2)
    );
    
    // Output the time to LEDs (optional, for debugging or additional visualization)
    assign led[7:0] = {s1, s2};  // Display time as 8-bit LED output
endmodule

module sevenseg_driver(
    input clk,          // Clock signal for timing control
    input clr,          // Clear signal to reset the module
    input [3:0] in1,    // 4-bit input for the first digit (rightmost)
    input [3:0] in2,    // 4-bit input for the second digit
    input [3:0] in3,    // 4-bit input for the third digit
    input [3:0] in4,    // 4-bit input for the fourth digit (leftmost)
    output reg [6:0] seg, // 7-segment display output (segments a-g)
    output reg [3:0] an   // Anode control for digit selection
    );

    // Wire to hold the 7-segment encoding for each input
    wire [6:0] seg1, seg2, seg3, seg4;
    
    // 13-bit counter for controlling the timing of the 7-segment displays
    reg [12:0] segclk; 

    // State encoding for the 4 digits (LEFT, MIDLEFT, MIDRIGHT, RIGHT)
    localparam LEFT = 2'b00, MIDLEFT = 2'b01, MIDRIGHT = 2'b10, RIGHT = 2'b11;

    // State variable to track which digit to display
    reg [1:0] state = LEFT;

    // On each clock cycle, increment the segment clock
    always @(posedge clk) begin
        segclk <= segclk + 1'b1; // Counter goes up by 1
    end

    // Display update on every positive edge of segclk or reset
    always @(posedge segclk[12] or posedge clr) begin
        if (clr == 1) begin // If clear is pressed
            seg <= 7'b0000000; // Clear all segments
            an <= 4'b0000;     // Disable all digits
            state <= LEFT;     // Reset to the first state (LEFT)
        end else begin
            // Switch between the different states for 4 digits
            case(state)
                LEFT: begin
                    seg <= seg1;       // Show first digit
                    an <= 4'b0111;     // Enable first digit (active low)
                    state <= MIDLEFT;  // Transition to next state
                end
                MIDLEFT: begin
                    seg <= seg2;       // Show second digit
                    an <= 4'b1011;     // Enable second digit (active low)
                    state <= MIDRIGHT; // Transition to next state
                end
                MIDRIGHT: begin
                    seg <= seg3;       // Show third digit
                    an <= 4'b1101;     // Enable third digit (active low)
                    state <= RIGHT;    // Transition to next state
                end
                RIGHT: begin
                    seg <= seg4;       // Show fourth digit
                    an <= 4'b1110;     // Enable fourth digit (active low)
                    state <= LEFT;     // Go back to the first state
                end
                default: begin
                    seg <= 7'b0000000; // Default to clearing the display
                    an <= 4'b0000;     // Default to disabling all digits
                end
            endcase
        end
    end

    // Logic for 7-segment display encoding for each digit (0-9)
    Decoder_7_segment enc1 (.in(in1), .seg(seg1));
    Decoder_7_segment enc2 (.in(in2), .seg(seg2));
    Decoder_7_segment enc3 (.in(in3), .seg(seg3));
    Decoder_7_segment enc4 (.in(in4), .seg(seg4));

endmodule


module Slow_Clock_4Hz(
    input clk_in,    // High-frequency clock input (e.g., 100 MHz)
    output reg clk_out  // Slow clock output (4 Hz)
    );
    
    reg [24:0] counter;  // 25-bit counter for clock division

    // Always block triggered on the rising edge of the input clock
    always @(posedge clk_in) begin
        if (counter == 24999999) begin
            counter <= 0;          // Reset the counter
            clk_out <= ~clk_out;   // Toggle the output clock (4 Hz)
        end else begin
            counter <= counter + 1;  // Increment the counter
        end
    end

endmodule


module Decoder_7_segment(
    input [3:0] in,      // 4 bits going into the segment
    output reg [6:0] seg // Display the BCD number on a 7-segment display
);

    always @(in)
    begin
        case(in)
            4'b0000: seg = 7'b0000001; // 0
            4'b0001: seg = 7'b1001111; // 1
            4'b0010: seg = 7'b0010010; // 2
            4'b0011: seg = 7'b0000110; // 3
            4'b0100: seg = 7'b1001100; // 4
            4'b0101: seg = 7'b0100100; // 5
            4'b0110: seg = 7'b0100000; // 6
            4'b0111: seg = 7'b0001111; // 7
            4'b1000: seg = 7'b0000000; // 8
            4'b1001: seg = 7'b0000100; // 9
            default: seg = 7'b1111111; // Default: all segments off (if input is invalid)
        endcase
    end

endmodule

module digital_clock(
    input clk,
    input en,
    input rst,
    input hrup,
    input minup,
    output [3:0] h1,
    output [3:0] h2,
    output [3:0] m1,
    output [3:0] m2,
    output [3:0] s1,
    output [3:0] s2
    );
    
    // Timekeeping registers
    reg [5:0] hour = 0, min = 0, sec = 0;
    integer clkc = 0;
    localparam onesec = 100_100_100; // 1 second counter
    
    // Hour, minute, and second logic
    always @(posedge clk)
    begin
        if (rst) begin
            hour <= 0;
            min <= 0;
            sec <= 0;
        end
        else if (minup && min < 59)
            min <= min + 1;
        else if (hrup && hour < 23)
            hour <= hour + 1;
        
        // Increment the second counter every second
        if (clkc == onesec) begin
            clkc <= 0;
            if (sec == 59) begin
                sec <= 0;
                if (min == 59) begin
                    min <= 0;
                    if (hour == 23)
                        hour <= 0;
                    else
                        hour <= hour + 1;
                end else begin
                    min <= min + 1;
                end
            end else begin
                sec <= sec + 1;
            end
        end else begin
            clkc <= clkc + 1;
        end
    end

    // Binary to BCD conversion for hours, minutes, and seconds
    wire [3:0] thos, hund, tens, ones;
    binarytoBCD bcd_hour(hour, thos, hund, tens, ones);
    binarytoBCD bcd_min(min, thos, hund, tens, ones);
    binarytoBCD bcd_sec(sec, thos, hund, tens, ones);

    // Output the values to the top module
    assign h1 = thos; 
    assign h2 = hund;
    assign m1 = tens; 
    assign m2 = ones;
    assign s1 = tens;
    assign s2 = ones;
endmodule
