//  AUTHOR: Mohamed Maged Elkholy.
//  INFO.: Undergraduate ECE student, Alexandria university, Egypt.
//  AUTHOR'S EMAIL: majiidd17@icloud.com
//  FILE NAME: washing_machine.v
//  TYPE: module.
//  DATE: 21/9/2022
//  KEYWORDS: Washing Machine Controller, Asynchronous Active low Reset, multiple clock frequency.
//  PURPOSE: An RTL modelling for a Washing Machine, controlled by an FSM.
//  Copyright 2022, Mohamed Maged, All rights reserved.

module washing_machine (
    input wire rst_n,           //  Active low Asynchronous reset.
    input wire clk,             //  System's clock.
    input wire [1:0] clk_freq,  //  Input Clock Frequency Configuration Code.
    input wire coin_in,         //  Asserted when a coin is deposited.
    input wire double_wash,     //  Asserted if the user requires double wash option.
    input wire timer_pause,     //  When it's set to ‘1’ spinning phase's paused until de-asserted.


    output reg wash_done        //  Active high output asserted when spinning is done.
);

//  Internal regs and wires
reg [2:0]   next_state;
reg [32:0]  timer_count;
reg [32:0]  timer_ticks;
reg         double_wash_begin;
reg         double_wash_done;
reg         spinning_done;

//  state encoding using gray code
localparam IDLE          = 3'b000,
           FILLING_WATER = 3'b001,
           WASHING       = 3'b011,
           RINSING       = 3'b010,
           SPINNING      = 3'b110;

//  encoding for the different frequency configurations
localparam FREQ_1MHZ = 2'b00,
           FREQ_2MHZ = 2'b01,
           FREQ_4MHZ = 2'b10,
           FREQ_8MHZ = 2'b11;

//  encoding for the 16 states of the timer value
localparam FILLING_1MHZ  = {FILLING_WATER,FREQ_1MHZ},
           FILLING_2MHZ  = {FILLING_WATER,FREQ_2MHZ},
           FILLING_4MHZ  = {FILLING_WATER,FREQ_4MHZ},
           FILLING_8MHZ  = {FILLING_WATER,FREQ_8MHZ},

           WASHING_1MHZ  = {WASHING,FREQ_1MHZ},
           WASHING_2MHZ  = {WASHING,FREQ_2MHZ},
           WASHING_4MHZ  = {WASHING,FREQ_4MHZ},
           WASHING_8MHZ  = {WASHING,FREQ_8MHZ},

           RINSING_1MHZ  = {RINSING,FREQ_1MHZ},
           RINSING_2MHZ  = {RINSING,FREQ_2MHZ},
           RINSING_4MHZ  = {RINSING,FREQ_4MHZ},
           RINSING_8MHZ  = {RINSING,FREQ_8MHZ},

           SPINNING_1MHZ = {SPINNING,FREQ_1MHZ},
           SPINNING_2MHZ = {SPINNING,FREQ_2MHZ},
           SPINNING_4MHZ = {SPINNING,FREQ_4MHZ},
           SPINNING_8MHZ = {SPINNING,FREQ_8MHZ};

//  next state logic
always @(posedge clk, negedge rst_n) begin
    if(~rst_n)
    begin
        next_state        <= IDLE;
        timer_count       <= 32'd0;
        double_wash_done  <= 1'b0;
        double_wash_begin <= 1'b0;
        spinning_done     <= 1'b0;
    end
    else
    begin
        case (next_state)
            // Starts when a coin is deposited.
            IDLE : 
            begin
                //  checks if the user requires a double wash  
                if(double_wash)
                begin
                    double_wash_begin <= 1'b1;
                    double_wash_done  <= 1'b0;
                end
                else
                begin
                    //  skipps the double wash operation
                    double_wash_begin <= 1'b0;
                    double_wash_done  <= 1'b1;
                end
                if(coin_in)
                begin
                    next_state     <= FILLING_WATER;
                    spinning_done  <= 1'b0;
                end
                else
                begin
                    next_state <= IDLE;
                end
            end
            // Filling water phase lasts for 2 minutes,
            // then automatically goes to washing phase.
            FILLING_WATER :
            begin
                if (timer_count == timer_ticks) 
                begin
                    timer_count <= 32'd0;
                    next_state  <= WASHING;
                end
                else
                begin
                    timer_count <= timer_count + 32'd1;
                    next_state  <= FILLING_WATER;
                end
            end
            // Washing phase lasts for 5 minutes,
            // then automatically goes to rinsing phase.
            WASHING :
            begin
                if(timer_count == timer_ticks) 
                begin
                    timer_count <= 32'd0;
                    next_state  <= RINSING;
                end
                else
                begin
                    timer_count <= timer_count + 32'd1;
                    next_state  <= WASHING;
                end
            end
            // rinsing phase lasts for 2 minutes, then if double wash is needed,
            // then it goes to wash phase for another cycle, if not, 
            // then it goes to spinning phase.
            RINSING :
            begin
                if(timer_count == timer_ticks) 
                begin
                    timer_count <= 32'd0;
                    if(double_wash_done)
                    begin
                        next_state  <= SPINNING;
                    end
                    else
                    begin
                        if (double_wash_begin) 
                        begin
                            next_state       <= WASHING;
                            double_wash_done <= 1'b1;
                        end
                        else
                        begin
                            next_state       <= SPINNING;
                            double_wash_done <= 1'b0;
                        end
                    end
                end
                else
                begin
                    timer_count <= timer_count + 32'd1;
                    next_state  <= RINSING;
                end
            end
            // spinning phase lasts for 1 minutes, then if timer pause is needed,
            // the counter stops counting untill the timer pause is de-asserted,
            // afterwards it goes back to the idle state,
            // ready for coin to get deposited.
            SPINNING : 
            begin
                //  we only check the pause input in the spinning phase
                if(timer_pause)
                begin
                    timer_count <= timer_count;
                    next_state  <= SPINNING;
                end
                else
                begin
                    if(timer_count == timer_ticks) 
                    begin
                        timer_count   <= 32'd0;
                        spinning_done <= 1'b1;
                        next_state    <= IDLE;
                    end
                    else
                    begin
                        timer_count   <= timer_count + 32'd1;
                        spinning_done <= 1'b0;
                        next_state    <= SPINNING;
                    end
                end
            end
            
            default: next_state <= IDLE;
        endcase
    end
end

//  Output flag logic
always @(*) begin
    if(~rst_n)
    begin
        wash_done     <= 1'b0;
    end
    else if(spinning_done)
    begin
        wash_done     <= 1'b1;
    end
    else
    begin
        wash_done     <= 1'b0;
    end
end

//  16-1 MUX supports the final value of the timer 
//  to meet the required time at different clock frequencies.
always @(*) begin
    case ({next_state,clk_freq}) //(scaled)
        FILLING_1MHZ, RINSING_1MHZ : timer_ticks = 32'd120_000_000;   //  (2mins == 2*60) * 1MHz
        FILLING_2MHZ, RINSING_2MHZ : timer_ticks = 32'd240_000_000;   //  (2mins == 2*60) * 2MHz
        FILLING_4MHZ, RINSING_4MHZ : timer_ticks = 32'd480_000_000;   //  (2mins == 2*60) * 4MHz
        FILLING_8MHZ, RINSING_8MHZ : timer_ticks = 32'd960_000_000;   //  (2mins == 2*60) * 8MHz

        WASHING_1MHZ : timer_ticks = 32'd300_000_000;   //  (5mins == 5*60) * 1MHz
        WASHING_2MHZ : timer_ticks = 32'd600_000_000;   //  (5mins == 5*60) * 2MHz
        WASHING_4MHZ : timer_ticks = 32'd1200_000_000;  //  (5mins == 5*60) * 4MHz
        WASHING_8MHZ : timer_ticks = 32'd2400_000_000;  //  (5mins == 5*60) * 8MHz

        SPINNING_1MHZ : timer_ticks = 32'd60_000_000;   //  (1mins == 1*60) * 1MHz
        SPINNING_2MHZ : timer_ticks = 32'd120_000_000;  //  (1mins == 1*60) * 2MHz
        SPINNING_4MHZ : timer_ticks = 32'd240_000_000;  //  (1mins == 1*60) * 4MHz
        SPINNING_8MHZ : timer_ticks = 32'd480_000_000;  //  (1mins == 1*60) * 8MHz

        default: timer_ticks = 32'd0;
    endcase
end

endmodule