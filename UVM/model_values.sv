/*
* =============================================================================
*
* - File        : model_values.sv
* - Autor       : Luis Diego Ramírez Leitón (C36421), Rodrigo Sánchez Araya (C37259), Brandon Jiménez Campos (C33972)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 09-07-2026
* - Descripción : Paquete que define la estructura comun utilizada por los
*                 modelos de referencia y el scoreboard para transportar
*                 resultados esperados, operandos, PC y banderas de control.
*
* =============================================================================
*/

// Se crea el paquete con la estructura compartida por los modelos de referencia:
package model_values;
    import instr_pkg::*;

    // Se declara la estructura que transporta el estado teórico de cada instrucción:
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
