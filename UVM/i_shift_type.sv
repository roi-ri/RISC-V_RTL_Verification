/*
* =============================================================================
*
* - File        : i_shift_type.sv
* - Autor       : Rodrigo Sánchez Araya (C37259)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción :Secuencia UVM dirigida para generar únicamente instrucciones
*                 tipo I shift del conjunto RISC-V. Esta secuencia deriva de la
*                 secuencia base y restringe la randomización para producir
*                 solamente instrucciones SLLI, SRLI y SRAI. Cada instrucción
*                 generada se asocia con una dirección incremental para que
*                 posteriormente el driver la codifique y la escriba en la
*                 memoria interna del DUT.
*
* =============================================================================
*/

import instr_pkg::*;

// Se define la secuencia para instrucciones tipo I shift:
class i_shift_type_sequence extends base_sequence;

    // Se registra la secuencia en la fábrica:
    `uvm_object_utils(i_shift_type_sequence)

    // Se crea el constructor de la secuencia:
    function new(string name = "i_shift_type_sequence");

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

        // Se generan los elementos de secuencia tipo I shift:
        for (int i = 0; i < cantidad_instrucciones; i++) begin

            // Se crea el objeto de secuencia:
            my_sequence_item_obj =
                my_sequence_item::type_id::create(
                    "i_shift_type_item"
                );

            // Se inicia el envío del item hacia el sequencer:
            start_item(my_sequence_item_obj);

            // Se restringe la randomización para generar únicamente instrucciones tipo I shift:
            assert(
                my_sequence_item_obj.randomize() with {

                    instr_type == I_TYPE_SHIFT;

                    i_shift_instr inside {
                        SLLI,
                        SRLI,
                        SRAI
                    };

                }
            )
            else begin

                `uvm_fatal(
                    "I_SHIFT_TYPE_SEQUENCE",
                    "Falló la randomización de una instrucción tipo I shift"
                )

            end

            case (i % 3)
                0: my_sequence_item_obj.i_shift_instr = SLLI;
                1: my_sequence_item_obj.i_shift_instr = SRLI;
                default: my_sequence_item_obj.i_shift_instr = SRAI;
            endcase

            if (i >= (cantidad_instrucciones - 72)) begin
                my_sequence_item_obj.i_shift_instr = SRAI;
            end

            case ((i / 3) % 8)
                0: my_sequence_item_obj.shamt = 5'd0;
                1: my_sequence_item_obj.shamt = 5'd1;
                2: my_sequence_item_obj.shamt = 5'd3;
                3: my_sequence_item_obj.shamt = 5'd7;
                4: my_sequence_item_obj.shamt = 5'd11;
                5: my_sequence_item_obj.shamt = 5'd16;
                6: my_sequence_item_obj.shamt = 5'd24;
                default: my_sequence_item_obj.shamt = 5'd31;
            endcase

            if (i >= (cantidad_instrucciones - 72)) begin
                case ((i - (cantidad_instrucciones - 72)) % 6)
                    0: my_sequence_item_obj.shamt = 5'd1;
                    1: my_sequence_item_obj.shamt = 5'd3;
                    2: my_sequence_item_obj.shamt = 5'd7;
                    3: my_sequence_item_obj.shamt = 5'd11;
                    4: my_sequence_item_obj.shamt = 5'd24;
                    default: my_sequence_item_obj.shamt = 5'd31;
                endcase
            end

            if (i < 36) begin

                case ((i / 3) % 3)
                    0: my_sequence_item_obj.rd = 5'd0;
                    1: my_sequence_item_obj.rd = 5'd1 + (i % 7);
                    default: my_sequence_item_obj.rd = 5'd11 + (i % 5);
                endcase

                case ((i / 9) % 3)
                    0: my_sequence_item_obj.rs1 = 5'd0;
                    1: my_sequence_item_obj.rs1 = 5'd1 + (i % 7);
                    default: my_sequence_item_obj.rs1 = 5'd8 + (i % 8);
                endcase

            end

            else begin

                case ((i / 6) % 4)
                    0: my_sequence_item_obj.rd = 5'd1 + (i % 7);
                    1: my_sequence_item_obj.rd = 5'd11 + (i % 5);
                    2: my_sequence_item_obj.rd = 5'd2 + (i % 6);
                    default: my_sequence_item_obj.rd = 5'd12 + (i % 4);
                endcase

                case ((i / 9) % 5)
                    0: my_sequence_item_obj.rs1 = 5'd8;
                    1: my_sequence_item_obj.rs1 = 5'd9;
                    2: my_sequence_item_obj.rs1 = 5'd10;
                    3: my_sequence_item_obj.rs1 = 5'd13;
                    default: my_sequence_item_obj.rs1 = 5'd14;
                endcase

            end

            // Se asigna la dirección incremental donde el driver escribirá la instrucción:
            if (i >= (cantidad_instrucciones - 72)) begin

                my_sequence_item_obj.rd = 5'd11 + ((i - (cantidad_instrucciones - 72)) % 5);

                case ((i - (cantidad_instrucciones - 72)) % 3)
                    0: my_sequence_item_obj.rs1 = 5'd9;
                    1: my_sequence_item_obj.rs1 = 5'd10;
                    default: my_sequence_item_obj.rs1 = 5'd14;
                endcase

            end

            else begin

                if (my_sequence_item_obj.rd == 5'd8) begin
                    my_sequence_item_obj.rd = 5'd11;
                end

                else if (my_sequence_item_obj.rd == 5'd9) begin
                    my_sequence_item_obj.rd = 5'd11;
                end

                else if (my_sequence_item_obj.rd == 5'd10) begin
                    my_sequence_item_obj.rd = 5'd12;
                end

                else if (my_sequence_item_obj.rd == 5'd13) begin
                    my_sequence_item_obj.rd = 5'd15;
                end

                else if (my_sequence_item_obj.rd == 5'd14) begin
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
