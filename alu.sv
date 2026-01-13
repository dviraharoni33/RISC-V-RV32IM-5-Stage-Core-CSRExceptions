module alu 
  (
    input logic [31:0] a,
    input logic [31:0] b,
    input rv32_pkg::alu_op_e op,
    output logic [31:0] result,
    output logic zero_flag
  );
  
 
  import rv32_pkg::*;

  logic [63:0] mul_res_signed;
  logic [63:0] mul_res_unsigned;
  logic [63:0] mul_res_su;
  
  assign mul_res_signed = $signed(a) * $signed(b);
  assign mul_res_unsigned = $unsigned(a) * $unsigned(b);
  assign mul_res_su = $signed(a) * $unsigned(b);
  
  always @(*) begin
    result = 32'b0;
    
    case (op)
      //לוגי
      ALU_ADD: result = a + b; 
      ALU_SUB: result = a - b;
      ALU_XOR: result = a ^ b; 
      ALU_OR:  result = a | b;
      ALU_AND: result = a & b;
      
      //הזזות
      ALU_SLL: result = a << b[4:0];
      ALU_SRL: result = a >> b[4:0];
      ALU_SRA: result = $signed(a) >>> b[4:0];
      
      //השוואות
      ALU_SLT: result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
      ALU_SLTU: result = (a < b) ? 32'b1 : 32'b0;
      
      //כפל
      ALU_MUL: result = mul_res_signed [31:0];
      ALU_MULH: result = mul_res_signed [63:32];
      ALU_MULHSU: result = mul_res_su [63:32];
      ALU_MULHU: result = mul_res_unsigned [63:32];
      
      //חילוק ושארית
      ALU_DIV: result = (b == 0) ? -1 : ($signed(a) / $signed(b));
      ALU_DIVU: result = (b == 0) ? -1 : (a / b);
      ALU_REM: result = (b == 0) ? a : ($signed(a) % $signed(b));
      ALU_REMU: result = (b == 0) ? a : a % b;
      
      ALU_PASS_B: result = b;
      
      default: result = 32'b0;
    endcase
  end
  
  assign zero_flag = (result == 32'b0);
  
endmodule
