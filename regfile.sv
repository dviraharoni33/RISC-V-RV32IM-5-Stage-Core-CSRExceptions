module regfile
  (
    input logic clk,
    input logic [4:0] rs1_addr,
    input logic [4:0] rs2_addr,
    
    input logic [4:0] rd_addr,
    input logic [31:0] wdata,
    input logic we,
    
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
  );
  
  logic [31:0] registers [31:0];
  
  assign rs1_data = (rs1_addr == 5'b0) ? 32'b0 : registers[rs1_addr];
  assign rs2_data = (rs2_addr == 5'b0) ? 32'b0 : registers[rs2_addr];
  
  always_ff @(posedge clk) begin
    if (we && (rd_addr != 5'b0)) begin
      registers[rd_addr] <= wdata;
    end
  end
  
endmodule
