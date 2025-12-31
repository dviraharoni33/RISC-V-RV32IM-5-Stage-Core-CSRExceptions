`timescale 1ns/1ps

import rv32_pkg::*;

module tb_rv32_core;
  
  logic clk;
  logic rst_n;
  
  wire [31:0] imem_addr;
  wire [31:0] imem_data;
  wire [31:0] dmem_addr;
  wire [31:0] dmem_wdata;
  wire dmem_we;
  logic [31:0] dmem_rdata;
  
  initial begin
    clk = 0;
    forever 
      #5 
      clk = ~clk;
  end
  
  rv32_core dut 
  (
    .clk(clk),
    .rst_n(rst_n),
    .imem_addr(imem_addr),
    .imem_data(imem_data),
    .dmem_addr(dmem_addr),
    .dmem_wdata(dmem_wdata),
    .dmem_we(dmem_we),
    .dmem_rdata(dmem_rdata)
  );

  logic [31:0] instr_mem [0:63];
  assign imem_data = instr_mem[imem_addr[7:2]];
  
  logic [31:0] data_mem [0:63];
  assign dmem_rdata = data_mem [dmem_addr[7:2]];
  
  always @(posedge clk) begin
    if (dmem_we) begin
      data_mem [dmem_addr[7:2]] <= dmem_wdata;
      $display (">> MEMORY WRITE DETECTED: ADDRESS = %0d, Data = %0d", dmem_addr, dmem_wdata);
    end
  end
      
      
  initial begin
    $dumpfile ("dump.vcd"); 
    $dumpvars (0, tb_rv32_core);
    
    rst_n = 0;
    
    for (int i = 0; i < 64; i++) begin
      instr_mem[i] = 0;
      data_mem[i] = 0;
    end
    
    for (int i = 0; i<32; i++) 
      dut.rf_u.registers[i] = 0;
    
    instr_mem[0] = 32'h00A00093;
    
    instr_mem[1] = 32'h01400113;
    
    instr_mem[2] = 32'h0020A223;
    
    instr_mem[3] = 32'h0040A183;
    
    instr_mem[4] = 32'h00310463;
    
    instr_mem[5] = 32'h3E700213;
    
    instr_mem[6] = 32'h30900293;
    
    
    $display ("---Starting Simulation ---");
    #10 rst_n = 1;
    
    repeat (10) @(posedge clk);
   
    
    $display ("--------------------------------------------");
    $display ("x1 (Base) = %d (Expect 10)", dut.rf_u.registers[1]);
    $display ("x2 (Val) = %d (Expect 20)", dut.rf_u.registers[2]);
    $display ("x3 (Load) = %d (Expect 20)", dut.rf_u.registers[3]);
    $display ("x4 (Skip) = %d (Expect 0) <---- Did branch work?", dut.rf_u.registers[4]);
    $display ("x5 (Jump) = %d (Expect 777) <---- Did branch land?", dut.rf_u.registers[5]);
    $display("---------------------------------------------");
 
    $finish;
    end

endmodule
