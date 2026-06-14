/*
* =============================================================================
*
* - File        : sequencer.sv
* - Autor       : Rodrigo Sanchez Araya (C37259)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción :Define el item de secuencia y el sequencer del ambiente UVM.
*                 El item contiene la randomización de familias de instrucciones,
*                 operaciones, registros e inmediatos, junto con restricciones de
*                 alineamiento y rango compatibles con el DUT darksocv. El
*                 sequencer entrega estos items al driver.
*
* =============================================================================
*/
import instr_pkg::*; 
class my_sequence_item 
    extends uvm_sequence_item; 
    randc instr_set                   instr_type; 
    // Randomizacion de cada uno de los tipos de instrucciones
    randc r_instructions              r_instr;      
    randc i_arithmetic_instructions   i_arith_instr;
    randc i_shift_instructions        i_shift_instr;
    randc i_loads_instructions        i_load_instr; 
    randc i_jump_instructions         i_jump_instr; 
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
    int unsigned addr;

    `uvm_object_utils_begin(my_sequence_item)
        `uvm_field_enum(r_instructions, r_instr, UVM_ALL_ON)
        `uvm_field_enum(i_arithmetic_instructions, i_arith_instr, UVM_ALL_ON)
        `uvm_field_enum(i_shift_instructions, i_shift_instr, UVM_ALL_ON)
        `uvm_field_enum(i_loads_instructions, i_load_instr, UVM_ALL_ON)
        `uvm_field_enum(i_jump_instructions, i_jump_instr, UVM_ALL_ON)
        `uvm_field_enum(s_instructions, s_instr, UVM_ALL_ON)
        `uvm_field_enum(b_instructions, b_instr, UVM_ALL_ON)
        `uvm_field_enum(u_instructions, u_instr, UVM_ALL_ON)
        `uvm_field_enum(j_instructions, j_instr, UVM_ALL_ON)

        `uvm_field_int(rd, UVM_ALL_ON)
        `uvm_field_int(rs1, UVM_ALL_ON)
        `uvm_field_int(rs2, UVM_ALL_ON)
        `uvm_field_int(shamt, UVM_ALL_ON)

        `uvm_field_int(imm_i, UVM_ALL_ON)
        `uvm_field_int(imm_s, UVM_ALL_ON)
        `uvm_field_int(imm_b, UVM_ALL_ON)
        `uvm_field_int(imm_u, UVM_ALL_ON)
        `uvm_field_int(imm_j, UVM_ALL_ON)

        `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_object_utils_end


     //Limita los registros al rango x0-x15, esto con el fin de generar
    //instrucciones con x16-x31, debido a que el darkriscv solamente tiene 16
    //registros 

    constraint registros_x0_x15_c {
            rs1 inside {[5'd0:5'd15]};
            rs2 inside {[5'd0:5'd15]};
            rd inside  {[5'd0:5'd15]};
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
            I_TYPE_ARITHMETIC,
            I_TYPE_SHIFT,
            I_TYPE_LOAD,
            I_TYPE_JUMP,
            //S_TYPE,
            //B_TYPE,
            U_TYPE,
            J_TYPE
        };
    }

     function new(string name = "My_sequence_itemOBJ"); //No parent
        super.new(name); //No parent
    endfunction
endclass



class sequencer extends uvm_sequencer #(my_sequence_item);
    `uvm_component_utils(sequencer)

    virtual ifc_riscv ifc_riscv_obj;

    function new(string name = "SequencerOBJ", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass
