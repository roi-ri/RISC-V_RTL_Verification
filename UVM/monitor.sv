/*
* ======================================================================================
*
* - File        : monitor.sv (parte del agente pasívo)
* - Autor       : Luis Diego Ramírez Leitón (C36421)
* - Curso       : IE0621 - Verificación Funcional del Diseño de Circuitos Integrados
*                 Universidad de Costa Rica.
* - Fecha       : 13-06-2026
*
* - Descripción : Este programa se encarga de observar los valores experimentales
*                 producidos por el DUT. Los valores se almacenan en una transacción
*                 y se envían al scoreboard mediante un analysis port.
*
* ======================================================================================
*/

// Se crea la clase monitor de salida:
class monitor extends uvm_monitor;

    localparam int unsigned MAX_CHECKED_INSTR = 800;

    // Se registra la clase en la fábrica:
    `uvm_component_utils(monitor)

    // Se declara la instancia de la interfaz virtual:
    virtual ifc_riscv ifc_riscv_obj;

    // Analysis port utilizado para enviar las señales experimentales hacia el scoreboard:
    uvm_analysis_port #(output_sequence_item)
        uvm_analysis_port_mon_out_obj;

    // Se crea el constructor:
    function new(
        string name = "monitor",
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

        // Se crea el puerto de análisis del monitor de salida:
        uvm_analysis_port_mon_out_obj =
            new(
                "uvm_analysis_port_mon_out_obj",
                this
            );

    endfunction

    // Función para identificar instrucciones LOAD:
    function automatic bit is_load_instruction(
        input logic [31:0] instr
    );

        // Opcode de LOAD en RISC-V:
        return (instr[6:0] == 7'b0000011);

    endfunction

    function automatic bit is_inside_loaded_program(
        input logic [31:0] pc
    );

        if (ifc_riscv_obj.instr_count == 0) begin

            return 1'b1;

        end

        return (pc < (ifc_riscv_obj.instr_count * 4));

    endfunction

    // Tarea para construir y enviar una transacción hacia el scoreboard:
    task automatic send_output_transaction(
        input logic        rst_value,
        input logic [31:0] instr_value,
        input logic [31:0] pc_value,
        input logic [31:0] pc_next_value,
        input logic        writes_rd_value,
        input logic [4:0]  rd_addr_value,
        input logic [31:0] alu_result_value,
        input logic [31:0] simm_value
    );

        // Se crea el objeto donde se almacenarán las señales observadas:
        output_sequence_item output_item_obj;

        // Se crea una transacción nueva para cada salida observada:
        output_item_obj =
            output_sequence_item::type_id::create(
                "output_item_obj"
            );

        // Se guarda el estado general:
        output_item_obj.output_data.rst =
            rst_value;

        output_item_obj.output_data.valid =
            1'b1;

        // Se guarda la instrucción y el PC asociados con el resultado:
        output_item_obj.output_data.instr =
            instr_value;

        output_item_obj.output_data.pc =
            pc_value;

        output_item_obj.output_data.pc_next =
            pc_next_value;

        // Se guarda la información relacionada con la escritura en el banco de registros:
        output_item_obj.output_data.writes_rd =
            writes_rd_value;

        output_item_obj.output_data.rd_addr =
            rd_addr_value;

        // Se obtiene el valor que quedó escrito en el registro destino:
        if (
            (writes_rd_value === 1'b1) &&
            (rd_addr_value < 5'd16)
        ) begin

            output_item_obj.output_data.rd_data =
                ifc_riscv_obj.regs[rd_addr_value];

        end

        else begin

            output_item_obj.output_data.rd_data =
                32'd0;

        end

        // Se guardan señales adicionales para depuración:
        output_item_obj.output_data.alu_result =
            alu_result_value;

        output_item_obj.output_data.simm =
            simm_value;

        // Se guarda una copia completa del banco de registros:
        for (int i = 0; i < 16; i = i + 1) begin

            output_item_obj.output_data.regs[i] =
                ifc_riscv_obj.regs[i];

        end

        // Se envía la transacción al scoreboard:
        uvm_analysis_port_mon_out_obj.write(
            output_item_obj
        );

    endtask

    // Se observan las señales experimentales producidas por el DUT:
    virtual task run_phase(uvm_phase phase);

        // Variables temporales para guardar la instrucción observada:
        logic        saved_rst;
        logic [31:0] saved_instr;
        logic [31:0] saved_pc;
        logic [31:0] saved_pc_next;
        logic        saved_writes_rd;
        logic [4:0]  saved_rd;
        logic [31:0] saved_alu_result;
        logic [31:0] saved_simm;
        int unsigned sent_count;

        // Se espera hasta que el driver termine de cargar la memoria:
        wait(ifc_riscv_obj.mem_loaded === 1'b1);

        sent_count = 0;

        // Se ejecuta el monitor durante toda la simulación:
        forever begin

            // Se espera al flanco negativo posterior a la actualización del banco de registros:
            @(negedge ifc_riscv_obj.clk);

            // No se captura nada durante reset:
            if (ifc_riscv_obj.res === 1'b1) begin

                continue;

            end

            // Solo se capturan resultados asociados con una instrucción válida:
            if (ifc_riscv_obj.commit_valid !== 1'b1) begin

                continue;

            end

            // Se deja estabilizar la información del commit:
            #1step;

            // Se guardan los datos del commit actual.
            // Esto es importante porque para LOAD se esperará un ciclo adicional,
            // pero la instrucción que se enviará al scoreboard debe seguir siendo
            // la instrucción original.
            saved_rst =
                ifc_riscv_obj.res;

            saved_instr =
                ifc_riscv_obj.commit_instr;

            saved_pc =
                ifc_riscv_obj.commit_pc;

            if (!is_inside_loaded_program(saved_pc)) begin

                continue;

            end

            if (sent_count >= MAX_CHECKED_INSTR) begin

                continue;

            end

            saved_pc_next =
                ifc_riscv_obj.nxpc2;

            saved_writes_rd =
                ifc_riscv_obj.commit_writes_rd;

            saved_rd =
                ifc_riscv_obj.commit_rd;

            saved_alu_result =
                ifc_riscv_obj.commit_alu_result;

            saved_simm =
                ifc_riscv_obj.commit_simm;

            // Para instrucciones LOAD se espera un ciclo extra antes de leer
            // el registro destino, porque el dato cargado puede aparecer después.
            if (is_load_instruction(saved_instr)) begin

                @(negedge ifc_riscv_obj.clk);
                #1step;

            end

            // Se envía la transacción.
            // En instrucciones normales se envía inmediatamente.
            // En LOAD se envía después del ciclo extra, pero conservando PC,
            // instrucción, rd y señales de control de la instrucción original.
            send_output_transaction(
                saved_rst,
                saved_instr,
                saved_pc,
                saved_pc_next,
                saved_writes_rd,
                saved_rd,
                saved_alu_result,
                saved_simm
            );

            sent_count++;

        end

    endtask

endclass
