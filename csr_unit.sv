module csr_unit
  (
    input logic clk,
    input logic rst_n,
    input logic [31:0] pc_current,
    input logic irq_i,
    input logic is_ecall,
    input logic is_mret,
    input logic is_illegal,
    input logic [11:0] csr_addr,
    input logic [31:0] csr_wdata,
    input logic csr_write,
    output logic [31:0] csr_rdata,
    output logic [31:0] trap_vector,
    output logic [31:0] mepc_out,
    output logic trap_taken,
    output logic is_irq_taken
  );
  
  logic [31:0] mtvec;
  logic [31:0] mepc;
  logic [31:0] mcause;
  logic [31:0] mstatus;
  logic [31:0] mie;
  
  logic irq_pending;
  
  localparam CSR_MSTATUS = 12'h300;
  localparam CSR_MIE = 12'h304;
  localparam CSR_MTVEC = 12'h305;
  localparam CSR_MEPC = 12'h341;
  localparam CSR_MCAUSE = 12'h342;
  localparam CSR_MIP = 13'h344;
  
  assign irq_pending = irq_i && mstatus[3] && mie[11];
  
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mtvec <= 32'd40;
      mepc <= 32'b0;
      mcause <= 32'b0;
      mstatus <= 32'b1000; 
      mie <= 32'b0;
      trap_taken <= 1'b0;
      is_irq_taken <= 1'b0;
    end else begin
      trap_taken <= 1'b0;
      is_irq_taken <= 1'b0;
      
      if (is_illegal) begin
        mepc <= pc_current + 4;
        mcause <= 32'd2;
        mstatus[7] <= mstatus[3];
        mstatus[3] <= 1'b0;
        trap_taken <= 1'b1;
      end
      
      else if(irq_pending) begin
        mepc <= pc_current;
        mcause <= 32'h8000000B;
        mstatus[7] <= mstatus[3];
        mstatus[3] <= 1'b0;
        trap_taken <= 1'b1;
        is_irq_taken <= 1'b1;
      end
      
      else if (is_ecall) begin
        mepc <= pc_current + 4;
        mcause <= 32'd11;
        mstatus[7] <= mstatus[3];
        mstatus[3] <= 1'b0;
        trap_taken <= 1'b1;
      end
      
      else if (is_mret) begin
        trap_taken <= 1'b0;
        mstatus[3] <= mstatus[7];
        mstatus[7] <= 1'b0;
      end
      
      else if (csr_write) begin
        case (csr_addr)
          CSR_MSTATUS: mstatus <= csr_wdata;
          CSR_MTVEC: mtvec <= csr_wdata;
          CSR_MIE: mie <= csr_wdata;
          CSR_MEPC: mepc <= csr_wdata;
          CSR_MCAUSE: mcause <= csr_wdata;
        endcase
      end
    end
  end
  
  always_comb begin
    case (csr_addr)
      CSR_MSTATUS: csr_rdata = mstatus;
      CSR_MTVEC: csr_rdata = mtvec;
      CSR_MIE: csr_rdata = mie;
      CSR_MEPC: csr_rdata = mepc;
      CSR_MCAUSE: csr_rdata = mcause;
      CSR_MIP: csr_rdata = {20'b0, irq_i, 11'b0};
      default: csr_rdata = 32'b0;
    endcase
  end
  
  assign trap_vector = mtvec;
  assign mepc_out = mepc;
  
endmodule
