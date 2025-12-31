package rv32_pkg;
typedef enum logic [6:0]
 {
   OP_LUI    = 7'b0110111, // טעינת מספר גדול
   OP_AUIPC  = 7'b0010111, // חישוב כתובת יחסית
   OP_JAL    = 7'b1101111, // קפיצה
   OP_JALR   = 7'b1100111, // קפיצה לכתובת משתנה
   OP_BRANCH = 7'b1100011, // אם.. אז
   OP_LOAD   = 7'b0000011, // קריאה מהזיכרון
   OP_STORE  = 7'b0100011, // כתיבה לזיכרון
   OP_ALU_I  = 7'b0010011, // חישוב עם מספר קבוע
   OP_ALU_R  = 7'b0110011, // חישוב בין 2 משתנים
   OP_SYSTEM = 7'b1110011  // פקודות מערכת מיוחדות
 } opcode_e;


typedef enum logic [3:0] 
 {
   ALU_ADD, 
   ALU_SUB,
   ALU_SLL,  // הזזה שמאלה
   ALU_SLT,  // האם קטן מ
   ALU_SLTU, // |האם קטן מ|
   ALU_XOR, 
   ALU_SRL,  // הזזה ימינה
   ALU_SRA,  // הזזה ימינה שומרת סימן
   ALU_OR,
   ALU_AND
 } alu_op_e;



endpackage
