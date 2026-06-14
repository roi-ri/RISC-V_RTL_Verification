/*
* =========================================================================================
*
* - File        : monitor_instruction.sv (parte del agente activo)
* - Autor       : Luis Diego Ramírez Leitón (C36421)
* - Curso       : IE0621 - Verificación Funcional del Diseño de Circuitos Integrados
*                 Universidad de Costa Rica.
* - Fecha       : 13-06-2026
*
* - Descripción : Este programa se encarga de mostrar las instrucciones enviadas, que
*				  corresponden a las experimentales que alimentan al DUT. De este se envían
*   			  las instrucciones al scoreboard.
*
* =========================================================================================
*/

// Se importa el paquete con las etiquetas de las instrucciones:
import instr_pkg::*;

// Se crea la clase monitor de instrucciones:
class monitor_instruction extends uvm_monitor;

    // Se registra la clase en la fábrica:
    `uvm_component_utils(monitor_instruction)

    // Se declara la instancia de los componentes necesarios:
    virtual ifc_riscv ifc_riscv_obj;

    // Analysis port utilizado para enviar las instrucciones observadas hacia el scoreboard:
    uvm_analysis_port #(my_sequence_item)
        uvm_analysis_port_mon_inst_obj;


    // Se crea el constructor:
    function new(string name = "monitor_instruction", uvm_component parent = null);
        super.new(name, parent);
    endfunction


    // En build phase configuramos asignando a atributos, o creamos instancias:
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Se obtiene la interfaz virtual desde la base de datos de configuración:
        if (!uvm_config_db #(virtual ifc_riscv)::get(this, "", "ifc_riscv_obj", ifc_riscv_obj)) begin
        	`uvm_fatal(get_type_name(), "No se encontró la interfaz virtual" )
        end

        // Se crea el puerto de análisis del monitor de instrucciones:
        uvm_analysis_port_mon_inst_obj = new("uvm_analysis_port_mon_inst_obj", this);
    endfunction


    // Se observan las instrucciones enviadas al DUT:
    virtual task run_phase(uvm_phase phase);

        // Se crea el objeto donde se almacenará cada instrucción observada:
        my_sequence_item sequence_item_obj;

        // Se espera hasta que el driver termine de cargar la memoria:
        wait(ifc_riscv_obj.mem_loaded === 1'b1);

        // Se ejecuta el monitor durante toda la simulación:
        forever begin

            // Se espera al flanco negativo para observar las señales registradas:
            @(negedge ifc_riscv_obj.clk);

            // Se envían instrucciones que correspondan a una ejecución válida del DUT:
            if (ifc_riscv_obj.commit_valid !== 1'b1) begin
                continue;
            end

            // Se crea una transacción nueva para cada instrucción:
            sequence_item_obj = my_sequence_item::type_id::create("sequence_item_inst");

            // Se guarda la instrucción completa de 32 bits:
            sequence_item_obj.instr = ifc_riscv_obj.commit_instr;
            sequence_item_obj.rst = 1'b0;

            // Se muestra la instrucción ejecutada:
          `uvm_info(get_type_name(), $sformatf( "Instrucción ejecutada: PC = 0x%08h, instrucción = 0x%08h", 													ifc_riscv_obj.commit_pc, sequence_item_obj.instr),
                UVM_MEDIUM
            )

            // Se envía la instrucción al scoreboard:
            uvm_analysis_port_mon_inst_obj.write(sequence_item_obj);

        end

    endtask

endclass