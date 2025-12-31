`timescale 1ns/1ps

`include "rv32_pkg.sv"
`include "alu.sv"
`include "regfile.sv"
`include "pc_unit.sv"

module rv32_core import rv32_pkg::*;
 (
 input logic clk,
 input logic rst_n,
  
 output logic [31:0] imem_addr,
 input logic [31:0] imem_data,
  
 output logic [31:0] dmem_addr,
 output logic [31:0] dmem_wdata,
 output logic dmem_we,
 input logic [31:0] dmem_rdata
 );
  

 opcode_e opcode;
 logic [4:0] rd;
 logic [4:0] rs1;
 logic [4:0] rs2;
 logic [2:0] funct3;
 logic [6:0] funct7;
  
 logic [31:0] imm_i;
 logic [31:0] imm_s;
 logic [31:0] imm_b;
 logic [31:0] imm_j;
 logic [31:0] imm_final;
 logic [31:0] branch_target;
 logic ziro_flag; 
  
 logic [31:0] writeback_data;
 logic [31:0] alu_operand_b;
 logic [31:0] final_wdata;
  
 logic alu_src_imm;
 logic mem_to_reg;
 logic is_branch;     
 logic is_jump;
 logic branch_taken;
 
 logic [31:0] pc_current;
 logic [31:0] alu_result;
 logic [31:0] reg1_data;
 logic [31:0] reg2_data;
 logic reg_write_en;
 alu_op_e alu_ctrl;    


 assign opcode = opcode_e'(imem_data[6:0]);
 assign rd = imem_data[11:7];
 assign rs1 = imem_data[19:15];
 assign rs2 = imem_data[24:20];
 assign funct3 = imem_data[14:12];
 assign funct7 = imem_data[31:25];

 
 assign imm_i = {{20{imem_data[31]}}, imem_data[31:20]};
 assign imm_s = {{20{imem_data[31]}}, imem_data[31:25], imem_data[11:7]};
 assign imm_b = {{20{imem_data[31]}}, imem_data[7], imem_data[30:25], imem_data[11:8], 1'b0};
 assign imm_j = {{12{imem_data[31]}}, imem_data[19:12], imem_data[20], imem_data[30:21], 1'b0};

 always_comb begin
    case (opcode)
        OP_STORE:  imm_final = imm_s;
        OP_BRANCH: imm_final = imm_b;
        OP_JAL:    imm_final = imm_j;
        default:   imm_final = imm_i; 
    endcase
 end

 
 assign branch_target = pc_current + imm_final;
 assign ziro_flag     = (alu_result == 32'b0);

 always_comb begin
    branch_taken = 1'b0;
    if (is_jump) branch_taken = 1'b1;
    else if (is_branch) begin
        case (funct3)
            3'b000: branch_taken = ziro_flag;      // BEQ
            3'b001: branch_taken = !ziro_flag;     // BNE
            default: branch_taken = 1'b0;
        endcase
    end
 end
  

 pc_unit pc_u
 (
   .clk(clk),
   .rst_n(rst_n),
   .stall(1'b0),
   .branch_taken(branch_taken),   
   .branch_target(branch_target), 
   .pc(pc_current)
 );
  
 assign imem_addr = pc_current;

 
 assign writeback_data = (mem_to_reg) ? dmem_rdata : alu_result;
 assign final_wdata    = (opcode == OP_JAL) ? (pc_current + 4) : writeback_data;
  
 regfile rf_u 
 (
   .clk(clk),
   .rs1_addr(rs1),
   .rs2_addr(rs2),
   .rd_addr(rd),
   .wdata(final_wdata), 
   .we(reg_write_en),
   .rs1_data(reg1_data),
   .rs2_data(reg2_data)
 );

 assign alu_operand_b = (alu_src_imm) ? imm_final : reg2_data; 
  
 alu alu_u 
 (
   .a(reg1_data),
   .b(alu_operand_b),   
   .op(alu_ctrl),
   .result(alu_result)
 );
  
 
 assign dmem_addr  = alu_result;
 assign dmem_wdata = reg2_data;
  
 
 always_comb begin
   reg_write_en = 0; 
   dmem_we = 0; 
   alu_src_imm = 0;
   mem_to_reg = 0; 
   is_branch = 0; 
   is_jump = 0; 
   alu_ctrl = ALU_ADD;
    
   case (opcode)
       
     OP_ALU_R: begin
       reg_write_en = 1'b1;
       alu_src_imm = 1'b1; 
       
       case (funct3)
         3'b000: begin
           if (funct7[5]) alu_ctrl = ALU_SUB;
           else
             alu_ctrl = ALU_ADD;
         end
         
           3'b001: alu_ctrl = ALU_SLL;
           3'b010: alu_ctrl = ALU_SLT;
           3'b011: alu_ctrl = ALU_SLTU;
           3'b100: alu_ctrl = ALU_XOR;
           3'b100: begin
             
             if (funct7[5]) alu_ctrl = ALU_SRA;
             else
               alu_ctrl = ALU_SRL;
           end
         
           3'b110: alu_ctrl = ALU_OR;
           3'b111: alu_ctrl = ALU_AND;
           default: alu_ctrl = ALU_ADD;
       endcase
     end
     
             
       OP_ALU_I: begin
         reg_write_en = 1'b1;
         alu_src_imm = 1'b1;
         
         case(funct3)
           
           3'b000: alu_ctrl = ALU_ADD;
           3'b100: alu_ctrl = ALU_XOR;
           3'b110: alu_ctrl = ALU_OR;
           3'b111: alu_ctrl = ALU_AND;
           default: alu_ctrl = ALU_ADD;
         endcase
       end
   
     
     OP_LOAD: begin
         reg_write_en = 1'b1;
         alu_src_imm = 1'b1;
         mem_to_reg = 1'b1;
     end

     OP_STORE: begin
         dmem_we = 1'b1;
         alu_src_imm = 1'b1;
     end

     OP_BRANCH: begin
         is_branch = 1'b1;
         alu_ctrl = ALU_SUB;
     end

     OP_JAL: begin
         is_jump = 1'b1;
         reg_write_en = 1'b1;
    end
      
     OP_LUI: begin
       reg_write_en = 1'b1;
     end
   endcase
 end
 
endmodule
