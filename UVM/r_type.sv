/*
* =============================================================================
*
* - File        : r_type.sv
* - Autor       : Rodrigo Sánchez Araya (C37259)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción :Secuencia UVM dirigida para generar únicamente instrucciones
*                 tipo R del conjunto RISC-V. Esta secuencia deriva de la
*                 secuencia base y restringe la randomización para producir
*                 solamente instrucciones ADD, SUB, SLL, SLT, SLTU, XOR, SRL,
*                 SRA, OR y AND. Cada instrucción generada se asocia con una
*                 dirección incremental para que posteriormente el driver la
*                 codifique y la escriba en la memoria interna del DUT.
*
* =============================================================================
*/

import instr_pkg::*;

// Se define la secuencia para instrucciones tipo R:
class r_type_sequence extends base_sequence;

    // Se registra la secuencia en la fábrica:
    `uvm_object_utils(r_type_sequence)

    // Se crea el constructor de la secuencia:
    function new(string name = "r_type_sequence");

        super.new(name);

    endfunction

    // Se define el cuerpo principal de la secuencia:
    virtual task body();

        // Se declara el item que será enviado al driver:
        my_sequence_item my_sequence_item_obj;
        int unsigned op_idx;
        int unsigned sample_idx;
        int unsigned source_group_rs1;
        int unsigned source_group_rs2;

        // Si no se indicó una cantidad desde el test, se usa el tamaño de la memoria:
        if (cantidad_instrucciones == 0) begin

            cantidad_instrucciones =
                $size($root.tb_top.dut.MEM);

        end

        // Se generan los elementos de secuencia tipo R:
        for (int i = 0; i < cantidad_instrucciones; i++) begin

            // Se crea el objeto de secuencia:
            my_sequence_item_obj =
                my_sequence_item::type_id::create(
                    "r_type_item"
                );

            // Se inicia el envío del item hacia el sequencer:
            start_item(my_sequence_item_obj);

            // Se restringe la randomización para generar únicamente instrucciones tipo R:
            assert(
                my_sequence_item_obj.randomize() with {

                    instr_type == R_TYPE;

                    r_instr inside {
                        ADD,
                        SUB,
                        SLL,
                        SLT,
                        SLTU,
                        XOR,
                        SRL,
                        SRA,
                        OR,
                        AND
                    };

                }
            )
            else begin

                `uvm_fatal(
                    "R_TYPE_SEQUENCE",
                    "Falló la randomización de una instrucción tipo R"
                )

            end

            op_idx = i % 10;
            sample_idx = i / 10;

            case (op_idx)
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

            if (i >= (cantidad_instrucciones - 50)) begin
                my_sequence_item_obj.r_instr = SRA;
            end

            if (sample_idx < 9) begin

                my_sequence_item_obj.rd = 5'd0;
                source_group_rs1 = sample_idx / 3;
                source_group_rs2 = sample_idx % 3;

                case (source_group_rs1)
                    0: my_sequence_item_obj.rs1 = 5'd0;
                    1: my_sequence_item_obj.rs1 = 5'd1 + ((sample_idx + op_idx) % 7);
                    default: my_sequence_item_obj.rs1 = 5'd8 + ((sample_idx + op_idx) % 8);
                endcase

                case (source_group_rs2)
                    0: my_sequence_item_obj.rs2 = 5'd0;
                    1: my_sequence_item_obj.rs2 = 5'd1 + ((sample_idx + (2 * op_idx)) % 7);
                    default: my_sequence_item_obj.rs2 = 5'd8 + ((sample_idx + (2 * op_idx)) % 8);
                endcase

                if ((my_sequence_item_obj.rs1 == 5'd0) && (my_sequence_item_obj.rs2 == 5'd0)) begin
                    my_sequence_item_obj.rs1 = 5'd1 + (op_idx % 7);
                end

            end

            else if (sample_idx < 19) begin

                my_sequence_item_obj.rd = 5'd8 + ((sample_idx + op_idx) % 8);
                my_sequence_item_obj.rs1 = 5'd0;

                if (
                    (my_sequence_item_obj.r_instr == SLL) ||
                    (my_sequence_item_obj.r_instr == SRL) ||
                    (my_sequence_item_obj.r_instr == SRA)
                ) begin

                    case ((sample_idx + op_idx) % 4)
                        0: my_sequence_item_obj.rs2 = 5'd2;
                        1: my_sequence_item_obj.rs2 = 5'd5;
                        2: my_sequence_item_obj.rs2 = 5'd6;
                        default: my_sequence_item_obj.rs2 = 5'd7;
                    endcase

                end

                else begin

                    case ((sample_idx + (2 * op_idx)) % 5)
                        0: my_sequence_item_obj.rs2 = 5'd1;
                        1: my_sequence_item_obj.rs2 = 5'd2;
                        2: my_sequence_item_obj.rs2 = 5'd4;
                        3: my_sequence_item_obj.rs2 = 5'd5;
                        default: my_sequence_item_obj.rs2 = 5'd7;
                    endcase

                end

            end

            else if (sample_idx < 62) begin

                my_sequence_item_obj.rd = 5'd8 + ((sample_idx + op_idx) % 8);

                case ((sample_idx + op_idx) % 4)
                    0: my_sequence_item_obj.rs1 = 5'd1;
                    1: my_sequence_item_obj.rs1 = 5'd3;
                    2: my_sequence_item_obj.rs1 = 5'd6;
                    default: my_sequence_item_obj.rs1 = 5'd7;
                endcase

                if (
                    (my_sequence_item_obj.r_instr == SLL) ||
                    (my_sequence_item_obj.r_instr == SRL) ||
                    (my_sequence_item_obj.r_instr == SRA)
                ) begin

                    case ((sample_idx + op_idx) % 4)
                        0: my_sequence_item_obj.rs2 = 5'd0;
                        1: my_sequence_item_obj.rs2 = 5'd2;
                        2: my_sequence_item_obj.rs2 = 5'd5;
                        default: my_sequence_item_obj.rs2 = 5'd6;
                    endcase

                end

                else begin

                    case ((sample_idx + (2 * op_idx)) % 5)
                        0: my_sequence_item_obj.rs2 = 5'd0;
                        1: my_sequence_item_obj.rs2 = 5'd2;
                        2: my_sequence_item_obj.rs2 = 5'd4;
                        3: my_sequence_item_obj.rs2 = 5'd5;
                        default: my_sequence_item_obj.rs2 = 5'd7;
                    endcase

                end

            end

            else begin

                my_sequence_item_obj.rd = 5'd1 + ((sample_idx + op_idx) % 7);

                case ((sample_idx + op_idx) % 4)
                    0: my_sequence_item_obj.rs1 = 5'd8;
                    1: my_sequence_item_obj.rs1 = 5'd11;
                    2: my_sequence_item_obj.rs1 = 5'd12;
                    default: my_sequence_item_obj.rs1 = 5'd13;
                endcase

                if ((sample_idx >= 76) && (my_sequence_item_obj.r_instr == SRA)) begin

                    my_sequence_item_obj.rd = 5'd15;
                    my_sequence_item_obj.rs1 = 5'd9;
                    my_sequence_item_obj.rs2 = 5'd2 + (sample_idx % 3);

                end

                else if (
                    (my_sequence_item_obj.r_instr == SLL) ||
                    (my_sequence_item_obj.r_instr == SRL) ||
                    (my_sequence_item_obj.r_instr == SRA)
                ) begin

                    my_sequence_item_obj.rs2 = 5'd0;

                end

                else begin

                    case ((sample_idx + (2 * op_idx)) % 4)
                        0: my_sequence_item_obj.rs2 = 5'd8;
                        1: my_sequence_item_obj.rs2 = 5'd11;
                        2: my_sequence_item_obj.rs2 = 5'd12;
                        default: my_sequence_item_obj.rs2 = 5'd13;
                    endcase

                end

            end

            // Se asigna la dirección incremental donde el driver escribirá la instrucción:
            if (i >= (cantidad_instrucciones - 50)) begin

                my_sequence_item_obj.rd = 5'd10 + ((i - (cantidad_instrucciones - 50)) % 5);
                my_sequence_item_obj.rs1 = 5'd9;
                my_sequence_item_obj.rs2 = 5'd2;

            end

            else begin

                if (my_sequence_item_obj.rd == 5'd2) begin
                    my_sequence_item_obj.rd = 5'd3;
                end

                else if (my_sequence_item_obj.rd == 5'd9) begin
                    my_sequence_item_obj.rd = 5'd10;
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
