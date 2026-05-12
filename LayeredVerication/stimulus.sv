/*
* =============================================================================
*
* - File        : stimulus.sv
* - Autor       : Rodrigo Sanchez Araya (C37259)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 
* - Descripción : 
*
* =============================================================================
*/

class instruction_stimulus; 
    // Se importa el package de instrucciones
    import instr_pkg::*;
   
    randc intr_set instr_type; // Se randomiza el tipo de instruccion


    // Randomizacion de cada uno de los tipos de instrucciones
    randc r_instructions              r_instr;
    randc i_arithmetic_instructions   i_arith_instr;
    randc i_shift_instructions        i_shift_instr;
    randc i_loads_instructions        i_load_instr;
    randc i_jump_instructions         i_jump_instr;
    randc i_mem_sys_instructions      i_mem_sys_instr;
    randc s_instructions              s_instr;
    randc b_instructions              b_instr;
    randc u_instructions              u_instr;
    randc j_instructions              j_instr;


    // Randomizacion de los valores para algunas de las instrucciones
    // (cuando corresponda) 
    rand logic [4:0] rd;
    rand logic [4:0] rs1;
    rand logic [4:0] rs2;
   

    // Inmediatos separados por formato para evitar despues estar viendo
    // temas de tamanio
    rand logic [11:0] imm_i;
    rand logic [11:0] imm_s;
    rand logic [12:0] imm_b;
    rand logic [19:0] imm_u;
    rand logic [20:0] imm_j;

    // Campos para CSR
    rand logic [11:0] csr;
    rand logic [4:0]  uimm;


    logic [31:0] instr_word; // Palabra donde se guardara la instruccion a 


    // Para no utilizar el 0, esto para no escribir cosas como 0 + 0 o un
    // jum de 0 o asi, es decir, evitar hacer operaciones que involucren el
    // cero 
    constraint rd_no_x0_c {
        if (instr_type inside {R_TYPE, I_TYPE_ARITHMETIC, I_TYPE_SHIFT, I_TYPE_LOAD, I_TYPE_JUMP, U_TYPE, J_TYPE}) {
            rd != 5'd0;
        }
    }


    constraint shift_c {
        if (instr_type == I_TYPE_SHIFT) {
            shamt inside {[0:31]};
        }
    }
    // Los branches y tambien JAL usan inmediatos alineados a 2 bytes por eso el bit cero
    // debe de ser 0 
    constraint branch_alignment_c {
        if (instr_type == B_TYPE or instr_type == J_TYPE) {
            imm_b[0] == 1'b0;
        }
    }

    /* para agregar o quitar familias no implementadas en el driver 
    // Limitacion momentanea de las instrucciones 
    constraint instr_type_soportadas_c {
        instr_type inside {
            R_TYPE                   
            I_TYPE_ARITHMETIC       
            I_TYPE_SHIFT            
            I_TYPE_LOAD            
            I_TYPE_MEMORY_SYSTEM    
            I_TYPE_JUMP                         S_TYPE                                  
            U_TYPE                 
            J_TYPE                  
        };
    }
    */
endclass 



