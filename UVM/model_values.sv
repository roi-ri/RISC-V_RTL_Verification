/*
*
* =============================================================================
*
* - File        : model_values.sv
* - Autor       : Brandon Jiménez Campos (C33972)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       :
* - Descripción : Contiene las estructuras, tipos de datos y valores utilizados
*                 por los modelos de referencia y el scoreboard para almacenar
*                 los resultados esperados de las instrucciones RISC-V.
*
* =============================================================================
*/
package model_values;
    import instr_pkg::*;
    typedef struct {
        logic [31:0] res_ref;
        logic [4:0]  rd;
        string       instr_name;
        instr_set     instr_type;
        logic [31:0] pc_ref;
        logic        branch;
        logic [31:0] pc_ref_next;
        logic [31:0] rs1_val;
        logic [31:0] rs2_val;
        logic [31:0] imm;
        logic [4:0]  rs1;
        logic [4:0]  rs2;
        logic [4:0]  shamt;
        logic        pc_4;
        logic        valid;
        logic        writes_rd;
        logic        check_pc;
    } result;
endpackage