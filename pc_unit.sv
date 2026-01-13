module pc_unit 
  (
    input logic clk,
    input logic rst_n,
    input logic stall,
    
    input logic pc_src,
    input logic [31:0] pc_target,
    
    output logic [31:0] pc,
    output logic [31:0] pc_next_debug
  );
  
  logic [31:0] pc_next;
  
  assign pc_next_debug = pc_next;
  
  always @(*) begin
    if (pc_src) begin
      pc_next = pc_target;
    end else begin
      pc_next = pc + 4;
    end
  end
  
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc <= 32'b0;
    end else if (!stall) begin
      pc <= pc_next;
    end
  end
  
  
  always_ff @(posedge clk) begin
    if (rst_n) begin
      if (pc[1:0] != 2'b00) 
        $display("[Error] PC Unit: Misaligned PC detected! PC = %h", pc);
    end
  end
  
endmodule
