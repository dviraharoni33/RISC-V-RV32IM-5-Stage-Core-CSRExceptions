module alu import rv32_pkg::*;
  (
    input logic [31:0] a,
    input logic [31:0] b,
    input alu_op_e op,
    output logic [31:0] result
  );
  
  always_comb begin
    result = 32'b0;
    
    case (op)
      ALU_ADD: result = a + b; 
      ALU_SUB: result = a - b;
      ALU_SLL: result = a << b[4:0];  
      ALU_XOR: result = a ^ b; 
      ALU_SRL: result = a >> b[4:0];
      ALU_OR: result = a | b;
      ALU_AND: result = a & b;
    endcase
  end
  
  
endmodule
