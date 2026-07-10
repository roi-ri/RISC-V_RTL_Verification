/*
* =============================================================================
*
* - File        : i_jump_type.sv
* - Autor       : Rodrigo Sánchez Araya (C37259)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción :Secuencia UVM dirigida para generar únicamente instrucciones
*                 tipo I jump del conjunto RISC-V. Esta secuencia deriva de la
*                 secuencia base y restringe la randomización para producir
*                 solamente instrucciones JALR. Además, se limita el registro
*                 base y el inmediato para mantener saltos controlados dentro
*                 de la zona de memoria utilizada durante la simulación.
*
* =============================================================================
*/

import instr_pkg::*;

// Se define la secuencia para instrucciones tipo I jump:
class i_jump_type_sequence extends base_sequence;

    // Se registra la secuencia en la fábrica:
    `uvm_object_utils(i_jump_type_sequence)

    // Se crea el constructor de la secuencia:
    function new(string name = "i_jump_type_sequence");

        super.new(name);

    endfunction

    // Se define el cuerpo principal de la secuencia:
    virtual task body();

        // Se declara el item que será enviado al driver:
        my_sequence_item my_sequence_item_obj;

        // Si no se indicó una cantidad suficiente desde el test, se generan 600 instrucciones:
        if (cantidad_instrucciones < 600) begin

            cantidad_instrucciones = 600;

        end

        // Se generan los elementos de secuencia tipo I jump:
        for (int i = 0; i < cantidad_instrucciones; i++) begin

            // Se crea el objeto de secuencia:
            my_sequence_item_obj =
                my_sequence_item::type_id::create(
                    "i_jump_type_item"
                );

            // Se inicia el envío del item hacia el sequencer:
            start_item(my_sequence_item_obj);

            // Se restringe la randomización para generar únicamente instrucciones tipo I jump:
            assert(
                my_sequence_item_obj.randomize() with {

                    instr_type == I_TYPE_JUMP;

                    i_jump_instr == JALR;

                    rd inside {[5'd0:5'd15]};

                    rs1 == 5'd0;

                    imm_i inside {[12'd0:12'd2044]};

                    imm_i[0] == 1'b0;

                }
            )
            else begin

                `uvm_fatal(
                    "I_JUMP_TYPE_SEQUENCE",
                    "Falló la randomización de una instrucción tipo I jump"
                )

            end

            case (i % 5)
                0: my_sequence_item_obj.rd = 5'd0;
                1: my_sequence_item_obj.rd = 5'd1;
                2: my_sequence_item_obj.rd = 5'd5;
                3: my_sequence_item_obj.rd = 5'd2 + (i % 3);
                default: my_sequence_item_obj.rd = 5'd6 + (i % 9);
            endcase

            if (i == (cantidad_instrucciones - 1)) begin

                my_sequence_item_obj.rs1 = 5'd15;
                my_sequence_item_obj.imm_i = (cantidad_instrucciones * 4) - 32'h0000080f;

            end

            else if (((i + 1) * 4) <= 2044) begin

                my_sequence_item_obj.rs1 = 5'd0;
                my_sequence_item_obj.imm_i = ((i + 1) * 4);

            end

            else begin

                my_sequence_item_obj.rs1 = 5'd15;
                my_sequence_item_obj.imm_i = ((i + 1) * 4) - 32'h0000080f;

            end

            // Se asigna la dirección incremental donde el driver escribirá la instrucción:
            my_sequence_item_obj.addr = i;
            my_sequence_item_obj.last_item =
                (i == (cantidad_instrucciones - 1));

            // Se finaliza el envío del item hacia el sequencer:
            finish_item(my_sequence_item_obj);

        end

    endtask

endclass
