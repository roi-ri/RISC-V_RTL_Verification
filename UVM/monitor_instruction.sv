/*
* =========================================================================================
*
* - File        : monitor_instruction.sv (parte del agente activo)
* - Autor       : Luis Diego Ramírez Leitón (C36421)
* - Curso       : IE0621 - Verificación Funcional del Diseño de Circuitos Integrados
*                 Universidad de Costa Rica.
* - Fecha       : 13-06-2026
*
* - Descripción : Este programa se encarga de observar las instrucciones ejecutadas
*                 por el DUT y enviarlas al scoreboard para alimentar el modelo
*                 teórico de referencia. Se evita duplicar instrucciones LOAD
*                 cuando el commit permanece válido durante más de un ciclo.
*
* =========================================================================================
*/

// Se importa el paquete con las etiquetas de las instrucciones:
import instr_pkg::*;

// Se crea la clase monitor de instrucciones:
class monitor_instruction extends uvm_monitor;

    localparam int unsigned MAX_CHECKED_INSTR = 800;

    // Se registra la clase en la fábrica:
    `uvm_component_utils(monitor_instruction)

    // Se declara la instancia de la interfaz virtual:
    virtual ifc_riscv ifc_riscv_obj;

    // Analysis port utilizado para enviar las instrucciones observadas hacia el scoreboard:
    uvm_analysis_port #(my_sequence_item)
        uvm_analysis_port_mon_inst_obj;

    // Variables para evitar duplicar instrucciones LOAD consecutivas:
    logic [31:0] last_load_pc;
    logic [31:0] last_load_instr;
    bit          last_load_valid;

    // Se crea el constructor:
    function new(
        string name = "monitor_instruction",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction

    // En build phase se obtiene la interfaz y se crea el puerto de análisis:
    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        // Se obtiene la interfaz virtual desde la base de datos de configuración:
        if (!uvm_config_db #(virtual ifc_riscv)::get(
                this,
                "",
                "ifc_riscv_obj",
                ifc_riscv_obj
            )) begin

            `uvm_fatal(
                get_type_name(),
                "No se encontró la interfaz virtual"
            )

        end

        // Se crea el puerto de análisis del monitor de instrucciones:
        uvm_analysis_port_mon_inst_obj =
            new(
                "uvm_analysis_port_mon_inst_obj",
                this
            );

        // Se inicializa el filtro de LOAD repetidos:
        last_load_pc    = 32'd0;
        last_load_instr = 32'd0;
        last_load_valid = 1'b0;

    endfunction

    // Función para identificar instrucciones LOAD:
    function automatic bit is_load_instruction(
        input logic [31:0] instr
    );

        // Opcode de LOAD en RISC-V:
        // LB, LH, LW, LBU y LHU usan opcode 0000011.
        return (instr[6:0] == 7'b0000011);

    endfunction

    // Función para detectar si el LOAD actual ya fue enviado al scoreboard:
    function automatic bit is_repeated_load(
        input logic [31:0] pc,
        input logic [31:0] instr
    );

        if (
            last_load_valid &&
            (last_load_pc    == pc) &&
            (last_load_instr == instr)
        ) begin

            return 1'b1;

        end

        return 1'b0;

    endfunction

    function automatic bit is_inside_loaded_program(
        input logic [31:0] pc
    );

        if (ifc_riscv_obj.instr_count == 0) begin

            return 1'b1;

        end

        return (pc < (ifc_riscv_obj.instr_count * 4));

    endfunction

    // Se observan las instrucciones ejecutadas por el DUT:
    virtual task run_phase(uvm_phase phase);

        // Se crea el objeto donde se almacenará cada instrucción observada:
        my_sequence_item sequence_item_obj;

        // Variables temporales:
        logic [31:0] current_instr;
        logic [31:0] current_pc;
        bit          current_is_load;
        int unsigned sent_count;

        // Se espera hasta que el driver termine de cargar la memoria:
        wait(ifc_riscv_obj.mem_loaded === 1'b1);

        sent_count = 0;

        // Se ejecuta el monitor durante toda la simulación:
        forever begin

            // Se espera al flanco negativo para observar las señales registradas:
            @(negedge ifc_riscv_obj.clk);

            // Durante reset no se envían instrucciones al scoreboard:
            if (ifc_riscv_obj.res === 1'b1) begin

                last_load_valid = 1'b0;
                continue;

            end

            // Se envían instrucciones que correspondan a una ejecución válida del DUT:
            if (ifc_riscv_obj.commit_valid !== 1'b1) begin

                continue;

            end

            // Se deja estabilizar la información del commit:
            #1step;

            // Se captura la instrucción y el PC actuales:
            current_instr =
                ifc_riscv_obj.commit_instr;

            current_pc =
                ifc_riscv_obj.commit_pc;

            if (!is_inside_loaded_program(current_pc)) begin

                continue;

            end

            current_is_load =
                is_load_instruction(current_instr);

            // Si la instrucción actual es un LOAD repetido consecutivamente,
            // no se envía otra vez al scoreboard. Esto evita duplicar referencias
            // teóricas en res_mem.
            if (
                current_is_load &&
                is_repeated_load(
                    current_pc,
                    current_instr
                )
            ) begin

                continue;

            end

            if (sent_count >= MAX_CHECKED_INSTR) begin

                continue;

            end

            // Se crea una transacción nueva para cada instrucción válida:
            sequence_item_obj =
                my_sequence_item::type_id::create(
                    "sequence_item_inst"
                );

            // Se guarda la instrucción completa de 32 bits:
            sequence_item_obj.instr =
                current_instr;

            // Se guarda el estado de reset observado:
            sequence_item_obj.rst =
                ifc_riscv_obj.res;

            // Se envía la instrucción al scoreboard:
            uvm_analysis_port_mon_inst_obj.write(
                sequence_item_obj
            );

            sent_count++;

            // Si fue un LOAD, se guarda para detectar una posible repetición
            // en el siguiente ciclo.
            if (current_is_load) begin

                last_load_pc =
                    current_pc;

                last_load_instr =
                    current_instr;

                last_load_valid =
                    1'b1;

            end

            else begin

                // Si aparece una instrucción que no es LOAD, se libera el filtro.
                // Así, si más adelante vuelve a aparecer el mismo PC/instrucción
                // de forma legítima, no se bloquea.
                last_load_valid =
                    1'b0;

            end

        end

    endtask

endclass
