/*
* =============================================================================
*
* - File        : u_type.sv
* - Autor       : Rodrigo Sánchez Araya (C37259)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción :Secuencia UVM dirigida para generar únicamente instrucciones
*                 tipo U del conjunto RISC-V. Esta secuencia deriva de la
*                 secuencia base y restringe la randomización para producir
*                 instrucciones LUI y AUIPC. Cada instrucción generada se
*                 asocia con una dirección incremental para que posteriormente
*                 el driver la codifique y la escriba en la memoria interna
*                 del DUT.
*
* =============================================================================
*/

import instr_pkg::*;

// Se define la secuencia para instrucciones tipo U:
class u_type_sequence extends base_sequence;

    // Se registra la secuencia en la fábrica:
    `uvm_object_utils(u_type_sequence)

    // Se crea el constructor de la secuencia:
    function new(string name = "u_type_sequence");

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

        // Se generan los elementos de secuencia tipo U:
        for (int i = 0; i < cantidad_instrucciones; i++) begin

            // Se crea el objeto de secuencia:
            my_sequence_item_obj =
                my_sequence_item::type_id::create(
                    "u_type_item"
                );

            // Se inicia el envío del item hacia el sequencer:
            start_item(my_sequence_item_obj);

            // Se restringe la randomización para generar únicamente instrucciones tipo U:
            assert(
                my_sequence_item_obj.randomize() with {

                    instr_type == U_TYPE;

                    u_instr inside {LUI, AUIPC};

                    rd inside {[5'd0:5'd15]};

                    imm_u inside {[20'h00000:20'hfffff]};

                }
            )
            else begin

                `uvm_fatal(
                    "U_TYPE_SEQUENCE",
                    "Falló la randomización de una instrucción tipo U"
                )

            end

            my_sequence_item_obj.u_instr =
                ((i % 2) == 0) ? LUI : AUIPC;

            case (i % 30)
                0: my_sequence_item_obj.rd = 5'd0;
                15: my_sequence_item_obj.rd = 5'd0;
                default: begin
                    if ((i % 4) < 2) begin
                        my_sequence_item_obj.rd = 5'd1 + (i % 7);
                    end
                    else begin
                        my_sequence_item_obj.rd = 5'd8 + (i % 8);
                    end
                end
            endcase

            case ((i / 2) % 8)
                0: my_sequence_item_obj.imm_u = 20'h00000;
                1: my_sequence_item_obj.imm_u = 20'h00001;
                2: my_sequence_item_obj.imm_u = 20'h00080;
                3: my_sequence_item_obj.imm_u = 20'h00fff;
                4: my_sequence_item_obj.imm_u = 20'h12000;
                5: my_sequence_item_obj.imm_u = 20'h1200f;
                6: my_sequence_item_obj.imm_u = 20'h80000;
                default: my_sequence_item_obj.imm_u = 20'hf000a;
            endcase

            // Se asigna la dirección incremental donde el driver escribirá la instrucción:
            my_sequence_item_obj.addr = i;
            my_sequence_item_obj.last_item =
                (i == (cantidad_instrucciones - 1));

            // Se finaliza el envío del item hacia el sequencer:
            finish_item(my_sequence_item_obj);

        end

    endtask

endclass
