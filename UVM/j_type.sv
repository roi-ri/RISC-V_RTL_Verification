/*
* =============================================================================
*
* - File        : j_type.sv
* - Autor       : Rodrigo Sánchez Araya (C37259)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción :Secuencia UVM dirigida para generar únicamente instrucciones
*                 tipo J del conjunto RISC-V. Esta secuencia deriva de la
*                 secuencia base y restringe la randomización para producir
*                 solamente instrucciones JAL. Además, se limita el inmediato
*                 para generar saltos positivos, controlados, alineados y con
*                 suficiente densidad para ejecutar una cantidad alta de casos.
*
* =============================================================================
*/

import instr_pkg::*;

// Se define la secuencia para instrucciones tipo J:
class j_type_sequence extends base_sequence;

    // Se registra la secuencia en la fábrica:
    `uvm_object_utils(j_type_sequence)

    // Se crea el constructor de la secuencia:
    function new(string name = "j_type_sequence");

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

        // Se generan los elementos de secuencia tipo J:
        for (int i = 0; i < cantidad_instrucciones; i++) begin

            // Se crea el objeto de secuencia:
            my_sequence_item_obj =
                my_sequence_item::type_id::create(
                    "j_type_item"
                );

            // Se desactiva el constraint general de instrucciones soportadas,
            // ya que J_TYPE puede estar comentado en el sequencer base:
            my_sequence_item_obj.instr_type_soportadas_c.constraint_mode(0);

            // Se inicia el envío del item hacia el sequencer:
            start_item(my_sequence_item_obj);

            // Se restringe la randomización para generar únicamente instrucciones tipo J:
            assert(
                my_sequence_item_obj.randomize() with {

                    instr_type == J_TYPE;

                    j_instr == JAL;

                    rd inside {[5'd0:5'd15]};

                    imm_j inside {21'd4, 21'd8, 21'd12};

                    imm_j[1:0] == 2'b00;

                }
            )
            else begin

                `uvm_fatal(
                    "J_TYPE_SEQUENCE",
                    "Falló la randomización de una instrucción tipo J"
                )

            end

            case (i % 5)
                0: my_sequence_item_obj.rd = 5'd0;
                1: my_sequence_item_obj.rd = 5'd1;
                2: my_sequence_item_obj.rd = 5'd5;
                3: my_sequence_item_obj.rd = 5'd2 + (i % 3);
                default: my_sequence_item_obj.rd = 5'd6 + (i % 10);
            endcase

            if ((i % 20) == 9) begin
                my_sequence_item_obj.imm_j = 21'd12;
            end
            else if ((i % 10) == 4) begin
                my_sequence_item_obj.imm_j = 21'd8;
            end
            else begin
                my_sequence_item_obj.imm_j = 21'd4;
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
