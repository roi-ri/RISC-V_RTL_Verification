/*
* ======================================================================================
*
* - File        : monitor.sv (parte del agente pasivo)
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

    // Se registra la clase en la fábrica:
    `uvm_component_utils(monitor)

    // Se declara la instancia de los componentes necesarios:
    virtual ifc_riscv ifc_riscv_obj;

    // Analysis port utilizado para enviar las señales experimentales hacia el scoreboard:
  	uvm_analysis_port #(output_sequence_item) uvm_analysis_port_mon_out_obj;

    // Se crea el constructor:
    function new(string name = "monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // En build phase configuramos asignando a atributos, o creamos instancias:
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Se obtiene la interfaz virtual desde la base de datos de configuración:
      	if (!uvm_config_db #(virtual ifc_riscv)::get(this, "", "ifc_riscv_obj", ifc_riscv_obj)) begin
            `uvm_fatal(get_type_name(),"No se encontró la interfaz virtual")
        end

        // Se crea el puerto de análisis del monitor de salida:
        uvm_analysis_port_mon_out_obj = new("uvm_analysis_port_mon_out_obj", this);
    endfunction


    // Se observan las señales experimentales producidas por el DUT:
    virtual task run_phase(uvm_phase phase);

        // Se crea el objeto donde se almacenarán las señales observadas:
        output_sequence_item output_item_obj;

        // Se espera hasta que el driver termine de cargar la memoria:
        wait(ifc_riscv_obj.mem_loaded === 1'b1);

        // Se ejecuta el monitor durante toda la simulación:
        forever begin

            // Se espera al flanco negativo posterior a la actualización del banco de registros:
            @(negedge ifc_riscv_obj.clk);

            // Solo se capturan resultados asociados con una instrucción válida:
            if (ifc_riscv_obj.commit_valid !== 1'b1) begin
                continue;
            end

            #1step;

            // Se crea una transacción nueva para cada salida observada:
          	output_item_obj = output_sequence_item::type_id::create("output_item_obj");

            // Se guarda el estado general:
            output_item_obj.output_data.rst = ifc_riscv_obj.res;
            output_item_obj.output_data.valid = 1'b1;

            // Se guarda la instrucción y el PC asociados con el resultado:
            output_item_obj.output_data.instr = ifc_riscv_obj.commit_instr;

            output_item_obj.output_data.pc = ifc_riscv_obj.commit_pc;

            output_item_obj.output_data.pc_next = ifc_riscv_obj.nxpc2;

            // Se guarda la información relacionada con la escritura en el banco de registros:
            output_item_obj.output_data.writes_rd = ifc_riscv_obj.commit_writes_rd;
            output_item_obj.output_data.rd_addr = ifc_riscv_obj.commit_rd;

            // Se obtiene el valor que quedó escrito en el registro destino:
            if ((ifc_riscv_obj.commit_writes_rd === 1'b1) && (ifc_riscv_obj.commit_rd < 5'd16)) begin
              
                output_item_obj.output_data.rd_data = ifc_riscv_obj.regs[ifc_riscv_obj.commit_rd];

            end else begin

                output_item_obj.output_data.rd_data = 32'd0;
            end

            // Se guardan señales adicionales para depuración:
            output_item_obj.output_data.alu_result = ifc_riscv_obj.commit_alu_result;
            output_item_obj.output_data.simm = ifc_riscv_obj.commit_simm;

            // Se guarda una copia completa del banco de registros:
            for (int i = 0; i < 16; i = i + 1) begin
                output_item_obj.output_data.regs[i] = ifc_riscv_obj.regs[i];
            end

          	// Se muestra un resumen de la salida experimental (se debe quitar, es sólo para revisar):
            `uvm_info(
                get_type_name(),
                $sformatf("Salida observada: instr=%08h PC=%08h rd_write=%0b rd=x%0d data=%08h PC_next=%08h",
                    output_item_obj.output_data.instr,
                    output_item_obj.output_data.pc,
                    output_item_obj.output_data.writes_rd,
                    output_item_obj.output_data.rd_addr,
                    output_item_obj.output_data.rd_data,
                    output_item_obj.output_data.pc_next
                ),
                UVM_MEDIUM
            )

            // Se envía la transacción al scoreboard:
          	uvm_analysis_port_mon_out_obj.write(output_item_obj);

        end

    endtask

endclass