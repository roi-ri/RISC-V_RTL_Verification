/*
* =============================================================================
*
* - File        : mixed_type.sv
* - Autor       : Luis Diego Ramírez Leitón (C36421), Rodrigo Sánchez Araya (C37259), Brandon Jiménez Campos (C33972)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 10-07-2026
* - Descripción :Secuencia UVM dirigida para generar instrucciones mixtas
*                 del conjunto RISC-V soportado por el ambiente. Combina
*                 instrucciones aritméticas, desplazamientos, memoria y control
*                 con saltos controlados para mantener un flujo ejecutable.
*
* =============================================================================
*/

import instr_pkg::*;

class mixed_type_sequence extends base_sequence;

    `uvm_object_utils(mixed_type_sequence)

    function new(string name = "mixed_type_sequence");
        super.new(name);
    endfunction

    virtual task body();

        my_sequence_item my_sequence_item_obj;
        int unsigned rd_value;
        int unsigned rs1_value;
        int unsigned rs2_value;
        int unsigned data_offset;
        int unsigned family;
        int unsigned op;
        int unsigned r_count;
        int unsigned i_arit_count;
        int unsigned i_shift_count;
        int unsigned load_count;
        int unsigned store_count;
        int unsigned branch_count;
        int unsigned u_count;
        int unsigned j_count;
        int unsigned jalr_count;

        if ((cantidad_instrucciones == 0) || (cantidad_instrucciones > 1000)) begin
            cantidad_instrucciones = 1000;
        end

        for (int i = 0; i < cantidad_instrucciones; i++) begin

            my_sequence_item_obj = my_sequence_item::type_id::create("mixed_type_item");
            start_item(my_sequence_item_obj);

            rd_value  = ((i % 19) == 0) ? 0 : ((i % 14) + 1);
            rs1_value = ((i + 3) % 15) + 1;
            rs2_value = i % 16;
            family    = i % 9;
            op        = 0;

            my_sequence_item_obj.rd = rd_value[4:0];
            my_sequence_item_obj.rs1 = rs1_value[4:0];
            my_sequence_item_obj.rs2 = rs2_value[4:0];
            my_sequence_item_obj.shamt = i % 8;
            my_sequence_item_obj.addr = i;
            my_sequence_item_obj.last_item = (i == (cantidad_instrucciones - 1));

            case (family)

                0: begin
                    op = r_count++;
                    my_sequence_item_obj.instr_type = R_TYPE;
                    case (op % 10)
                        0: my_sequence_item_obj.r_instr = ADD;
                        1: my_sequence_item_obj.r_instr = SUB;
                        2: my_sequence_item_obj.r_instr = SLL;
                        3: my_sequence_item_obj.r_instr = SLT;
                        4: my_sequence_item_obj.r_instr = SLTU;
                        5: my_sequence_item_obj.r_instr = XOR;
                        6: my_sequence_item_obj.r_instr = SRL;
                        7: my_sequence_item_obj.r_instr = SRA;
                        8: my_sequence_item_obj.r_instr = OR;
                        default: my_sequence_item_obj.r_instr = AND;
                    endcase
                end

                1: begin
                    op = i_arit_count++;
                    my_sequence_item_obj.instr_type = I_TYPE_ARITHMETIC;
                    case (op % 6)
                        0: begin my_sequence_item_obj.i_arith_instr = ADDI; my_sequence_item_obj.imm_i = 12'h001; end
                        1: begin my_sequence_item_obj.i_arith_instr = SLTI; my_sequence_item_obj.imm_i = 12'hfff; end
                        2: begin my_sequence_item_obj.i_arith_instr = SLTIU; my_sequence_item_obj.imm_i = 12'h020; end
                        3: begin my_sequence_item_obj.i_arith_instr = XORI; my_sequence_item_obj.imm_i = 12'h0f0; end
                        4: begin my_sequence_item_obj.i_arith_instr = ORI; my_sequence_item_obj.imm_i = 12'h800; end
                        default: begin my_sequence_item_obj.i_arith_instr = ANDI; my_sequence_item_obj.imm_i = 12'h7ff; end
                    endcase
                end

                2: begin
                    op = i_shift_count++;
                    my_sequence_item_obj.instr_type = I_TYPE_SHIFT;
                    case (op % 3)
                        0: my_sequence_item_obj.i_shift_instr = SLLI;
                        1: my_sequence_item_obj.i_shift_instr = SRLI;
                        default: my_sequence_item_obj.i_shift_instr = SRAI;
                    endcase
                    my_sequence_item_obj.shamt = op % 6;
                end

                3: begin
                    op = load_count++;
                    my_sequence_item_obj.instr_type = I_TYPE_LOAD;
                    my_sequence_item_obj.rs1 = 5'd15;
                    data_offset = (op % 31) * 4;
                    case (op % 5)
                        0: begin my_sequence_item_obj.i_load_instr = LB; my_sequence_item_obj.imm_i = data_offset[11:0]; end
                        1: begin my_sequence_item_obj.i_load_instr = LH; my_sequence_item_obj.imm_i = data_offset[11:0]; end
                        2: begin my_sequence_item_obj.i_load_instr = LW; my_sequence_item_obj.imm_i = data_offset[11:0]; end
                        3: begin my_sequence_item_obj.i_load_instr = LBU; my_sequence_item_obj.imm_i = data_offset + 1; end
                        default: begin my_sequence_item_obj.i_load_instr = LHU; my_sequence_item_obj.imm_i = data_offset[11:0]; end
                    endcase
                end

                4: begin
                    op = store_count++;
                    my_sequence_item_obj.instr_type = S_TYPE;
                    my_sequence_item_obj.rs1 = 5'd15;
                    my_sequence_item_obj.rs2 = (op % 15) + 1;
                    data_offset = (op % 31) * 4;
                    case (op % 3)
                        0: begin my_sequence_item_obj.s_instr = SB; my_sequence_item_obj.imm_s = data_offset + (op % 4); end
                        1: begin my_sequence_item_obj.s_instr = SH; my_sequence_item_obj.imm_s = data_offset[11:0]; end
                        default: begin my_sequence_item_obj.s_instr = SW; my_sequence_item_obj.imm_s = data_offset[11:0]; end
                    endcase
                end

                5: begin
                    op = branch_count++;
                    my_sequence_item_obj.instr_type = B_TYPE;
                    my_sequence_item_obj.imm_b = 13'd4;
                    case (op % 6)
                        0: my_sequence_item_obj.b_instr = BEQ;
                        1: my_sequence_item_obj.b_instr = BNE;
                        2: my_sequence_item_obj.b_instr = BLT;
                        3: my_sequence_item_obj.b_instr = BGE;
                        4: my_sequence_item_obj.b_instr = BLTU;
                        default: my_sequence_item_obj.b_instr = BGEU;
                    endcase
                end

                6: begin
                    op = u_count++;
                    my_sequence_item_obj.instr_type = U_TYPE;
                    my_sequence_item_obj.u_instr = ((op % 2) == 0) ? LUI : AUIPC;
                    case (op % 4)
                        0: my_sequence_item_obj.imm_u = 20'h00000;
                        1: my_sequence_item_obj.imm_u = 20'h0007f;
                        2: my_sequence_item_obj.imm_u = 20'h12345;
                        default: my_sequence_item_obj.imm_u = 20'hf0000;
                    endcase
                end

                7: begin
                    op = j_count++;
                    my_sequence_item_obj.instr_type = J_TYPE;
                    my_sequence_item_obj.j_instr = JAL;
                    my_sequence_item_obj.imm_j = 21'd4;
                end

                default: begin
                    op = jalr_count++;
                    my_sequence_item_obj.instr_type = I_TYPE_JUMP;
                    my_sequence_item_obj.i_jump_instr = JALR;
                    my_sequence_item_obj.rs1 = 5'd0;
                    my_sequence_item_obj.imm_i = ((i + 1) * 4);
                end

            endcase

            finish_item(my_sequence_item_obj);

        end

    endtask

endclass
