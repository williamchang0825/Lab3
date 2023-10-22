`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2023 11:42:58 AM
// Design Name: 
// Module Name: fir
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)
(
    output  wire                     awready,
    output  wire                     wready,
    input   wire                     awvalid,
    input   wire [(pADDR_WIDTH-1):0] awaddr,
    input   wire                     wvalid,
    input   wire [(pDATA_WIDTH-1):0] wdata,
    output  wire                     arready,
    input   wire                     rready,
    input   wire                     arvalid,
    input   wire [(pADDR_WIDTH-1):0] araddr,
    output  wire                     rvalid,
    output  wire [(pDATA_WIDTH-1):0] rdata,    
    input   wire                     ss_tvalid, 
    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    input   wire                     ss_tlast, 
    output  wire                     ss_tready, 
    input   wire                     sm_tready, 
    output  wire                     sm_tvalid, 
    output  wire [(pDATA_WIDTH-1):0] sm_tdata, 
    output  wire                     sm_tlast, 
    
    // bram for tap RAM
    output  wire [3:0]               tap_WE,
    output  wire                     tap_EN,
    output  wire [(pDATA_WIDTH-1):0] tap_Di,
    output  wire [(pADDR_WIDTH-1):0] tap_A,
    input   wire [(pDATA_WIDTH-1):0] tap_Do,

    // bram for data RAM
    output  wire [3:0]               data_WE,
    output  wire                     data_EN,
    output  wire [(pDATA_WIDTH-1):0] data_Di,
    output  wire [(pADDR_WIDTH-1):0] data_A,
    input   wire [(pDATA_WIDTH-1):0] data_Do,

    input   wire                     axis_clk,
    input   wire                     axis_rst_n

);

    wire ap_start;
    wire ap_done;
    wire ap_idle;
    reg [10:0] cnt;
    reg [31:0] mem [0:72];
    reg [31:0] ory [0:121];
    reg ss_tready_temp;
    reg [31:0]sm_tdata_temp;
    reg [31:0] data_A_temp;
    reg [3:0] curr_state;
    reg [3:0] next_state;
    reg [31:0] add_temp;
    reg [10:0] cnt_temp;
    integer r;
    parameter IDLE = 4'b0000;
    parameter S0 = 4'b0001;
    parameter S1 = 4'b0010;
    parameter S2 = 4'b0011;
    parameter S3 = 4'b0100;
    parameter S4 = 4'b0101;
    parameter S5 = 4'b0110;
    
    assign wready = wvalid;
    assign awready = awvalid;
    assign arready = arvalid;
    assign rvalid = arvalid;
    assign tap_Di = wdata;
    assign tap_WE = 4'b1111;
    assign tap_A = awaddr>>1;
    assign tap_EN = 1;
    assign data_Di = ss_tdata;
    assign data_WE = 4'b1111;
    assign data_A = data_A_temp;
    assign data_EN = 1;
    assign ss_tready = ss_tready_temp;
    assign rdata = mem [araddr] ;
    assign sm_tdata = add_temp;
    assign ap_start = mem [0][0];
    assign ap_done = mem [0][1];
    assign ap_idle = mem [0][2];
    assign sm_tvalid = ss_tready;
    assign sm_tlast = (sm_tdata == -915 && cnt == 600) ? 1 : 0;
    
    
    always @ (*) begin
        if(awaddr)data_A_temp <= awaddr>>2;
        if(araddr)data_A_temp <= araddr>>2;
    end
    
    always @ (*) begin
        cnt <= (cnt_temp/2) + 1;
    end    
    
    always @ (posedge axis_clk or negedge axis_rst_n) begin
    if(~axis_rst_n) data_A_temp <= 0;
    else
        case(data_A_temp)
            18 : data_A_temp <= 8;
            8  : data_A_temp <= 9;
            9  : data_A_temp <= 10;
            10 : data_A_temp <= 11;
            11 : data_A_temp <= 12;
            12 : data_A_temp <= 13;
            13 : data_A_temp <= 14;
            14 : data_A_temp <= 15;
            15 : data_A_temp <= 16;
            16 : data_A_temp <= 17;
            17 : data_A_temp <= 18;
        endcase
    end    
    always @ (posedge axis_clk) begin
        if(curr_state == 4) 
            case(data_A)                     
                8 :  add_temp = ory [2 + 11*(((cnt%11)+10)%11)];
                9 :  add_temp = add_temp + ory [3 + 11*(((cnt%11)+9)%11)];
                10 : add_temp = add_temp + ory [4 + 11*(((cnt%11)+8)%11)];
                11 : add_temp = add_temp + ory [5 + 11*(((cnt%11)+7)%11)];
                12 : add_temp = add_temp + ory [6 + 11*(((cnt%11)+6)%11)];
                13 : add_temp = add_temp + ory [7 + 11*(((cnt%11)+5)%11)];
                14 : add_temp = add_temp + ory [8 + 11*(((cnt%11)+4)%11)];
                15 : add_temp = add_temp + ory [9 + 11*(((cnt%11)+3)%11)];
                16 : add_temp = add_temp + ory [10 + 11*(((cnt%11)+2)%11)];
                17 : add_temp = add_temp + ory [11 + 11*(((cnt%11)+1)%11)];
                18 : add_temp = add_temp + ory [12 + 11*(((cnt%11))%11)];
            endcase
    end
        
    always @ (posedge axis_clk or negedge axis_rst_n)   
        if(~axis_rst_n) curr_state <= IDLE;
        else    curr_state <= next_state; 
                
    always @ (*)
        case(curr_state)
            IDLE : if (awready) next_state = S0;
                   else         next_state = IDLE;
            S0   : if (araddr == 72 && awaddr ==0) next_state = S1;
                   else         next_state = S0;
            S1   : if (ap_start) next_state = S2;
                   else         next_state = S1;    
            S2   : if (ss_tready) next_state = S3;        
                   else         next_state = S2;
            S3   : if (cnt == 600 && data_A ==18) next_state = S4;
                   else         next_state = S3;
            S4   : if (arvalid) next_state = S5;
                   else         next_state = S4;
                   
        endcase
    always @ (*)
        case(curr_state)
            IDLE : begin
                        ss_tready_temp <= 0;
                        cnt_temp <= 0;
                        for (r=1 ; r<=121 ; r=r+1) begin
                            ory[r] = 0;                            
                        end
                   end
            S0   : begin
                        mem [tap_A<<1] <= tap_Do ;
                        mem [data_A] <= data_Do;            
                        add_temp <= 0;        
                   end
            S1   : begin
                        mem [0] <= wdata;                       
                        
                   end          
            S2   : begin
                        mem [0] <= 0;
                        if(data_A == 18) ss_tready_temp <= 1;
                        ory [(data_A - 7) + 11*(data_Di%11)] <= mem [data_A<<2] * data_Do;
                   end    
            S3   : begin
                        if(data_A == 18) ss_tready_temp <= 1;
                        else if(ss_tready_temp <= 1) ss_tready_temp <= 0;      
                        ory [(data_A - 7) + 11*(cnt%11)] <= mem [data_A<<2] * data_Do; 
                        if (data_A == 8) cnt_temp = cnt_temp + 1; 
                   end                                         
            S4   : begin
                        mem [0] <= 2;
                   end  
            S5   : begin
                        mem [0] <= 4;
                   end                       
        endcase

endmodule
