/*
* =============================================================================
*
* - File        : instr_pkg.sv
* - Autor       : Rodrigo Sanchez Araya (C37259)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción :Paquete de tipos para el generador de instrucciones RISC-V.
*                 Agrupa enums para seleccionar familias de instrucciones
*                 (R, I, S, B, U, J, etc.) y operaciones específicas, junto con
*                 structs packed que respetan la posición de bits de cada formato
*                 de instrucción. El driver utiliza estas definiciones para llenar
*                 los campos correspondientes, formar la palabra de instrucción de
*                 32 bits y escribirla en la memoria interna del DUT.
*
* =============================================================================
*/
package  instr_pkg; 

//Enum con los tipos de instruccion disponibles y con la asignacion de un codigo para poder utilizarlos dentro de los constrains para definir sobre cuales datos van a variar las randomizaciones

typedef enum logic [3:0] {
    R_TYPE                  = 4'b0001, 
    I_TYPE_ARITHMETIC       = 4'b0010,
    I_TYPE_SHIFT            = 4'b0011,
    I_TYPE_LOAD             = 4'b0100,
    I_TYPE_JUMP             = 4'b1001,
    S_TYPE                  = 4'b1010,
    B_TYPE                  = 4'b1011,
    U_TYPE                  = 4'b1100,
    J_TYPE                  = 4'b1101
} instr_set;



/*
* -> hacer un tipo case en otro modulo para cada tipo de instruccion instruccion y dentro
*  de esos buscar las instrucciones y hardcodear el strig para ir a buscar
*  en los structs los distintos valores
*/

/*
*Definicion de las diversas instrucciones que se tienen 
*/
typedef enum logic[3:0]{
  ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
}r_instructions; 

typedef enum logic[3:0]{
  ADDI, SLTI, SLTIU, XORI, ORI, ANDI
}i_arithmetic_instructions; 

typedef enum logic[3:0]{
    SLLI, SRLI, SRAI  
}i_shift_instructions; 

typedef enum logic[3:0]{
   LB, LH, LW, LBU, LHU 
}i_loads_instructions; 

typedef enum logic[3:0]{
    SB, SH, SW
}s_instructions; 

typedef enum logic[3:0]{
    BEQ, BNE, BLT, BGE, BLTU, BGEU    
}b_instructions; 

typedef enum logic[3:0]{
    LUI, 
    //AUIPC
}u_instructions; 

typedef enum logic[3:0]{
    JAL
} j_instructions; 

typedef enum logic[3:0]{
    JALR
}i_jump_instructions; 

/*
* Como se tiene una organizacion de las intrucciones 
* se puede simplemente devolver despues se le asigna el valor a un logic
* [31:0] para mandar la instruccion 
*/


typedef struct packed{
    logic [6:0] funct7;   // Bits [31:25]
    logic [4:0] rs2;      // Bits [24:20]
    logic [4:0] rs1;      // Bits [19:15]
    logic [2:0] funct3;   // Bits [14:12]
    logic [4:0] rd;       // Bits [11:7]
    logic [6:0] opcode;   // Bits [6:0]
}r_instr_t;


typedef struct packed {
    logic [11:0] imm;     // Bits [31:20]
    logic [4:0]  rs1;     // Bits [19:15]
    logic [2:0]  funct3;  // Bits [14:12]
    logic [4:0]  rd;      // Bits [11:7]
    logic [6:0]  opcode;  // Bits [6:0]
}i_arithmetic_instr_t;

typedef struct packed {
    logic [6:0] funct7;   // Bits [31:25]
    logic [4:0] shamt;    // Bits [24:20]
    logic [4:0] rs1;      // Bits [19:15]
    logic [2:0] funct3;   // Bits [14:12]
    logic [4:0] rd;       // Bits [11:7]
    logic [6:0] opcode;   // Bits [6:0]
} i_shift_instr_t;

typedef struct packed {
    logic [11:0] offset;  // Bits [31:20]
    logic [4:0]  rs1;     // Bits [19:15] base register
    logic [2:0]  funct3;  // Bits [14:12]
    logic [4:0]  rd;      // Bits [11:7]
    logic [6:0]  opcode;  // Bits [6:0]
} i_load_instr_t;

typedef struct packed {
    logic [11:0] offset;  // Bits [31:20]
    logic [4:0]  rs1;     // Bits [19:15] base register
    logic [2:0]  funct3;  // Bits [14:12]
    logic [4:0]  rd;      // Bits [11:7]
    logic [6:0]  opcode;  // Bits [6:0]
}i_jump_instr_t;

// Struct para manejar la estructura de las instrucciones de tipo J
typedef struct packed {
    logic [6:0] imm_11_5; // Bits [31:25]
    logic [4:0] rs2;      // Bits [24:20]
    logic [4:0] rs1;      // Bits [19:15] base register
    logic [2:0] funct3;   // Bits [14:12]
    logic [4:0] imm_4_0;  // Bits [11:7]
    logic [6:0] opcode;   // Bits [6:0]
}s_store_inst_t;

typedef struct packed {
    logic       imm_12;    // Bit  [31]
    logic [5:0] imm_10_5;  // Bits [30:25]
    logic [4:0] rs2;       // Bits [24:20]
    logic [4:0] rs1;       // Bits [19:15]
    logic [2:0] funct3;    // Bits [14:12]
    logic [3:0] imm_4_1;   // Bits [11:8]
    logic       imm_11;    // Bit  [7]
    logic [6:0] opcode;    // Bits [6:0]
}b_branch_instr_t;

typedef struct packed {
    logic [19:0] imm_31_12; // Bits [31:12]
    logic [4:0]  rd;        // Bits [11:7]
    logic [6:0]  opcode;    // Bits [6:0]
} u_intr_t; 


typedef struct packed{
    logic        imm_20;     // Bit  [31]
    logic [9:0]  imm_10_1;   // Bits [30:21]
    logic        imm_11;     // Bit  [20]
    logic [7:0]  imm_19_12;  // Bits [19:12]
    logic [4:0]  rd;         // Bits [11:7]
    logic [6:0]  opcode;     // Bits [6:0]
}j_instr_t; 

endpackage 
