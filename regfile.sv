module regfile
  (
    input logic clk,
    input logic rst_n,
    
    input logic [4:0] rs1_addr,
    input logic [4:0] rs2_addr,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,
    
    input logic [4:0] rd_addr,
    input logic [31:0] wdata,
    input logic we,
    
    output logic [31:0] x0_debug
  );
  
  logic [31:0] registers [31:0];
  
  assign x0_debug = registers[0];
  
  assign rs1_data = (rs1_addr == 5'b0) ? 32'b0 : registers[rs1_addr];
  assign rs2_data = (rs2_addr == 5'b0) ? 32'b0 : registers[rs2_addr];
  
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      for (int i = 0; i < 32; i++) begin
        registers[i] <= 32'b0;
      end
    end
    
    else if (we && (rd_addr != 5'b0)) begin
      registers[rd_addr] <= wdata;
    end
  end
  
  
  always_ff @(posedge clk) begin
    if (rst_n) begin
      if (rs1_addr == 5'b0 && rs1_data != 32'b0) 
        $display("[Error] RegFile: Reading x0 (rs1) returned non-zero value!");
        
      if (rs2_addr == 5'b0 && rs2_data != 32'b0) 
        $display("[Error] RegFile: Reading x0 (rs2) returned non-zero value!");
    end
  end
  
  
endmodule
