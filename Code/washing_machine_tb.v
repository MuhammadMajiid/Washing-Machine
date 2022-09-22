//  AUTHOR: Mohamed Maged Elkholy.
//  INFO.: Undergraduate ECE student, Alexandria university, Egypt.
//  AUTHOR'S EMAIL: majiidd17@icloud.com
//  FILE NAME: washing_machine_tb.v
//  TYPE: Test fixture "Test bench".
//  DATE: 22/9/2022
//  KEYWORDS: washing machine controller.

//  NOTE: in order to save simulation time down-scale the timer_ticks by dividing them by 10^6
//  , which this method is used in this testbench.

`timescale 1us/1ns
module washing_machine_tb;

//  regs to drive the inputs
reg        rst_n_tb;
reg        clk_tb;
reg        coin_in_tb;
reg        double_wash_tb;
reg        timer_pause_tb;
reg [1:0]  clk_freq_tb;

//  wires to show the output
wire wash_done_tb;

//  DUT
washing_machine DUT(
    .rst_n(rst_n_tb),
    .clk(clk_tb),
    .coin_in(coin_in_tb),
    .double_wash(double_wash_tb),
    .timer_pause(timer_pause_tb),
    .clk_freq(clk_freq_tb),

    .wash_done(wash_done_tb)
);

// dump file
initial begin
   $dumpfile("washing_machine.vcd") ;       
   $dumpvars; 
end
    
//  Clock generator
initial begin
    clk_tb = 1'b0;
    forever #0.5 clk_tb = ~clk_tb;      //  clk_freq 1MHz
    // forever #0.25 clk_tb = ~clk_tb;     //  clk_freq 2MHz
    // forever #0.125 clk_tb = ~clk_tb;     //  clk_freq 4MHz
    // forever #0.0625 clk_tb = ~clk_tb;    //  clk_freq 8MHz
end

//  Reset
initial begin
    rst_n_tb = 1'b1;
    #1 rst_n_tb = 1'b0;
    #1 rst_n_tb = 1'b1;
end

//  initialization
initial begin
    clk_freq_tb    = 2'b00;
    coin_in_tb     = 1'b0;      // Ni coin is deposited.
    double_wash_tb = 1'b0;
    timer_pause_tb = 1'b0;
end

//  Test for 1MHz with double wash and pause
initial begin
    #1;
    clk_freq_tb    = 2'b00;     // 1MHz
    coin_in_tb     = 1'b1;      // coin is deposited.
    double_wash_tb = 1'b1;
    timer_pause_tb = 1'b1;      // pause timer in spin phase.
    #990;
    timer_pause_tb = 1'b0;      // continue spin phase.
    #30;
end

initial begin
    #1200 $stop;
end

//  Test for 8MHz with double wash and pause
/*
initial begin
    #2;
    clk_freq_tb    = 2'b11;     // 8MHz
    coin_in_tb     = 1'b1;      // coin is deposited.
    double_wash_tb = 1'b1;
    timer_pause_tb = 1'b1;      // pause timer in spin phase.
    #3720;
    timer_pause_tb = 1'b0;      // continue spin phase.
    #240;
end

initial
begin
    #4200 $stop;
end

*/

endmodule