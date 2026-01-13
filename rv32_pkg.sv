package rv32_pkg;

typedef enum logic [6:0]
 {
   OP_LUI    = 7'b0110111, // טעינת מספר גדול
   OP_AUIPC  = 7'b0010111, // PC חישוב כתובת יחסית ל
   OP_JAL    = 7'b1101111, // קפיצה ישירה
   OP_JALR   = 7'b1100111, // קפיצה לכתובת משתנה
   OP_BRANCH = 7'b1100011, // אם.. אז
   OP_LOAD   = 7'b0000011, // קריאה מהזיכרון
   OP_STORE  = 7'b0100011, // כתיבה לזיכרון
   OP_ALU_I  = 7'b0010011, // חישוב רגיסטר-מספר
   OP_ALU_R  = 7'b0110011, // חישוב עם 2 רגיסטרים
   OP_SYSTEM = 7'b1110011  // פקודות מערכת מיוחדות
 } opcode_e;


typedef enum logic [4:0] 
 {
   ALU_ADD    = 5'b00000, 
   ALU_SUB    = 5'b00001,
   ALU_SLL    = 5'b00010,
   ALU_SLT    = 5'b00011,
   ALU_SLTU   = 5'b00100,
   ALU_XOR    = 5'b00101, 
   ALU_SRL    = 5'b00110,
   ALU_SRA    = 5'b00111,
   ALU_OR     = 5'b01000,
   ALU_AND    = 5'b01001,
   ALU_MUL    = 5'b01010,
   ALU_MULH   = 5'b01011,
   ALU_MULHSU = 5'b01100,
   ALU_MULHU  = 5'b01101,
   ALU_DIV    = 5'b01110,
   ALU_DIVU   = 5'b01111,
   ALU_REM    = 5'b10000,
   ALU_REMU   = 5'b10001,
   ALU_PASS_B = 5'b10010
 } alu_op_e;


endpackage
