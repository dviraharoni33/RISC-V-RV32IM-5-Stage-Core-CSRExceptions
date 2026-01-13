module iterative_alu
(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic [31:0] alu_op_raw,
    input  logic [31:0] op_a,
    input  logic [31:0] op_b,
    output logic [31:0] result,
    output logic        ready,
    output logic        busy
);

    rv32_pkg::alu_op_e alu_op;
    assign alu_op = rv32_pkg::alu_op_e'(alu_op_raw);

    typedef enum logic [1:0] {IDLE, CALC, DONE} state_t;
    state_t state;
    logic [4:0] count;
    logic       is_div_op;
    
    logic [31:0] latched_a;
    logic [31:0] latched_b;

    assign is_div_op = (alu_op == rv32_pkg::ALU_DIV  || alu_op == rv32_pkg::ALU_DIVU || 
                        alu_op == rv32_pkg::ALU_REM  || alu_op == rv32_pkg::ALU_REMU);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            busy      <= 1'b0;
            ready     <= 1'b0;
            result    <= 32'b0;
            count     <= 5'b0;
            latched_a <= 32'b0;
            latched_b <= 32'b0;
        end else begin
            case (state)
                IDLE: begin
                    busy  <= 1'b0;
                    ready <= 1'b0;
                    if (start) begin
                        state     <= CALC;
                        count     <= 5'b0;
                        busy      <= 1'b1;
                        latched_a <= op_a;
                        latched_b <= op_b;
                    end
                end

                CALC: begin
                    busy  <= 1'b1;
                    count <= count + 1'b1;
                    
                    if ((!is_div_op && count == 5'd5) || (is_div_op && count == 5'd15)) begin
                        state <= DONE;
                        case (alu_op)
                            rv32_pkg::ALU_MUL:    result <= latched_a * latched_b;
                            rv32_pkg::ALU_MULH:   result <= ($signed(latched_a) * $signed(latched_b)) >>> 32;
                            rv32_pkg::ALU_MULHSU: result <= ($signed(latched_a) * $unsigned(latched_b)) >>> 32;
                            rv32_pkg::ALU_MULHU:  result <= ($unsigned(latched_a) * $unsigned(latched_b)) >>> 32;
                            rv32_pkg::ALU_DIV:    result <= (latched_b == 0) ? 32'hFFFFFFFF : ($signed(latched_a) / $signed(latched_b));
                            rv32_pkg::ALU_DIVU:   result <= (latched_b == 0) ? 32'hFFFFFFFF : (latched_a / latched_b);
                            rv32_pkg::ALU_REM:    result <= (latched_b == 0) ? latched_a : ($signed(latched_a) % $signed(latched_b));
                            rv32_pkg::ALU_REMU:   result <= (latched_b == 0) ? latched_a : (latched_a % latched_b);
                            default:              result <= 32'b0;
                        endcase
                    end
                end

                DONE: begin
                    busy  <= 1'b0;
                    ready <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
