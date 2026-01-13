module control_unit 
  (
    input logic [31:0] instr,
    output rv32_pkg::alu_op_e alu_op, 
    output logic alu_src_a,
    output logic alu_src_b,
    output logic reg_write,
    output logic mem_to_reg,
    output logic mem_write,
    output logic is_branch,
    output logic is_jump,
    output logic is_jalr,
    output logic csr_write,
    output logic is_ecall,
    output logic is_mret,
    output logic is_illegal
  );

  import rv32_pkg::*;

  always @(*) begin
    alu_op = ALU_ADD;
    alu_src_a = 1'b0;
    alu_src_b = 1'b0;
    reg_write = 1'b0;
    mem_to_reg = 1'b0;
    mem_write = 1'b0;
    is_branch = 1'b0;
    is_jump = 1'b0;
    is_jalr = 1'b0;
    csr_write = 1'b0;
    is_ecall = 1'b0;
    is_mret = 1'b0;
    is_illegal = 1'b0;
      
    case (instr[6:0])
      // R TYPE
      7'b0110011: begin
        reg_write = 1'b1;
        if (instr[31:25] == 7'b0000001) begin 
          case (instr[14:12])
            3'b000: alu_op = ALU_MUL;
            3'b001: alu_op = ALU_MULH;
            3'b010: alu_op = ALU_MULHSU;
            3'b011: alu_op = ALU_MULHU;
            3'b100: alu_op = ALU_DIV;
            3'b101: alu_op = ALU_DIVU;
            3'b110: alu_op = ALU_REM;
            3'b111: alu_op = ALU_REMU;
            default: is_illegal = 1'b1;
          endcase
        end else begin
          case (instr[14:12])
            3'b000: if (instr[30]) alu_op = ALU_SUB; else alu_op = ALU_ADD;
            3'b001: alu_op = ALU_SLL;
            3'b010: alu_op = ALU_SLT;
            3'b011: alu_op = ALU_SLTU;
            3'b100: alu_op = ALU_XOR;
            3'b101: if (instr[30]) alu_op = ALU_SRA; else alu_op = ALU_SRL;
            3'b110: alu_op = ALU_OR;
            3'b111: alu_op = ALU_AND;
            default: is_illegal = 1'b1;
          endcase
        end
      end
      
      // I TYPE ALU
      7'b0010011: begin
        reg_write = 1'b1;
        alu_src_b = 1'b1;
        case (instr[14:12])
          3'b000: alu_op = ALU_ADD;
          3'b010: alu_op = ALU_SLT;
          3'b011: alu_op = ALU_SLTU;
          3'b100: alu_op = ALU_XOR;
          3'b110: alu_op = ALU_OR;
          3'b111: alu_op = ALU_AND;
          3'b001: alu_op = ALU_SLL;
          3'b101: if (instr[30]) alu_op = ALU_SRA; else alu_op = ALU_SRL;
          default: is_illegal = 1'b1;
        endcase
      end
      
      // LOAD
      7'b0000011: begin
        reg_write = 1'b1;
        alu_src_b = 1'b1;
        mem_to_reg = 1'b1;
        alu_op = ALU_ADD;
      end
      
      // STORE
      7'b0100011: begin
        mem_write = 1'b1;
        alu_src_b = 1'b1;
        alu_op = ALU_ADD;
      end
      
      // BRANCH
      7'b1100011: begin
        is_branch = 1'b1;
        alu_op = ALU_SUB;
      end
      
      // JAL
      7'b1101111: begin
        is_jump = 1'b1;
        reg_write = 1'b1;
      end
      
      // JALR
      7'b1100111: begin
        is_jump = 1'b1;
        is_jalr = 1'b1;
        reg_write = 1'b1;
        alu_src_b = 1'b1;
        alu_op = ALU_ADD;
      end
      
      // LUI
      7'b0110111: begin
        reg_write = 1'b1;
        alu_src_b = 1'b1;
        alu_op = ALU_PASS_B;
      end
      
      // AUIPC
      7'b0010111: begin
        reg_write = 1'b1;
        alu_src_a = 1'b1;
        alu_src_b = 1'b1;
        alu_op = ALU_ADD;
      end
      
      // SYSTEM
      7'b1110011: begin
        case (instr[14:12])
          3'b000: begin
            if (instr[31:20] == 12'h000)
              is_ecall = 1'b1;
            else if (instr[31:20] == 12'h302)
              is_mret = 1'b1;
            else
              is_illegal = 1'b1;
          end
          3'b001: begin
            csr_write = 1'b1;
            reg_write = 1'b1;
          end
          default: is_illegal = 1'b1;
        endcase
      end
      
      default: is_illegal = 1'b1;
    endcase
  end      
endmodule
