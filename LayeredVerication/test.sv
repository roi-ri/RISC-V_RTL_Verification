program testcase(ifc_riscv ifc_riscv_obj);

    env env_obj;

    int cantidad_instrucciones;


    // ============================================================
    // Carga valores iniciales en los registros del DUT y scoreboard
    // ============================================================
    task automatic load_initial_registers();

        logic [31:0] value;

        $display("");
        $display("=====================================================");
        $display("Cargando registros iniciales del DUT y scoreboard");
        $display("=====================================================");

        /*
         * El DUT está configurado como RV32E, entonces usa x0-x15.
         * Por eso solamente se cargan esos 16 registros reales del DUT.
         */
        for (int i = 0; i < 16; i = i + 1) begin

            if (i == 0) begin
                value = 32'd0;
            end
            else begin
                value = i;
            end

            $root.top.dut.core0.REGS[i] = value;
            env_obj.scoreboard_obj.reg_mem[i] = value;

            $display("x%0d = 0x%08h", i, value);

        end


        /*
         * El scoreboard tiene reg_mem[0:31], pero el DUT está en RV32E.
         * Para evitar que el scoreboard lea ceros si aparece x16-x31,
         * se espejan esos registros contra x0-x15.
         *
         * Ejemplo:
         * x16 -> x0
         * x17 -> x1
         * x18 -> x2
         * ...
         * x31 -> x15
         */
        for (int i = 16; i < 32; i = i + 1) begin
            env_obj.scoreboard_obj.reg_mem[i] = env_obj.scoreboard_obj.reg_mem[i % 16];
        end

        $display("=====================================================");
        $display("");

    endtask


    // ============================================================
    // Carga las referencias esperadas en el scoreboard
    // ============================================================
    task automatic load_scoreboard_references(input int cantidad);

        $display("");
        $display("=====================================================");
        $display("Cargando referencias esperadas en el scoreboard");
        $display("=====================================================");

        /*
         * Primero se limpia el scoreboard.
         * Esto borra la cola res_mem y reinicia el PC de referencia.
         */
        env_obj.scoreboard_obj.ref_model(32'h00000013, 1'b1);

        /*
         * Como el ref_model con reset borra los registros internos del scoreboard,
         * se vuelven a cargar los registros iniciales.
         */
        load_initial_registers();

        /*
         * Ahora sí se calculan las referencias con rst = 0.
         */
        for (int i = 0; i < cantidad; i = i + 1) begin
            env_obj.scoreboard_obj.ref_model($root.top.dut.MEM[i], 1'b0);
        end

        $display("Referencias cargadas: %0d", cantidad);
        $display("=====================================================");
        $display("");

    endtask


    // ============================================================
    // Dump para EPWave
    // ============================================================
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, top);
    end


    // ============================================================
    // Test principal
    // ============================================================
    initial begin

        env_obj = new(ifc_riscv_obj);

        cantidad_instrucciones = $size($root.top.dut.MEM) / 4;

        ifc_riscv_obj.XRES    = 1'b1;
        ifc_riscv_obj.UART_RXD = 1'b1;

        repeat (2) @(posedge ifc_riscv_obj.XCLK);

        $display("Limpiando memoria...");
        env_obj.driver_obj.clear_mem();

        $display("Generando instrucciones...");
        for (int i = 0; i < cantidad_instrucciones; i = i + 1) begin
            env_obj.driver_obj.create_write_instr(i);
        end

        /*
         * El monitor se arranca antes de bajar reset.
         * Así queda esperando a que el DUT salga de reset.
         */
        env_obj.start_monitor();

        repeat (5) @(posedge ifc_riscv_obj.XCLK);

        /*
         * Se baja el reset externo.
         */
        ifc_riscv_obj.XRES = 1'b0;

        $display("");
        $display("Reset externo desactivado. Esperando reset interno del DUT...");

        /*
         * Espera a que el reset que ve el core baje.
         */
        wait(ifc_riscv_obj.res == 1'b0);

        /*
         * En darkriscv existe un reset interno llamado XRES.
         * Este puede durar un ciclo más que el reset externo.
         * Si se cargan los registros antes de que este baje,
         * el propio core puede volver a limpiarlos.
         */
        wait($root.top.dut.core0.XRES == 1'b0);

        /*
         * Se espera al negedge para cargar registros antes del siguiente posedge,
         * que es cuando el core vuelve a actualizarse.
         */
        @(negedge ifc_riscv_obj.XCLK);

        /*
         * Se cargan registros iniciales y luego las referencias esperadas.
         */
        load_scoreboard_references(cantidad_instrucciones);

        $display("");
        $display("Reset interno desactivado. Iniciando ejecución del DUT.");
        $display("");

        repeat (1000) @(posedge ifc_riscv_obj.XCLK);

        $display("");
        $display("Fin de la simulación.");

        $finish;

    end

endprogram
