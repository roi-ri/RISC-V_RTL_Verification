/*
* =============================================================================
*
* - File        : s_type.sv
* - Autor       : Rodrigo Sánchez Araya (C37259)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción :Secuencia UVM dirigida para generar únicamente instrucciones
*                 tipo S del conjunto RISC-V. Esta secuencia deriva de la
*                 secuencia base y restringe la randomización para producir
*                 solamente instrucciones de almacenamiento SB, SH y SW.
*                 Además, se limitan los registros base, los registros fuente
*                 y los inmediatos para mantener accesos de memoria controlados
*                 y alineados según el tipo de almacenamiento.
*
* =============================================================================
*/

import instr_pkg::*;

// Se define la secuencia para instrucciones tipo S:
class s_type_sequence extends base_sequence;

    // Se registra la secuencia en la fábrica:
    `uvm_object_utils(s_type_sequence)

    // Se crea el constructor de la secuencia:
    function new(string name = "s_type_sequence");

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

        // Se generan los elementos de secuencia tipo S:
        for (int i = 0; i < cantidad_instrucciones; i++) begin

            // Se crea el objeto de secuencia:
            my_sequence_item_obj =
                my_sequence_item::type_id::create(
                    "s_type_item"
                );

            // Se desactiva el constraint general de instrucciones soportadas,
            // ya que S_TYPE puede estar comentado en el sequencer base:
            my_sequence_item_obj.instr_type_soportadas_c.constraint_mode(0);

            // Se inicia el envío del item hacia el sequencer:
            start_item(my_sequence_item_obj);

            // Se restringe la randomización para generar únicamente instrucciones tipo S:
            assert(
                my_sequence_item_obj.randomize() with {

                    instr_type == S_TYPE;

                    s_instr inside {
                        SB,
                        SH,
                        SW
                    };

                    rs1 == 5'd15;

                    rs2 inside {[5'd0:5'd15]};

                    imm_s inside {[12'd0:12'd120]};

                    if (
                        s_instr == SH
                    ) {

                        imm_s[0] == 1'b0;

                    }

                    if (
                        s_instr == SW
                    ) {

                        imm_s[1:0] == 2'b00;

                    }

                }
            )
            else begin

                `uvm_fatal(
                    "S_TYPE_SEQUENCE",
                    "Falló la randomización de una instrucción tipo S"
                )

            end

            case (i % 3)
                0: my_sequence_item_obj.s_instr = SB;
                1: my_sequence_item_obj.s_instr = SH;
                default: my_sequence_item_obj.s_instr = SW;
            endcase

            if (
                (i == 5) ||
                (i == 6) ||
                (i == 7)
            ) begin

                my_sequence_item_obj.rs2 = 5'd0;

            end

            else begin

                my_sequence_item_obj.rs2 = 5'd1 + ((i + (i / 16)) % 15);

            end

            case (my_sequence_item_obj.s_instr)
                SB: my_sequence_item_obj.imm_s = (i % 121);
                SH: my_sequence_item_obj.imm_s = (i % 61) * 2;
                default: my_sequence_item_obj.imm_s = (i % 31) * 4;
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
