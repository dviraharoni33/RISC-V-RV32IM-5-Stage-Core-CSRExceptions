module rv32_assertions
  (
    input logic clk,
    input logic rst_n,
    input logic [31:0] x0_val,
    input logic [31:0] pc,
    input logic stall,
    input logic [31:0] pc_next_calc
  );
  
  logic [31:0] prev_pc;
  logic prev_stall;
  logic was_reset;
  
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_pc <= 32'b0;
      prev_stall <= 1'b0;
      was_reset <= 1'b0;
    end else begin
      was_reset <= 1'b1;
      
      if (x0_val != 32'b0) begin
        $display ("[ASSERT FAIL] Time = %0t: x0 register is not zero! Value: %h", $time, x0_val);
      end
      
      if (was_reset && prev_stall && (pc != prev_pc)) begin
        $display ("[ASSERT FAIL] Time = %0t: Pipeline Error: PC changed during STALL! PrevPC = %h, CurrPC = %h", $time, prev_pc, pc);
      end
      
      if (pc[1:0] != 2'b00) begin
        $display ("[ASSERT FAIL] Time = %0t: PC misaligned! PC = %h", $time, pc);
      end
      
      prev_pc <= pc;
      prev_stall <= stall;
    end
  end
  
endmodule
        
        
  
