/*
* =============================================================================
*
* - File        : i_arit_type.sv
* - Autor       : Rodrigo Sánchez Araya (C37259)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción :Secuencia UVM dirigida para generar únicamente instrucciones
*                 tipo I aritméticas del conjunto RISC-V. Esta secuencia deriva
*                 de la secuencia base y restringe la randomización para producir
*                 solamente instrucciones ADDI, SLTI, SLTIU, XORI, ORI y ANDI.
*                 Cada instrucción generada se asocia con una dirección
*                 incremental para que posteriormente el driver la codifique y
*                 la escriba en la memoria interna del DUT.
*
* =============================================================================
*/

import instr_pkg::*;

// Se define la secuencia para instrucciones tipo I aritméticas:
class i_arit_type_sequence extends base_sequence;

    // Se registra la secuencia en la fábrica:
    `uvm_object_utils(i_arit_type_sequence)

    // Se crea el constructor de la secuencia:
    function new(string name = "i_arit_type_sequence");

        super.new(name);

    endfunction

    // Se define el cuerpo principal de la secuencia:
    virtual task body();

        // Se declara el item que será enviado al driver:
        my_sequence_item my_sequence_item_obj;

        // Si no se indicó una cantidad desde el test, se usa el tamaño de la memoria:
        if (cantidad_instrucciones == 0) begin

            cantidad_instrucciones =
                $size($root.tb_top.dut.MEM);

        end

        // Se generan los elementos de secuencia tipo I aritméticas:
        for (int i = 0; i < cantidad_instrucciones; i++) begin

            // Se crea el objeto de secuencia:
            my_sequence_item_obj =
                my_sequence_item::type_id::create(
                    "i_arit_type_item"
                );

            // Se inicia el envío del item hacia el sequencer:
            start_item(my_sequence_item_obj);

            // Se restringe la randomización para generar únicamente instrucciones tipo I aritméticas:
            assert(
                my_sequence_item_obj.randomize() with {

                    instr_type == I_TYPE_ARITHMETIC;

                    i_arith_instr inside {
                        ADDI,
                        SLTI,
                        SLTIU,
                        XORI,
                        ORI,
                        ANDI
                    };

                }
            )
            else begin

                `uvm_fatal(
                    "I_ARIT_TYPE_SEQUENCE",
                    "Falló la randomización de una instrucción tipo I aritmética"
                )

            end

            case (i % 6)
                0: my_sequence_item_obj.i_arith_instr = ADDI;
                1: my_sequence_item_obj.i_arith_instr = SLTI;
                2: my_sequence_item_obj.i_arith_instr = SLTIU;
                3: my_sequence_item_obj.i_arith_instr = XORI;
                4: my_sequence_item_obj.i_arith_instr = ORI;
                default: my_sequence_item_obj.i_arith_instr = ANDI;
            endcase

            case ((i / 6) % 3)
                0: my_sequence_item_obj.imm_i = 12'h000;
                1: my_sequence_item_obj.imm_i = 12'h07f;
                default: my_sequence_item_obj.imm_i = 12'hf80;
            endcase

            case ((i / 18) % 3)
                0: my_sequence_item_obj.rd = 5'd0;
                1: my_sequence_item_obj.rd = 5'd1 + (i % 7);
                default: my_sequence_item_obj.rd = 5'd8 + (i % 8);
            endcase

            case ((i / 54) % 3)
                0: my_sequence_item_obj.rs1 = 5'd0;
                1: my_sequence_item_obj.rs1 = 5'd1 + (i % 7);
                default: my_sequence_item_obj.rs1 = 5'd8 + (i % 8);
            endcase

            if ((my_sequence_item_obj.i_arith_instr == SLTI || my_sequence_item_obj.i_arith_instr == SLTIU) && my_sequence_item_obj.rs1 == 5'd0 && i >= 72) begin
                my_sequence_item_obj.rs1 = (i[1]) ? 5'd10 : 5'd9;
            end

            // Se asigna la dirección incremental donde el driver escribirá la instrucción:
            if (i >= (cantidad_instrucciones - 72)) begin

                case ((i - (cantidad_instrucciones - 72)) % 6)
                    0: my_sequence_item_obj.i_arith_instr = ADDI;
                    1: my_sequence_item_obj.i_arith_instr = SLTI;
                    2: my_sequence_item_obj.i_arith_instr = SLTIU;
                    3: my_sequence_item_obj.i_arith_instr = XORI;
                    4: my_sequence_item_obj.i_arith_instr = ORI;
                    default: my_sequence_item_obj.i_arith_instr = ANDI;
                endcase

                case (((i - (cantidad_instrucciones - 72)) / 6) % 6)
                    0: my_sequence_item_obj.imm_i = 12'h000;
                    1: my_sequence_item_obj.imm_i = 12'h001;
                    2: my_sequence_item_obj.imm_i = 12'h07f;
                    3: my_sequence_item_obj.imm_i = 12'h7ff;
                    4: my_sequence_item_obj.imm_i = 12'hfff;
                    default: my_sequence_item_obj.imm_i = 12'h800;
                endcase

                case (((i - (cantidad_instrucciones - 72)) / 18) % 4)
                    0: my_sequence_item_obj.rs1 = 5'd9;
                    1: my_sequence_item_obj.rs1 = 5'd10;
                    2: my_sequence_item_obj.rs1 = 5'd9;
                    default: my_sequence_item_obj.rs1 = 5'd10;
                endcase

                my_sequence_item_obj.rd = 5'd11 + ((i - (cantidad_instrucciones - 72)) % 5);

            end

            else begin

                if (my_sequence_item_obj.rd == 5'd9) begin
                    my_sequence_item_obj.rd = 5'd11;
                end

                else if (my_sequence_item_obj.rd == 5'd10) begin
                    my_sequence_item_obj.rd = 5'd12;
                end

            end

            my_sequence_item_obj.addr = i;
            my_sequence_item_obj.last_item =
                (i == (cantidad_instrucciones - 1));

            // Se finaliza el envío del item hacia el sequencer:
            finish_item(my_sequence_item_obj);

        end

    endtask

endclass
