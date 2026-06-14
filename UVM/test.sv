class base_test extends uvm_test;

    // Se registra la clase en la fábrica:
    `uvm_component_utils(base_test)


    // Se declaran las instancias de los componentes necesarios:
    env env_obj;
    virtual ifc_riscv ifc_riscv_obj;

    // Cantidad de instrucciones que serán generadas por la secuencia:
    int unsigned cantidad_instrucciones;

    //  Se crea el constructor:
    function new(string name = "base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // En build phase se crean las instancias de los componentes:
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Se crea el ambiente mediante la fábrica:
        env_obj = env::type_id::create("env_obj", this);

        // Se obtiene la interfaz virtual desde la base de datos de configuración:
      	if (!uvm_config_db #(virtual ifc_riscv)::get(this, "", "ifc_riscv_obj", ifc_riscv_obj)) begin
          `uvm_fatal(get_type_name(), "No se encontró la interfaz virtual")
        end
    endfunction

    // Se cargan valores iniciales en los registros del DUT y del scoreboard:
  	task automatic load_initial_registers();
    
        logic [31:0] value;

        $display("");
        $display("=====================================================");
        $display("Cargando registros iniciales del DUT y scoreboard");
        $display("=====================================================");


        // Como es RV32E, entonces utiliza x0-x15:
        for (int i = 0; i < 16; i = i + 1) begin
            if (i == 0) begin
                value = 32'd0;
            end else begin
                value = i;
            end

            // Se carga el valor inicial en el banco de registros del DUT:
            $root.tb_top.dut.core0.REGS[i] = value;

            // Se carga el mismo valor en el banco de registros del scoreboard:
            env_obj.scoreboard_obj.reg_mem[i] = value;

          	$display("x%0d = 0x%08h", i, value); // Esto es para control y depuración, se puede quitar (limitación de EDA):
        end

        // Se asegura que la cola de referencias comience vacía:
        env_obj.scoreboard_obj.res_mem.delete();

        $display("=====================================================");
        $display("");
      
    endtask

    // Se ejecuta el test principal:
    virtual task run_phase(uvm_phase phase);
      
        // Se declara la secuencia encargada de generar las instrucciones:
        base_sequence base_sequence_obj;
        super.run_phase(phase);

        // Se levanta una objeción para evitar que la simulación termine antes de completar la prueba:
        phase.raise_objection(this);

        // Se inicializan las entradas externas del DUT:
        ifc_riscv_obj.XRES     = 1'b1;
        ifc_riscv_obj.UART_RXD = 1'b1;

        // Se calcula la cantidad de instrucciones que serán generadas:
        cantidad_instrucciones = $size($root.tb_top.dut.MEM) / 4;
      
      	`uvm_info(get_type_name(), $sformatf("Cantidad de instrucciones por generar: %0d", cantidad_instrucciones), UVM_MEDIUM)

        // Se crea la secuencia mediante la fábrica:
        base_sequence_obj = base_sequence::type_id::create("base_sequence_obj");

        // Se indica a la secuencia cuántas instrucciones debe generar:
        base_sequence_obj.cantidad_instrucciones = cantidad_instrucciones;

        // Se mantienen algunos ciclos iniciales con el reset externo activo:
        repeat (2) @(posedge ifc_riscv_obj.XCLK);

        $display("");
        $display("Generando y cargando instrucciones en la memoria...");
        $display("");

        // Se inicia la secuencia en el sequencer del agente activo:
        base_sequence_obj.start(env_obj.agent_instruction_obj.sequencer_obj);

        // Se espera hasta que el driver indique que terminó de cargar todas las instrucciones:
        wait(ifc_riscv_obj.mem_loaded === 1'b1);

      	`uvm_info(get_type_name(), $sformatf("Memoria cargada con %0d instrucciones", ifc_riscv_obj.instr_count),UVM_MEDIUM)

        // Se inicializan los registros antes de liberar el reset:
        load_initial_registers();

        // Se mantiene el reset externo activo durante algunos ciclos más:
        repeat (5) @(posedge ifc_riscv_obj.XCLK);

        // Se desactiva el reset externo:
        ifc_riscv_obj.XRES = 1'b0;

        $display("");
        $display("Reset externo desactivado.");
        $display("Esperando que termine el reset interno del darkriscv...");
        $display("");

        // Se espera hasta que termine el reset interno del procesador:
        wait(ifc_riscv_obj.res === 1'b0);

        // Se espera al flanco negativo para comenzar desde un punto estable:
        @(negedge ifc_riscv_obj.XCLK);

        $display("");
        $display("Reset interno desactivado.");
        $display("Iniciando ejecución y verificación del DUT.");
        $display("");

        repeat (1000) @(posedge ifc_riscv_obj.XCLK);

        $display("");
        $display("Fin de la simulación.");
        $display("");

        // Se baja la objeción para permitir que UVM termine la simulación:
        phase.drop_objection(this);
      
    endtask

endclass