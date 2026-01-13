module hazard_unit
  (
    input logic [4:0] rs1_addr_id,
    input logic [4:0] rs2_addr_id,
    
    input logic [4:0] rs1_addr_ex,
    input logic [4:0] rs2_addr_ex,
    
    input logic [4:0] rd_addr_ex,
    input logic [4:0] rd_addr_mem,
    input logic [4:0] rd_addr_wb,
    
    input logic reg_write_ex,
    input logic reg_write_mem,
    input logic reg_write_wb,
    
    input logic mem_to_reg_ex,
    
    input logic mul_stall,
    
    output logic [1:0] forward_a,
    output logic [1:0] forward_b,
    
    output logic stall_if,
    output logic stall_id,
    output logic flush_ex
  );
  
  always @(*) begin
    forward_a = 2'b00;
    forward_b = 2'b00;
    
    if (reg_write_mem && (rd_addr_mem != 0) && (rd_addr_mem == rs1_addr_ex)) begin
      forward_a = 2'b01;
    end else if (reg_write_wb && (rd_addr_wb != 0) && (rd_addr_wb == rs1_addr_ex)) begin
      forward_a = 2'b10;
    end
    
    if (reg_write_mem && (rd_addr_mem != 0) && (rd_addr_mem == rs2_addr_ex)) begin
      forward_b = 2'b01;
    end else if (reg_write_wb && (rd_addr_wb != 0) && (rd_addr_wb == rs2_addr_ex)) begin
      forward_b = 2'b10;
    end
  end
  
  always @(*) begin
    stall_if = 1'b0;
    stall_id = 1'b0;
    flush_ex = 1'b0;
    
    if (mem_to_reg_ex && ((rd_addr_ex == rs1_addr_id) || (rd_addr_ex == rs2_addr_id))) begin
      stall_if = 1'b0;
      stall_id = 1'b0;
      flush_ex = 1'b0;
    end
    
    if(mul_stall) begin
      stall_if = 1'b1;
      stall_id = 1'b1;
      flush_ex = 1'b0;
    end
  end

endmodule
