/*
* =============================================================================
*
* - File        : b_type.sv
* - Autor       : Rodrigo Sánchez Araya (C37259)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción :Secuencia UVM dirigida para generar únicamente instrucciones
*                 tipo B del conjunto RISC-V. Esta secuencia deriva de la
*                 secuencia base y restringe la randomización para producir
*                 solamente instrucciones de salto condicional BEQ, BNE, BLT,
*                 BGE, BLTU y BGEU. Además, se limitan los registros fuente y
*                 los inmediatos para mantener saltos controlados, positivos y
*                 alineados dentro de la zona de memoria utilizada durante la
*                 simulación.
*
* =============================================================================
*/

import instr_pkg::*;

// Se define la secuencia para instrucciones tipo B:
class b_type_sequence extends base_sequence;

    // Se registra la secuencia en la fábrica:
    `uvm_object_utils(b_type_sequence)

    // Se crea el constructor de la secuencia:
    function new(string name = "b_type_sequence");

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

        // Se generan los elementos de secuencia tipo B:
        for (int i = 0; i < cantidad_instrucciones; i++) begin

            // Se crea el objeto de secuencia:
            my_sequence_item_obj =
                my_sequence_item::type_id::create(
                    "b_type_item"
                );

            // Se desactiva el constraint general de instrucciones soportadas,
            // ya que B_TYPE puede estar comentado en el sequencer base:
            my_sequence_item_obj.instr_type_soportadas_c.constraint_mode(0);

            // Se inicia el envío del item hacia el sequencer:
            start_item(my_sequence_item_obj);

            // Se restringe la randomización para generar únicamente instrucciones tipo B:
            assert(
                my_sequence_item_obj.randomize() with {

                    instr_type == B_TYPE;

                    b_instr inside {
                        BEQ,
                        BNE,
                        BLT,
                        BGE,
                        BLTU,
                        BGEU
                    };

                    rs1 inside {[5'd0:5'd15]};

                    rs2 inside {[5'd0:5'd15]};

                    imm_b inside {[13'd4:13'd8]};

                    imm_b[1:0] == 2'b00;

                }
            )
            else begin

                `uvm_fatal(
                    "B_TYPE_SEQUENCE",
                    "Falló la randomización de una instrucción tipo B"
                )

            end

            case (i % 6)
                0: my_sequence_item_obj.b_instr = BEQ;
                1: my_sequence_item_obj.b_instr = BNE;
                2: my_sequence_item_obj.b_instr = BLT;
                3: my_sequence_item_obj.b_instr = BGE;
                4: my_sequence_item_obj.b_instr = BLTU;
                default: my_sequence_item_obj.b_instr = BGEU;
            endcase

            if (i < 6) begin

                my_sequence_item_obj.rs1 = 5'd0;
                my_sequence_item_obj.rs2 = 5'd8 + (i % 8);

            end

            else if (i < 12) begin

                my_sequence_item_obj.rs1 = 5'd1 + (i % 7);
                my_sequence_item_obj.rs2 = 5'd0;

            end

            else if (((i / 6) % 2) == 0) begin

                my_sequence_item_obj.rs1 = 5'd1 + (i % 7);
                my_sequence_item_obj.rs2 = 5'd8 + ((i + 3) % 8);

            end

            else begin

                my_sequence_item_obj.rs1 = 5'd8 + (i % 8);
                my_sequence_item_obj.rs2 = 5'd1 + ((i + 2) % 7);

            end

            my_sequence_item_obj.imm_b = ((i % 8) == 0) ? 13'd8 : 13'd4;

            // Se asigna la dirección incremental donde el driver escribirá la instrucción:
            my_sequence_item_obj.addr = i;
            my_sequence_item_obj.last_item =
                (i == (cantidad_instrucciones - 1));

            // Se finaliza el envío del item hacia el sequencer:
            finish_item(my_sequence_item_obj);

        end

    endtask

endclass
