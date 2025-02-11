`timescale 1ns / 1ps

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