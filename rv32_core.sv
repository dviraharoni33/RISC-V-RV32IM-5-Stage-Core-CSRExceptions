`timescale 1ns/1ps

`include "rv32_pkg.sv"
`include "iterative_alu.sv"
`include "alu.sv"
`include "hazard_unit.sv"
`include "regfile.sv"
`include "pc_unit.sv"
`include "control_unit.sv"
`include "imm_gen.sv"
`include "csr_unit.sv"
`include "rv32_assertions.sv"

module rv32_core import rv32_pkg::*;
 (
 input logic clk,
 input logic rst_n,
 input logic irq_i,
  
 output logic [31:0] imem_addr,
 input logic [31:0] imem_data,
  
 output logic [31:0] dmem_addr,
 output logic [31:0] dmem_wdata,
 output logic dmem_we,
 input logic [31:0] dmem_rdata
 );
  
  
  struct packed 
  {
    logic [31:0] pc;
    logic [31:0] instr;
  } if_id_reg;

  struct packed 
  {
    logic [31:0] pc;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] imm;
    logic [4:0] rs1_addr;
    logic [4:0] rs2_addr;
    logic [4:0] rd_addr;
    logic [2:0] funct3;
    
    //Control Signals
    alu_op_e alu_op;
    logic alu_src_a; 
    logic alu_src_b; 
    logic reg_write;
    logic mem_to_reg;
    logic mem_write;
    logic is_branch;
    logic is_jump;
    logic is_jalr; 
    
    //CSR Singels
    logic csr_write;
    logic is_ecall;
    logic is_mret;
    logic is_illegal;
    
  } id_ex_reg;

  struct packed 
  {
    logic [31:0] alu_result;
    logic [31:0] rs2_data;
    logic [4:0] rd_addr;
    
    logic reg_write;
    logic mem_to_reg;
    logic mem_write;
    
    logic [31:0] csr_data;
    logic is_csr_op;
  } ex_mem_reg;

  struct packed
  {
    logic [31:0] alu_result;
    logic [31:0] mem_rdata;
    logic [31:0] csr_data;
    logic [4:0] rd_addr;
    
    logic reg_write;
    logic mem_to_reg;
    logic is_csr_op;
  } mem_wb_reg;
  
  
  logic [31:0] current_pc;
  logic [31:0] rs1_data_raw, rs2_data_raw;
  logic [31:0] imm;
  logic stall_global;
  logic flush_load_use;
  logic flush_branch;
  logic flush_trap;
  
  logic pc_src_ex;
  logic [31:0] pc_target_ex;
  
  alu_op_e alu_op_id;
  logic alu_src_a_id, alu_src_b_id, reg_write_id, mem_to_reg_id, mem_write_id;
  logic is_branch_id, is_jump_id, is_jalr_id;
  logic csr_write_id, is_ecall_id, is_mret_id, is_illegal_id;
  
  logic reg_write_en_wb;
  logic [4:0] rd_addr_wb;
  logic [31:0] wdata_wb;
  
  logic [31:0] alu_in_a, alu_in_b, alu_result_ex;
  logic [1:0] forward_a, forward_b;
  logic zero_ex;
  logic [31:0] fwd_rs1_data, fwd_rs2_data; 
  logic [31:0] csr_rdata_ex;
  logic [31:0] trap_vector;
  logic [31:0] mepc_out;
  logic trap_taken;
  logic is_irq_taken;
  
  logic [31:0] id_ex_pc_wire;
  logic [31:0] id_ex_imm_wire;
  logic [31:0] id_ex_rs1_data_wire;
  logic [31:0] id_ex_rs2_data_wire;
  logic [2:0]  id_ex_funct3_wire;
  logic [11:0] id_ex_csr_addr_wire;
  logic [31:0] if_id_instr_wire;
  
  logic is_branch_wire;
  logic is_jump_wire;
  logic is_jalr_wire;
  logic is_mret_wire;
  logic is_ecall_wire;
  logic csr_write_wire;
  logic is_illegal_wire;
  
  logic mul_busy;
  logic mul_ready;
  logic [31:0] mul_result;
  logic is_mul_op;
  
  logic [31:0] x0_debug_wire;
  logic [31:0] pc_next_debug_wire;
  
  logic stall_alu;
  
  assign is_mul_op = (id_ex_reg.alu_op >= ALU_MUL && id_ex_reg.alu_op <= ALU_REMU);
  assign stall_alu = (is_mul_op && !mul_ready);
  
  assign id_ex_pc_wire       = id_ex_reg.pc;
  assign id_ex_imm_wire      = id_ex_reg.imm;
  assign id_ex_rs1_data_wire = id_ex_reg.rs1_data;
  assign id_ex_rs2_data_wire = id_ex_reg.rs2_data;
  assign id_ex_funct3_wire   = id_ex_reg.funct3;
  assign id_ex_csr_addr_wire = id_ex_reg.imm[11:0];
  assign if_id_instr_wire    = if_id_reg.instr;
  
  assign is_branch_wire = id_ex_reg.is_branch;
  assign is_jump_wire   = id_ex_reg.is_jump;
  assign is_jalr_wire   = id_ex_reg.is_jalr;
  assign is_mret_wire   = id_ex_reg.is_mret;
  assign is_ecall_wire  = id_ex_reg.is_ecall;
  assign csr_write_wire = id_ex_reg.csr_write;
  assign is_illegal_wire = id_ex_reg.is_illegal;
  
  
  //IF
  pc_unit pc_i
  (
    .clk (clk),
    .rst_n (rst_n),
    .stall (stall_global),
    .pc_src (pc_src_ex),
    .pc_target (pc_target_ex),
    .pc (current_pc),
    .pc_next_debug (pc_next_debug_wire)
  );
  
  assign imem_addr = current_pc;

  
  //IF/ID
  always_ff @(posedge clk or negedge rst_n) begin
    
    if (!rst_n) begin
      if_id_reg.pc <= 32'b0;
      if_id_reg.instr <= 32'h00000013;
      
    end else if (flush_branch || flush_trap) begin
      if_id_reg.pc <= 32'b0;
      if_id_reg.instr <= 32'h00000013;
        
    end else if (!stall_global) begin
      if_id_reg.pc <= current_pc;
      if_id_reg.instr <= imem_data;
    end
  end
  
  
  //ID
  logic [4:0] rs1_addr, rs2_addr, rd_addr;
  logic [2:0] funct3;
  
  assign rs1_addr = if_id_instr_wire[19:15];
  assign rs2_addr = if_id_instr_wire[24:20];
  assign rd_addr = if_id_instr_wire[11:7];
  assign funct3 = if_id_instr_wire[14:12];
  
  regfile rf_inst 
  (
    .clk (~clk),
    .rst_n (rst_n),
    .rs1_addr (rs1_addr),
    .rs2_addr (rs2_addr),
    .rs1_data (rs1_data_raw),
    .rs2_data (rs2_data_raw),
    .we (reg_write_en_wb),
    .rd_addr (rd_addr_wb),
    .wdata (wdata_wb),
    .x0_debug (x0_debug_wire)
  );
  
  
  imm_gen imm_gen_inst
  (
    .instr (if_id_instr_wire),
    .imm (imm)
  );
  
  //control unit
  control_unit ctrl_unit_inst
  (
    .instr (if_id_instr_wire),
    .alu_op (alu_op_id),
    .alu_src_a (alu_src_a_id), 
    .alu_src_b (alu_src_b_id), 
    .reg_write (reg_write_id),
    .mem_to_reg (mem_to_reg_id),
    .mem_write (mem_write_id),
    .is_branch (is_branch_id),
    .is_jump (is_jump_id),
    .is_jalr (is_jalr_id),
    .csr_write (csr_write_id),
    .is_ecall (is_ecall_id),
    .is_mret (is_mret_id),
    .is_illegal (is_illegal_id)
  );
  
  
  //Load-Use & Forwarding
  hazard_unit hu_inst
  (
    .rs1_addr_id (rs1_addr),
    .rs2_addr_id (rs2_addr),
    .mem_to_reg_ex (id_ex_reg.mem_to_reg), 
    .rd_addr_ex (id_ex_reg.rd_addr),         
    
    .rs1_addr_ex (id_ex_reg.rs1_addr),
    .rs2_addr_ex (id_ex_reg.rs2_addr),
    .rd_addr_mem (ex_mem_reg.rd_addr),
    .rd_addr_wb (mem_wb_reg.rd_addr),
    .reg_write_mem (ex_mem_reg.reg_write),
    .reg_write_wb (mem_wb_reg.reg_write),
    .reg_write_ex (id_ex_reg.reg_write),
    
    .mul_stall (stall_alu),
    .forward_a (forward_a),
    .forward_b (forward_b),
    .stall_if (stall_global),  
    .stall_id (),              
    .flush_ex (flush_load_use)  
  );
  
  
  // ID/EX
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_ex_reg <= '0;
    end 
    else if (flush_branch || flush_load_use || flush_trap) begin
      id_ex_reg <= '0;
    end 
    else if (!stall_global) begin
      id_ex_reg.pc <= if_id_reg.pc;
      id_ex_reg.rs1_data <= rs1_data_raw;
      id_ex_reg.rs2_data <= rs2_data_raw;
      id_ex_reg.imm <= imm;
      id_ex_reg.rs1_addr <= rs1_addr;
      id_ex_reg.rs2_addr <= rs2_addr;
      id_ex_reg.rd_addr <= rd_addr;
      
      id_ex_reg.alu_op <= alu_op_id;
      id_ex_reg.alu_src_a <= alu_src_a_id; 
      id_ex_reg.alu_src_b <= alu_src_b_id; 
      id_ex_reg.reg_write <= reg_write_id;
      id_ex_reg.mem_to_reg <= mem_to_reg_id;
      id_ex_reg.mem_write <= mem_write_id;
      id_ex_reg.is_branch <= is_branch_id;
      id_ex_reg.is_jump <= is_jump_id;
      id_ex_reg.is_jalr <= is_jalr_id;      
      id_ex_reg.funct3 <= funct3;
      
      id_ex_reg.csr_write <= csr_write_id;
      id_ex_reg.is_ecall <= is_ecall_id;
      id_ex_reg.is_mret <= is_mret_id;
      id_ex_reg.is_illegal <= is_illegal_id;
    end
  end
    
  
  //EX
  assign fwd_rs1_data = (forward_a == 2'b01) ? ex_mem_reg.alu_result : (forward_a == 2'b10) ? wdata_wb : id_ex_rs1_data_wire;
  assign fwd_rs2_data = (forward_b == 2'b01) ? ex_mem_reg.alu_result : (forward_b == 2'b10) ? wdata_wb : id_ex_rs2_data_wire;
  assign alu_in_a = (id_ex_reg.alu_src_a) ? id_ex_pc_wire : fwd_rs1_data;
  assign alu_in_b = (id_ex_reg.alu_src_b) ? id_ex_imm_wire : fwd_rs2_data;
  
  iterative_alu mul_div_unit
  (
    .clk (clk),
    .rst_n (rst_n),
    .start (is_mul_op && !mul_busy && !mul_ready),
    .alu_op_raw (32'(id_ex_reg.alu_op)),
    .op_a (alu_in_a),
    .op_b (alu_in_b),
    .result (mul_result),
    .busy (mul_busy),
    .ready (mul_ready)
  );
  
  alu alu_inst 
  (
    .a (alu_in_a),
    .b (alu_in_b),
    .op (id_ex_reg.alu_op),
    .result (alu_result_ex),
    .zero_flag (zero_ex)
  );
  
  
  csr_unit csr_inst
  (
    .clk (clk),
    .rst_n (rst_n),
    .pc_current (id_ex_pc_wire),
    .irq_i (irq_i),
    .is_ecall (is_ecall_wire),
    .is_mret (is_mret_wire),
    .is_illegal (is_illegal_wire),
    .csr_addr (id_ex_csr_addr_wire),
    .csr_wdata (fwd_rs1_data),
    .csr_write (csr_write_wire),
    .csr_rdata (csr_rdata_ex),
    .trap_vector (trap_vector),
    .mepc_out (mepc_out),
    .trap_taken (trap_taken),
    .is_irq_taken (is_irq_taken)
  );
  
    
  logic branch_condition_met; 
  logic [31:0] ex_result_mux;
  
  always_comb begin
    branch_condition_met = 1'b0;
    if (is_branch_wire) begin
      
      case (id_ex_funct3_wire) 
        3'b000: branch_condition_met = (alu_in_a == fwd_rs2_data); 
        3'b001: branch_condition_met = (alu_in_a != fwd_rs2_data);                       
        3'b100: branch_condition_met = ($signed(alu_in_a) < $signed(fwd_rs2_data));  
        3'b101: branch_condition_met = ($signed(alu_in_a) >= $signed(fwd_rs2_data)); 
        3'b110: branch_condition_met = (alu_in_a < fwd_rs2_data);                       
        3'b111: branch_condition_met = (alu_in_a >= fwd_rs2_data);              
        
        default: branch_condition_met = 1'b0;
      endcase
    end
  end
  
  
  always_comb begin
    if (trap_taken) begin
      pc_target_ex = trap_vector;
      end else if (is_mret_wire) begin
        pc_target_ex = mepc_out;
      end else if (is_jalr_wire) begin
        pc_target_ex = alu_result_ex;
      end else begin
        pc_target_ex = id_ex_pc_wire + id_ex_imm_wire;
      end
  end
      
  
  assign pc_src_ex = is_jump_wire || branch_condition_met || trap_taken || is_mret_wire;
  
  assign flush_branch = pc_src_ex;
  
  assign flush_trap = trap_taken || is_mret_wire;
  
  assign ex_result_mux = (is_jump_wire) ? (id_ex_pc_wire + 4) : 
                         (is_mul_op && mul_ready) ? mul_result : 
                         alu_result_ex;
  
  
  //EX/MEM
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ex_mem_reg.alu_result <= 32'b0;
      ex_mem_reg.rs2_data <= 32'b0;
      ex_mem_reg.rd_addr <= 5'b0;
      ex_mem_reg.reg_write <= 1'b0;
      ex_mem_reg.mem_to_reg <= 1'b0;
      ex_mem_reg.mem_write <= 1'b0;
      ex_mem_reg.csr_data <= 32'b0;
      ex_mem_reg.is_csr_op <= 1'b0;
    
    end else begin
      ex_mem_reg.alu_result <= ex_result_mux;
      ex_mem_reg.rs2_data <= fwd_rs2_data;
      ex_mem_reg.rd_addr <= id_ex_reg.rd_addr;
      
      if (stall_alu) begin
        ex_mem_reg.reg_write <= 1'b0;
        ex_mem_reg.mem_write <= 1'b0;
        ex_mem_reg.mem_to_reg <= 1'b0;
        ex_mem_reg.csr_data <= 32'b0;
        ex_mem_reg.is_csr_op <= 1'b0;
      
      end else begin
        ex_mem_reg.reg_write <= id_ex_reg.reg_write;
        ex_mem_reg.mem_write <= id_ex_reg.mem_write;
        ex_mem_reg.mem_to_reg <= id_ex_reg.mem_to_reg;
        ex_mem_reg.is_csr_op <= csr_write_wire;
        ex_mem_reg.csr_data <= csr_rdata_ex;
     end
   end
  end
  
  
  //MEM
  assign dmem_addr = ex_mem_reg.alu_result;
  assign dmem_wdata = ex_mem_reg.rs2_data;
  assign dmem_we = ex_mem_reg.mem_write;
  
  
  // MEM/WB
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_wb_reg.alu_result <= 32'b0;
      mem_wb_reg.mem_rdata <= 32'b0;
      mem_wb_reg.rd_addr <= 5'b0;
      mem_wb_reg.reg_write <= 1'b0;
      mem_wb_reg.mem_to_reg <= 1'b0;
      mem_wb_reg.csr_data <= 32'b0;
      mem_wb_reg.is_csr_op <= 1'b0;
      
    end else begin
      mem_wb_reg.alu_result <= ex_mem_reg.alu_result;
      mem_wb_reg.mem_rdata <= dmem_rdata;
      mem_wb_reg.rd_addr <= ex_mem_reg.rd_addr;
      
      mem_wb_reg.reg_write <= ex_mem_reg.reg_write;
      mem_wb_reg.mem_to_reg <= ex_mem_reg.mem_to_reg;
      
      mem_wb_reg.csr_data <= ex_mem_reg.csr_data;
      mem_wb_reg.is_csr_op <= ex_mem_reg.is_csr_op;
    end
  end
  
 
  //WB
  assign wdata_wb = (mem_wb_reg.mem_to_reg) ? mem_wb_reg.mem_rdata : (mem_wb_reg.is_csr_op) ? mem_wb_reg.csr_data : mem_wb_reg.alu_result;
  
  assign reg_write_en_wb = mem_wb_reg.reg_write;
  assign rd_addr_wb = mem_wb_reg.rd_addr;
  
  
  rv32_assertions assertions_inst 
  (
    .clk (clk),
    .rst_n (rst_n),
    .x0_val (x0_debug_wire),
    .pc (current_pc),
    .stall (stall_global),
    .pc_next_calc (pc_next_debug_wire)
  );
      
endmodule
