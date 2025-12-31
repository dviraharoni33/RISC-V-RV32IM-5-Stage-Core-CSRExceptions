module pc_unit 
  (
    input logic clk,
    input logic rst_n,
    
    input logic stall,
    input logic branch_taken,
    input logic [31:0] branch_target,
    
    output logic [31:0] pc
  );
  
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc <= 32'b0;
    end
  
  else if (!stall) begin
    
    if (branch_taken) begin
      pc <= branch_target;
    end
    
    else begin
      pc <= pc + 4;
    end
  end
  end
  
  
endmodule
