
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ratan Abhinav Sharma
// Create Date: 09.04.2024 13:17:20
// Design Name: 
// Module Name: top
// Project Name: Processor Design
// Target Devices: 
// Tool Versions: 
// Description: 
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

/////////////////    Defining Fields of 32-Bit Instruction Register

`define  oper_type  IR [31:27]         //// Op Code of Instruction
`define  rdst       IR[26:22]         ////  Address of Destination Register
`define  rsrc1      IR[21:17]        ////   Address of First Source Register
`define  imm_mode   IR[16]          ////    Status of Addressing Mode (Immediate or Register)
`define  rsrc2      IR[15:11]      ////     Address of Second Source Register
`define  isrc       IR[15:0]      ////      Immediate Source Data

/////////////////   Adding MOV and Arithmetic Instructions

`define movsgpr         5'b00000                 ///////// 0
`define mov             5'b00001                /////////  1
`define add             5'b00010               /////////   2
`define sub             5'b00011              /////////    3
`define mul             5'b00100             /////////     4

////////////////   Adding Logical Instructions

`define ror             5'b00101            ////////       5
`define rand            5'b00110           ////////        6
`define rxor            5'b00111          ////////         7
`define rxnor           5'b01000         ////////          8
`define rnand           5'b01001        ////////           9
`define rnor            5'b01010       ////////            10
`define rnot            5'b01011      ////////             11

////////////////   Adding Load and Store Instructions between Data Memory, GPR & Input and Output Ports

`define storereg        5'b01101        ///////            13  store content of reg in data memory
`define storedin        5'b01110       ///////             14  store content of input din in data memory
`define senddout        5'b01111      ///////              15  send content of data memory to output port dout
`define sendreg         5'b10001     ///////               17  send content of data memory to reg



////////////////    Adding Jump, Branch and Halt Operation Instructions

`define jump            5'b10010           ////            18  jump to address
`define jcarry          5'b10011          ////             19  jump to address if Carry is high
`define jnocarry        5'b10100         ////              20     
`define jsign           5'b10101        ////               21  jump if sign
`define jnosign         5'b10110       ////                22
`define jzero           5'b10111      ////                 23  jump if zero
`define jnozero         5'b11000     ////                  24
`define joverflow       5'b11001    ////                   25  jump if overflow
`define jnooverflow     5'b11010   ////                    26

////////////// Halt

`define halt            5'b11011  ///                      27



module top(
input clk,sys_rst,
input [15:0] din,
output reg [15:0] dout);

reg [31:0] IR;                           ////// 32 Bit Instruction Register
reg [15:0] GPR [31:0];                  //////  32 16-Bit General Purpose Registers
reg [15:0] SGPR;                       //////   16-Bit Special General Purpose Register for storing MSB 16 bit of Multiplication Result 
reg [31:0] mul_res;                   //////    32 Bit register for storing Multiplication Result


reg [31:0] inst_mem [15:0];           ////// Adding Program Memory
reg [15:0] data_mem [15:0];          //////  Adding Data Memory       

reg carry = 0, sign = 0, zero = 0, overflow = 0;
reg [16:0] temp_sum;


reg jmp_flag = 0;
reg stop = 0;


