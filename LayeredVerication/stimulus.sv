/*
* =============================================================================
*
* - File        : stimulus.sv
* - Autor       : Rodrigo Sanchez Araya (C37259)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción : Generador de estímulos para instrucciones RISC-V. La clase
*                 randomiza los campos que luego utiliza el driver para construir
*                 la instrucción final de 32 bits e insertarla en la memoria del
*                 DUT. Sus constraints aseguran registros observables, rangos
*                 válidos para shifts y alineamiento correcto para branches,
*                 jumps y loads
*
* ==============================================================================
*/
import instr_pkg::*;
class instruction_stimulus; 
    // Se importa el package de instrucciones

   
    randc instr_set instr_type; // Se randomiza el tipo de instruccion


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
    rand logic [4:0] shamt; 

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


   
    // // Evita que las instrucciones que escriben resultado usen x0 como registro destino.
    // Esto ayuda a que el resultado sea observable, porque x0 siempre vale cero.
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
        if (instr_type == B_TYPE) {
            imm_b[0] == 1'b0;
        }
    }

    constraint jal_alignment_c {
        if (instr_type == J_TYPE) {
            imm_j[0] == 1'b0;
        }
    }
    
    // Alineamiento para los load 
    constraint load_alignment_c {
        if (instr_type == I_TYPE_LOAD) {
            if (i_load_instr == LH || i_load_instr == LHU) {
                imm_i[0] == 1'b0;
            }

            if (i_load_instr == LW) {
                imm_i[1:0] == 2'b00;
            }
        }
    }

    /* para agregar o quitar familias no implementadas en el driver 
    // Limitacion momentanea de las instrucciones para poder ir implementando
    // en el driver
    */
    constraint instr_type_soportadas_c {
        instr_type inside {
            R_TYPE,                   
            I_TYPE_ARITHMETIC      
            //I_TYPE_SHIFT,            
            //I_TYPE_LOAD,            
            //I_TYPE_MEMORY_SYSTEM,    
            //I_TYPE_JUMP,                         
            //S_TYPE,                                  
           // U_TYPE,                 
           // J_TYPE                  
        };
    }
    
endclass 



