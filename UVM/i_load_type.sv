/*
* =============================================================================
*
* - File        : i_load_type.sv
* - Autor       : Rodrigo Sánchez Araya (C37259)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción : Secuencia UVM dirigida para generar únicamente instrucciones
*                 tipo I de carga del conjunto RISC-V. Esta secuencia deriva de
*                 la secuencia base y restringe la randomización para producir
*                 solamente instrucciones LB, LH, LW, LBU y LHU. Además, utiliza
*                 un registro base fijo para acceder a una zona de datos
*                 inicializada, evitando que las instrucciones LOAD lean desde
*                 la zona donde se carga el programa.
*
* =============================================================================
*/

import instr_pkg::*;

// Se define la secuencia para instrucciones tipo I load:
class i_load_type_sequence extends base_sequence;

    // Se registra la secuencia en la fábrica:
    `uvm_object_utils(i_load_type_sequence)

    // Se crea el constructor de la secuencia:
    function new(string name = "i_load_type_sequence");

        super.new(name);

    endfunction

    // Se define el cuerpo principal de la secuencia:
    virtual task body();

        // Se declara el item que será enviado al driver:
        my_sequence_item my_sequence_item_obj;

        // Para instrucciones LOAD no conviene llenar toda la memoria con
        // instrucciones, porque se necesita reservar una zona para datos.
        // Por eso, si no se indicó cantidad o si viene una cantidad demasíado
        // grande desde el test, se limita a 800 instrucciones.
        if (
            (cantidad_instrucciones == 0) ||
            (cantidad_instrucciones > 800)
        ) begin

            cantidad_instrucciones = 800;

        end

        // Se generan los elementos de secuencia tipo I load:
        for (int i = 0; i < cantidad_instrucciones; i++) begin

            // Se crea el objeto de secuencia:
            my_sequence_item_obj =
                my_sequence_item::type_id::create(
                    "i_load_type_item"
                );

            // Se inicia el envío del item hacia el sequencer:
            start_item(my_sequence_item_obj);

            // Se restringe la randomización para generar únicamente instrucciones tipo I load:
            assert(
                my_sequence_item_obj.randomize() with {

                    // Se fuerza el tipo general de instrucción:
                    instr_type == I_TYPE_LOAD;

                    // Se permite únicamente el subconjunto de instrucciones LOAD:
                    i_load_instr inside {
                        LB,
                        LH,
                        LW,
                        LBU,
                        LHU
                    };

                    // Se usa x15 como registro base.
                    // En el test se debe inicializar x15 con la dirección base
                    // de la zona de datos, por ejemplo 32'h00000800.
                    rs1 == 5'd15;

                    // Se evita escribir en x15 para no modificar el registro
                    // base de los accesos de memoria.
                    rd inside {[5'd1:5'd14]};

                    // Se limita el inmediato para leer dentro de una zona pequeña
                    // de datos inicializada por el test.
                    imm_i inside {[12'd0:12'd120]};

                    // Las instrucciones LH y LHU deben estar alineadas a 2 bytes:
                    if (
                        (i_load_instr == LH) ||
                        (i_load_instr == LHU)
                    ) {

                        imm_i[0] == 1'b0;

                    }

                    // La instrucción LW debe estar alineada a 4 bytes:
                    if (i_load_instr == LW) {

                        imm_i[1:0] == 2'b00;

                    }

                }
            )
            else begin

                `uvm_fatal(
                    "I_LOAD_TYPE_SEQUENCE",
                    "Falló la randomización de una instrucción tipo I load"
                )

            end

            case (i % 5)
                0: my_sequence_item_obj.i_load_instr = LB;
                1: my_sequence_item_obj.i_load_instr = LH;
                2: my_sequence_item_obj.i_load_instr = LW;
                3: my_sequence_item_obj.i_load_instr = LBU;
                default: my_sequence_item_obj.i_load_instr = LHU;
            endcase

            if ((i % 16) == 0) begin
                my_sequence_item_obj.rd = 5'd0;
            end
            else if ((i % 2) == 0) begin
                my_sequence_item_obj.rd = 5'd1 + (i % 7);
            end
            else begin
                my_sequence_item_obj.rd = 5'd8 + (i % 7);
            end

            case (my_sequence_item_obj.i_load_instr)
                LB, LBU: my_sequence_item_obj.imm_i = (i % 31);
                LH, LHU: my_sequence_item_obj.imm_i = (i % 16) * 2;
                default: my_sequence_item_obj.imm_i = (i % 8) * 4;
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