task decode_inst();
begin
case(`oper_type)
 `movsgpr: begin
    GPR[`rdst] = SGPR;
  end 
 `mov: begin
    if(`imm_mode)
        GPR[`rdst] = `isrc;
    else
        GPR[`rdst] = GPR[`rsrc1];
    end 
 `add: begin
    if(`imm_mode)
        GPR[`rdst] = GPR[`rsrc1] + `isrc;
    else
        GPR[`rdst] = GPR[`rsrc1] + GPR[`rsrc2];
    end
 `sub: begin
    if(`imm_mode)
        GPR[`rdst] = GPR[`rsrc1] - `isrc;
    else
        GPR[`rdst] = GPR[`rsrc1] - GPR[`rsrc2];
    end 
 `mul: begin
    if(`imm_mode)
        mul_res = GPR[`rsrc1] * `isrc;
    else
        mul_res = GPR[`rsrc1] * GPR[`rsrc2];
    GPR[`rdst] = mul_res[15:0];
    SGPR = mul_res[31:16];
    end 
    
    //////// Logical Operations
  
 `ror: begin
    if(`imm_mode)
        GPR[`rdst] = GPR[`rsrc1] | `isrc;
    else
        GPR[`rdst] = GPR[`rsrc1] | GPR[`rsrc2];
   end 
   
  `rand: begin
    if(`imm_mode)
        GPR[`rdst] = GPR[`rsrc1] & `isrc;
    else
        GPR[`rdst] = GPR[`rsrc1] & GPR[`rsrc2];
   end
   
  `rxor: begin
    if(`imm_mode)
        GPR[`rdst] = GPR[`rsrc1] ^ `isrc;
    else
        GPR[`rdst] = GPR[`rsrc1] ^ GPR[`rsrc2];
   end 
   
   `rxnor: begin
    if(`imm_mode)
        GPR[`rdst] = ~(GPR[`rsrc1] ^ `isrc) ;
    else
        GPR[`rdst] = ~(GPR[`rsrc1] ^ GPR[`rsrc2]) ;
   end 
   
  `rnand:  begin
    if(`imm_mode)
        GPR[`rdst] = ~(GPR[`rsrc1] & `isrc) ;
    else
        GPR[`rdst] = ~(GPR[`rsrc1] & GPR[`rsrc2]) ;
   end 
   
   `rnor:  begin
    if(`imm_mode)
        GPR[`rdst] = ~(GPR[`rsrc1] | `isrc) ;
    else
        GPR[`rdst] = ~(GPR[`rsrc1] | GPR[`rsrc2]) ;
   end 
   
    `rnot:  begin
    if(`imm_mode)
        GPR[`rdst] = ~(`isrc) ;
    else
        GPR[`rdst] = ~(GPR[`rsrc1]) ;
   end 
   
   ///////// Load and Store
   
   `storedin: begin
        data_mem[`isrc] = din;
   end
   
   `storereg: begin
        data_mem[`isrc] = GPR[`rsrc1];
   end 
   
   `senddout: begin
        dout = data_mem[`isrc]; 
   end    
   
   `sendreg: begin
        GPR[`rdst] = data_mem[`isrc];
    end
    
    /////// Jump and Branch
    
    `jump: begin
             jmp_flag = 1'b1;
     end  
     
     `jcarry: begin
        if(carry == 1'b1)
            jmp_flag = 1'b1;
        else
            jmp_flag = 1'b0; 
     end  
     
      `jsign: begin
        if(sign == 1'b1)
            jmp_flag = 1'b1;
        else
            jmp_flag = 1'b0; 
     end 
     
      `jzero: begin
        if(zero == 1'b1)
            jmp_flag = 1'b1;
        else
            jmp_flag = 1'b0; 
     end 
      
      `joverflow: begin
        if(overflow == 1'b1)
            jmp_flag = 1'b1;
        else
            jmp_flag = 1'b0; 
     end 
     
     `jnocarry: begin
        if(carry == 1'b0)
            jmp_flag = 1;
        else
            jmp_flag = 0;
      end 
      
     `jnosign: begin
        if(sign == 1'b0)
            jmp_flag = 1;
        else
            jmp_flag = 0;
      end 
      
     `jnozero: begin
        if(zero == 1'b0)
            jmp_flag = 1;
        else
            jmp_flag = 0;
      end  
      
     `jnooverflow: begin
        if(overflow == 1'b0)
            jmp_flag = 1;
        else
            jmp_flag = 0;
      end   
      
      `halt: begin
            stop = 1;
       end       
 endcase
end 
endtask

//////// Adding Condition Flags

task decode_condflag();

begin

//// Sign Flag

if(`oper_type == `mul)

    sign = SGPR[15];
else
    sign = GPR[`rdst][15];

/// Carry Flag
if(`oper_type == `add)
begin
    if(`imm_mode)
        begin
        temp_sum = GPR[`rsrc1] + `isrc;
        carry = temp_sum[16]; 
        end
    else
        begin
        temp_sum = GPR[`rsrc1] + GPR[`rsrc2];
        carry = temp_sum[16];
        end
end 
else
        carry = 1'b0;

///// Zero Flag
if(`oper_type == `mul)
    zero = ~((|GPR[`rdst]) | (|SGPR[15:0]));
else
    zero = ~(|GPR[`rdst]);
    
//// Overflow Flag
if(`oper_type == `add)
begin
    if(`imm_mode)
        overflow =  (~(GPR[`rsrc1][15]) & (~IR[15]) & GPR[`rdst][15]) | (GPR[`rsrc1][15] & IR[15] & ~(GPR[`rdst][15]));
    else
        overflow = (~(GPR[`rsrc1][15]) & ~(GPR[`rsrc2][15]) & GPR[`rdst][15]) | (GPR[`rsrc1][15] & GPR[`rsrc2][15] & ~(GPR[`rdst][15]));
end
if(`oper_type == `sub)
begin
    if(`imm_mode)
        overflow = (GPR[`rsrc1][15] & ~(IR[15]) & ~(GPR[`rdst][15])) | (~(GPR[`rsrc1]) & IR[15] & GPR[`rdst][15]) ; 
    else
        overflow = (GPR[`rsrc1][15] & ~(GPR[`rsrc2][15]) & ~(GPR[`rdst][15])) | (~(GPR[`rsrc1]) & GPR[`rsrc2][15] & GPR[`rdst][15]) ; 
end
else
        overflow = 1'b0; 
        
        
end
endtask

///////// Reading and Loading Program into Memory Array
initial
begin
$readmemb("C:/Users/DELL/Desktop/inst_data.mem",inst_mem);
end

////////  Reading Instructions in Program Memory One by One

reg [2:0] count = 0;
integer PC = 0;

//////// FSM States

parameter idle = 0, fetch_inst = 1, dec_exec_inst = 2, next_inst = 3, sense_halt = 4, delay_next_inst = 5;
/// idle: check reset state
/// fetch_inst: load instruction from Program Memory into IR
/// dec_exec_inst: Decode Opcode Instruction + Execute Instruction + Update Condition Flag
/// next_inst: Next instruction to be fetched

reg [2:0] state = idle, next_state = idle;

////  Reset Decoder
always@(posedge clk)
begin
if(sys_rst)
    state <= idle;
else
    state <= next_state;
end 

/// Next State Decoder + Output Decoder

always@(*)
begin
    case(state)
        idle: begin
            IR = 32'h 0;
            PC = 0;
            next_state = fetch_inst;
        end 
        
        fetch_inst: begin
            IR = inst_mem[PC];
            next_state = dec_exec_inst;
        end 
        
        dec_exec_inst: begin
            decode_inst();
            decode_condflag();
            next_state = delay_next_inst;
        end   
        
        delay_next_inst: begin
        if(count < 4)
            next_state = delay_next_inst;
        else
            next_state = next_inst;
        end 
        
        next_inst: begin
        next_state = sense_halt;
        if(jmp_flag == 1'b1)
            PC = `isrc;
        else
            PC = PC + 1;
        end  
        
        sense_halt: begin
        if(stop == 1'b0)
            next_state = fetch_inst;
        else if(sys_rst == 1'b1)
            next_state = idle;
        else
            next_state = sense_halt;
        end
        
        default:  next_state = idle;
     
     endcase
 end

always@(posedge clk)
begin 
    case(state)
        idle: begin
            count <= 0;
        end  
        
        fetch_inst: begin
            count <= 0;
        end  
        
        dec_exec_inst: begin
            count <= 0;
        end    
        
        delay_next_inst: begin
            count <= count + 1;
        end    
        
        next_inst:  begin
            count <= 0;
        end     
        
        sense_halt: begin
            count <= 0;
        end  
        
        default:  count <= 0;
        
      endcase   
 end
 endmodule       
                    
       
        
            



























/*
always@(posedge clk)
begin
    if(sys_rst)
        begin
        count <= 0;
        PC <= 0;
        end 
    else
    begin
    if(count < 4)
        begin
        count <= count + 1;
        end 
    else
        begin
        PC <= PC + 1;
        count <= 0;
        end    
    end 
end
     
///////// Reading Instructions in Instruction Register

always@(*)
begin
    if(sys_rst)
        begin
        IR = 0;
        end 
     else
     begin
        IR = inst_mem[PC];
        decode_inst();
        decode_condflag();
     end
end 
*/
       

    
        
    
    



    

