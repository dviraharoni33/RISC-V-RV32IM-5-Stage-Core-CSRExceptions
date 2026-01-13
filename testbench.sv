`timescale 1ns/1ps

import rv32_pkg::*;

module tb_rv32_core;
  
  logic clk;
  logic rst_n;
  logic irq;
  
  wire [31:0] imem_addr;
  wire [31:0] imem_data;
  wire [31:0] dmem_addr;
  wire [31:0] dmem_wdata;
  wire dmem_we;
  logic [31:0] dmem_rdata;
  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  rv32_core dut 
  (
    .clk(clk),
    .rst_n(rst_n),
    .irq_i(irq),
    .imem_addr(imem_addr),
    .imem_data(imem_data),
    .dmem_addr(dmem_addr),
    .dmem_wdata(dmem_wdata),
    .dmem_we(dmem_we),
    .dmem_rdata(dmem_rdata)
  );

  //זיכרון פקודות
  logic [31:0] instr_mem [0:127];
  assign imem_data = (imem_addr[31:2] < 128) ? instr_mem[imem_addr[31:2]] : 32'b0;
  
  //זיכרון נתונים
  logic [31:0] data_mem [0:127];
  assign dmem_rdata = (dmem_addr[31:2] < 128) ? data_mem [dmem_addr[31:2]] : 32'b0;
  
  //כתיבה לזיכרון נתונים
  always @(posedge clk) begin
    if (dmem_we) begin
      if (dmem_addr[31:2] < 128) begin 
        data_mem [dmem_addr[31:2]] <= dmem_wdata;
        $display ("[MEM] WRITE: ADDRESS = 0x%0d, Data = %0d", dmem_addr, dmem_wdata);
      end else begin
        $display ("[MEM] Error: Out of bounds write to 0x%0h", dmem_addr);
      end
    end
  end
      
  
  //מעקב בזמן אמת
  always @(posedge clk) begin
    if (rst_n) begin
      if (dut.reg_write_en_wb && dut.rd_addr_wb != 0) begin
        $display ("[wb] Time = %0t | x%0d <= 0x%h (%0d)", $time, dut.rd_addr_wb, dut.wdata_wb, dut.wdata_wb);
      end
      
      if (dut.pc_src_ex) begin
        if (dut.trap_taken) begin
           if (dut.is_irq_taken)
              $display ("[IRQ] Time = %0t | HARDWARE INTERRUPT TAKEN! Jumping to Handler => PC = 0x%h", $time,  dut.pc_target_ex);
           else
              $display ("[TRAP] Time = %0t | EXCEPTION TAKEN! Jumping to Handler => PC = 0x%h", $time, dut.csr_inst.mcause,  dut.pc_target_ex);
        end
        else if (dut.id_ex_reg.is_mret)
          $display ("[mret] Time = %0t | Returning from Trap => PC = 0x%h", $time, dut.pc_target_ex);
      end
    end
  end
  
 
   initial begin
    $dumpfile ("dump.vcd"); 
    $dumpvars (0, tb_rv32_core);
      
    //איפוס זכרונות
    for (int i = 0; i < 128; i++) begin
      instr_mem[i] = 32'h00000013;
      data_mem[i] = 0;
    end
    
    //טעינת תוכנית בדיקה

    // הגדרת פסיקות
    instr_mem[0] = 32'h08000313; 
    instr_mem[1] = 32'h30531073; 
    instr_mem[2] = 32'h80000393; 
    instr_mem[3] = 32'h30439073; 
    instr_mem[4] = 32'h00800413; 
    instr_mem[5] = 32'h30041073; 
    
    // בדיקות לוגיקה וזיכרון
    instr_mem[6] = 32'h00A00093; 
    instr_mem[7] = 32'h00500113; 
    instr_mem[8] = 32'h002081B3; 
    instr_mem[9] = 32'h02208233; 
    instr_mem[10] = 32'h00402023; 
    instr_mem[11] = 32'h00002283; 
    
    instr_mem[12] = 32'h00209463;
    instr_mem[13] = 32'h00000A13;
    instr_mem[14] = 32'h00100A13; 
     
    instr_mem[15] = 32'h00200513;
    instr_mem[16] = 32'h00151513;
    
    instr_mem[17] = 32'hFFFFFFFF;
    instr_mem[18] = 32'h0000006F;
      
    instr_mem[32] = 32'hABC00F13; 
    instr_mem[33] = 32'h30200073; 
    
    
    //הרצת סימולציה
    $display ("---Starting Simulation ---");
    irq = 0;
    rst_n = 0;
    #15 rst_n = 1;
    
    // המתנה לביצוע חישובים
    #500;
    
    // בדיקת לוגיקה
    $display ("--- CHECKING ALU & MEMORY LOGIC ---");
    check_reg (3, 15, "ALU ADD (10+5)");
    check_reg (4, 50, "ALU MUL (10*5)");
    check_reg (5, 50, "LW (Load-Use)");
     
     $display ("--- CHECKING SHIFT LOGIC ---");
     check_reg (20, 1, "BNE (Branch if Not Equal)");
     
     $display ("--- CHECKING SHIFT LOGIC ---");
     check_reg (10, 4, "SLLI (Shift Left 2 << 1)");

    
     $display ("-------------------------------------------");
     $display ("--- Final Interrupt Check ---");
     
     if (dut.rf_inst.registers[30] == 32'hFFFFFABC)
        $display ("[PASS] Interrupt Handler Executed! x30 = 0xFFFFFABC");
     else
        $display ("[FAIL] Interrupt Handler DID NOT Execute. x30 = 0x%h", dut.rf_inst.registers[30]);

     $display("--------------------------------------------");
 
    $finish;
    end
    
  task check_reg (input int reg_idx, input int expected, input string name);
    if (dut.rf_inst.registers [reg_idx] == expected)
      $display ("[PASS] %s : x%0d = %0d", name, reg_idx, expected);
    else
      $display ("[FAIL] %s : x%0d = %0d (Expected %0d)", name, reg_idx, dut.rf_inst.registers [reg_idx], expected);
  endtask

endmodule
