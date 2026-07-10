/*
* =============================================================================
*
* - File        : test.sv
* - Autor       : Luis Diego Ramírez Leitón (C36421)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 08-7-2026
* - Descripción :Test UVM principal encargado de crear el ambiente de
*                 verificación, seleccionar el tipo de instrucciones que se
*                 desea generar y ejecutar la simulación del DUT. La selección
*                 del ambiente y de la secuencia se realiza mediante el archivo
*                 instruction_selector.sv, el cual entrega una etiqueta de
*                 selección que permite trabajar con nombres en lugar de valores
*                 binarios directos.
*
* =============================================================================
*/

import instruction_selector_pkg::*;

class base_test extends uvm_test;

    // Se registra la clase en la fábrica:
    `uvm_component_utils(base_test)

    // Se declara la instancia del ambiente de verificación:
    env env_obj;

    // Se declara la interfaz virtual utilizada para controlar el DUT:
    virtual ifc_riscv ifc_riscv_obj;

    // Se declara la cantidad de instrucciones que serán generadas por la secuencia:
    int unsigned cantidad_instrucciones;

    // Se declara el selector de instrucciones utilizado durante la simulación:
    instruction_selector_e instruction_selected;

    // Dirección base donde se cargan los datos para las instrucciones LOAD.
    // La secuencia i_load_type usa x15 como registro base, por lo que x15 debe
    // apuntar a esta dirección.
    int unsigned load_data_base = 32'h00000e00;

    // Cantidad maxima de instrucciones que los monitores enviaran al scoreboard.
    // Mantiene las pruebas acotadas y evita comparar ejecución residual.
    int unsigned max_checked_instr = 800;

    // Cantidad de palabras de datos cargadas para las pruebas LOAD.
    // 32 palabras = 128 bytes. Esto cubre imm_i entre 0 y 120.
    int unsigned load_data_words = 32;

    // Se crea el constructor:
    function new(
        string name = "base_test",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction

    // Se crea el ambiente correspondiente según el selector de instrucciones:
    function automatic env create_env_from_selector(
        input instruction_selector_e selector
    );

        // Se declara el ambiente que será retornado:
        env selected_env;

        // Se seleccióna el ambiente según la etiqueta recibida:
        case (selector)

            R_TYPE_SELECTED: begin

                selected_env =
                    R_Type_env::type_id::create(
                        "env_obj",
                        this
                    );

            end

            I_ARIT_TYPE_SELECTED: begin

                selected_env =
                    I_arit_Type_env::type_id::create(
                        "env_obj",
                        this
                    );

            end

            I_SHIFT_TYPE_SELECTED: begin

                selected_env =
                    I_shift_Type_env::type_id::create(
                        "env_obj",
                        this
                    );

            end

            I_LOAD_TYPE_SELECTED: begin

                selected_env =
                    I_load_Type_env::type_id::create(
                        "env_obj",
                        this
                    );

            end

            I_JUMP_TYPE_SELECTED: begin

                selected_env =
                    I_jump_Type_env::type_id::create(
                        "env_obj",
                        this
                    );

            end

            S_TYPE_SELECTED: begin

                selected_env =
                    S_Type_env::type_id::create(
                        "env_obj",
                        this
                    );

            end

            B_TYPE_SELECTED: begin

                selected_env =
                    B_Type_env::type_id::create(
                        "env_obj",
                        this
                    );

            end

            U_TYPE_SELECTED: begin

                selected_env =
                    U_Type_env::type_id::create(
                        "env_obj",
                        this
                    );

            end

            J_TYPE_SELECTED: begin

                selected_env =
                    J_Type_env::type_id::create(
                        "env_obj",
                        this
                    );

            end

            MIXED_TYPE_SELECTED: begin

                selected_env =
                    Mixed_Type_env::type_id::create(
                        "env_obj",
                        this
                    );

            end

            RESET_LOGIC_TEST_SELECTED,
            CLOCK_VARIATION_TEST_SELECTED: begin

                selected_env =
                    env::type_id::create(
                        "env_obj",
                        this
                    );

            end

            default: begin

                `uvm_fatal(
                    get_type_name(),
                    "Selector de ambiente no reconocido"
                )

            end

        endcase

        // Se retorna el ambiente selecciónado:
        return selected_env;

    endfunction

    // Se crea la secuencia correspondiente según el selector de instrucciones:
    function automatic base_sequence create_sequence_from_selector(
        input instruction_selector_e selector
    );

        // Se declara la secuencia que será retornada:
        base_sequence selected_sequence;

        // Se seleccióna la secuencia según la etiqueta recibida:
        case (selector)

            R_TYPE_SELECTED: begin

                selected_sequence =
                    r_type_sequence::type_id::create(
                        "r_type_sequence_obj"
                    );

            end

            I_ARIT_TYPE_SELECTED: begin

                selected_sequence =
                    i_arit_type_sequence::type_id::create(
                        "i_arit_type_sequence_obj"
                    );

            end

            I_SHIFT_TYPE_SELECTED: begin

                selected_sequence =
                    i_shift_type_sequence::type_id::create(
                        "i_shift_type_sequence_obj"
                    );

            end

            I_LOAD_TYPE_SELECTED: begin

                selected_sequence =
                    i_load_type_sequence::type_id::create(
                        "i_load_type_sequence_obj"
                    );

            end

            I_JUMP_TYPE_SELECTED: begin

                selected_sequence =
                    i_jump_type_sequence::type_id::create(
                        "i_jump_type_sequence_obj"
                    );

            end

            S_TYPE_SELECTED: begin

                selected_sequence =
                    s_type_sequence::type_id::create(
                        "s_type_sequence_obj"
                    );

            end

            B_TYPE_SELECTED: begin

                selected_sequence =
                    b_type_sequence::type_id::create(
                        "b_type_sequence_obj"
                    );

            end

            U_TYPE_SELECTED: begin

                selected_sequence =
                    u_type_sequence::type_id::create(
                        "u_type_sequence_obj"
                    );

            end

            J_TYPE_SELECTED: begin

                selected_sequence =
                    j_type_sequence::type_id::create(
                        "j_type_sequence_obj"
                    );

            end

            MIXED_TYPE_SELECTED: begin

                selected_sequence =
                    mixed_type_sequence::type_id::create(
                        "mixed_type_sequence_obj"
                    );

            end

            default: begin

                `uvm_fatal(
                    get_type_name(),
                    "Selector de secuencia no reconocido"
                )

            end

        endcase

        // Se retorna la secuencia selecciónada:
        return selected_sequence;

    endfunction

    // En build phase se crean las instancias de los componentes principales:
    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        // Se obtiene la selección definida en instruction_selector.sv:
        instruction_selected =
            INSTRUCTION_SELECTED;

        // Se imprime el selector recibido por el test:
        $display("");
        $display("=====================================================");
        $display("Selector de instrucciones recibido por el test");
        $display("=====================================================");
        $display(
            "Etiqueta selecciónada : %s",
            instruction_selector_name(instruction_selected)
        );
        $display(
            "Señal selecciónada    : %04b",
            instruction_selected
        );
        $display("=====================================================");
        $display("");

        // Se crea el ambiente correspondiente mediante el selector:
        env_obj =
            create_env_from_selector(
                instruction_selected
            );

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

    endfunction

    // Se cargan valores iniciales en los registros del DUT y del scoreboard:
    function automatic logic [31:0] initial_register_value(
        input int unsigned reg_index
    );

        if (reg_index == 0) begin

            return 32'd0;

        end

        if (
            ((instruction_selected == I_LOAD_TYPE_SELECTED) ||
             (instruction_selected == MIXED_TYPE_SELECTED) ||
             (instruction_selected == S_TYPE_SELECTED)) &&
            (reg_index == 15)
        ) begin

            return load_data_base;

        end

        case (reg_index)

            1:  return 32'h0000_0011;
            2:  return 32'h0000_0023;
            3:  return 32'h0000_0047;
            4:  return 32'h0000_0089;
            5:  return 32'h0000_0101;
            6:  return 32'h0000_0203;
            7:  return 32'h0000_0407;
            8:  return 32'h7fff_ff00;
            9:  return 32'h8000_0010;
            10: return 32'hffff_ff80;
            11: return 32'h0000_0f0f;
            12: return 32'h00ff_00ff;
            13: return 32'h55aa_55aa;
            14: return 32'haa55_aa55;
            15: return 32'h0000_080f;

            default: return reg_index[31:0];

        endcase

    endfunction

    task automatic load_initial_registers(
        input bit force_dut_regs = 1'b0
    );

        // Se declara la variable temporal utilizada para asignar cada registro:
        logic [31:0] value;

        $display("");
        $display("=====================================================");
        $display("Cargando registros iniciales del DUT y scoreboard");
        $display("=====================================================");

        // Se inicializan únicamente los registros x0-x15 debido a la configuración RV32E:
        if (force_dut_regs) begin

            $root.tb_top.force_initial_regs(
                initial_register_value(15)
            );

        end

        for (int i = 0; i < 16; i = i + 1) begin

            // Se asegura que el registro x0 se mantenga en cero:
            if (i == 0) begin

                value = 32'd0;

            end

            else begin

                value = initial_register_value(i);

            end

            // Se carga el valor inicial en el banco de registros del DUT:
            if (!force_dut_regs) begin

                $root.tb_top.dut.core0.REGS[i] =
                    value;

            end

            // Se carga el mismo valor inicial en el banco de registros del scoreboard:
            env_obj.scoreboard_obj.reg_mem[i] =
                value;

            // Se imprime el valor inicial utilizado para cada registro:
            $display(
                "x%0d = 0x%08h",
                i,
                value
            );

        end

        // Se asegura que la cola de resultados esperados comience vacía:
        env_obj.scoreboard_obj.res_mem.delete();
        env_obj.scoreboard_obj.actual_mem.delete();

        $display("=====================================================");
        $display("");

    endtask

    // Se carga una zona de datos en la memoria del DUT y en la memoria del scoreboard.
    // Esta tarea se usa únicamente cuando se prueban instrucciones I_LOAD_TYPE.
    task automatic release_initial_register_forces();

        $root.tb_top.release_initial_regs();

    endtask

    task automatic load_initial_data_memory();

        // Se declara la palabra temporal que se cargará en memoria:
        logic [31:0] data_word;

        // Se declara una versión de 8 bits del índice para construir los datos:
        logic [7:0] w_byte;

        $display("");
        $display("=====================================================");
        $display("Cargando memoria de datos para instrucciones LOAD");
        $display("=====================================================");
        $display(
            "Base de datos: 0x%08h",
            load_data_base
        );

        // Se cargan varias palabras de datos consecutivas:
        for (int w = 0; w < load_data_words; w = w + 1) begin

            // Se convierte el índice a 8 bits:
            w_byte = w[7:0];

            // Se construye una palabra con bytes distintos para poder verificar
            // LB, LH, LW, LBU y LHU.
            data_word = {
                8'hA0 + w_byte,
                8'h70 + w_byte,
                8'h40 + w_byte,
                8'h10 + w_byte
            };

            // Se carga la palabra en la memoria del DUT.
            // El DUT usa direcciónamiento por palabras, por eso se divide entre 4.
            $root.tb_top.dut.MEM[(load_data_base >> 2) + w] =
                data_word;

            // Se carga la misma información en la memoria del scoreboard.
            // El scoreboard modela la memoria por bytes y en little endian.
            env_obj.scoreboard_obj.data_mem[load_data_base + (4*w) + 0] =
                data_word[7:0];

            env_obj.scoreboard_obj.data_mem[load_data_base + (4*w) + 1] =
                data_word[15:8];

            env_obj.scoreboard_obj.data_mem[load_data_base + (4*w) + 2] =
                data_word[23:16];

            env_obj.scoreboard_obj.data_mem[load_data_base + (4*w) + 3] =
                data_word[31:24];

            // Se imprimen únicamente las primeras palabras para no saturar consola:
            if (w < 8) begin

                $display(
                    "MEM[0x%08h] = 0x%08h",
                    load_data_base + (4*w),
                    data_word
                );

            end

        end

        $display("=====================================================");
        $display("");

    endtask

    task automatic wait_internal_reset_value(
        input bit expected_value,
        input int unsigned max_cycles,
        input string step_name
    );

        bit reached;

        reached = 1'b0;

        for (int i = 0; i < max_cycles; i = i + 1) begin

            @(posedge ifc_riscv_obj.XCLK);

            if (ifc_riscv_obj.res === expected_value) begin

                reached = 1'b1;
                break;

            end

        end

        if (!reached) begin

            `uvm_error(
                get_type_name(),
                $sformatf(
                    "La prueba de reinicio no observó %s dentro de %0d ciclos",
                    step_name,
                    max_cycles
                )
            )

        end

    endtask

    task automatic run_reset_logic_test();

        $display("");
        $display("=====================================================");
        $display("Prueba de reinicio de lógica");
        $display("=====================================================");

        ifc_riscv_obj.UART_RXD = 1'b1;
        ifc_riscv_obj.XRES = 1'b1;
        repeat (6) @(posedge ifc_riscv_obj.XCLK);
        wait_internal_reset_value(1'b1, 20, "reset interno activo");

        ifc_riscv_obj.XRES = 1'b0;
        wait_internal_reset_value(1'b0, 700, "reset interno inactivo");
        repeat (10) @(posedge ifc_riscv_obj.XCLK);

        ifc_riscv_obj.XRES = 1'b1;
        wait_internal_reset_value(1'b1, 40, "reset interno activo después del pulso");
        repeat (6) @(posedge ifc_riscv_obj.XCLK);

        ifc_riscv_obj.XRES = 1'b0;
        wait_internal_reset_value(1'b0, 700, "reset interno inactivo después del pulso");

        $display("Resultado: prueba de reinicio ejecutada.");
        $display("=====================================================");
        $display("");

    endtask

    task automatic check_clock_period(
        input time half_period,
        input string step_name
    );

        time t0;
        time t1;
        time expected_period;

        expected_period = 2 * half_period;

        $root.tb_top.set_clock_half_period(half_period);

        repeat (3) @(posedge ifc_riscv_obj.XCLK);
        t0 = $time;
        @(posedge ifc_riscv_obj.XCLK);
        t1 = $time;

        if ((t1 - t0) != expected_period) begin

            `uvm_error(
                get_type_name(),
                $sformatf(
                    "Periodo incorrecto en %s: esperado %0t, observado %0t",
                    step_name,
                    expected_period,
                    (t1 - t0)
                )
            )

        end

        else begin

            $display(
                "%s: periodo observado = %0t",
                step_name,
                (t1 - t0)
            );

        end

    endtask

    task automatic run_clock_variation_test();

        $display("");
        $display("=====================================================");
        $display("Prueba de variación de reloj");
        $display("=====================================================");

        ifc_riscv_obj.UART_RXD = 1'b1;
        ifc_riscv_obj.XRES = 1'b1;

        check_clock_period(5ns, "Reloj nominal");
        check_clock_period(3ns, "Reloj rápido");
        check_clock_period(8ns, "Reloj lento");
        check_clock_period(5ns, "Reloj restaurado");

        ifc_riscv_obj.XRES = 1'b0;
        wait_internal_reset_value(1'b0, 700, "reset interno inactivo con reloj restaurado");

        $display("Resultado: prueba de variación de reloj ejecutada.");
        $display("=====================================================");
        $display("");

    endtask

    // Se ejecuta el test principal:
    virtual task run_phase(uvm_phase phase);

        // Se declara la secuencia encargada de generar las instrucciones:
        base_sequence base_sequence_obj;

        // Se declara la cantidad de ciclos que se dejará ejecutar el DUT:
        int unsigned ciclos_ejecucion;

        super.run_phase(phase);

        // Se levanta una objeción para evitar que la simulación termine antes de completar la prueba:
        phase.raise_objection(this);

        // Se inicializan las entradas externas del DUT:
        ifc_riscv_obj.XRES     = 1'b1;
        ifc_riscv_obj.UART_RXD = 1'b1;

        if (instruction_selected == RESET_LOGIC_TEST_SELECTED) begin

            run_reset_logic_test();
            phase.drop_objection(this);
            return;

        end

        if (instruction_selected == CLOCK_VARIATION_TEST_SELECTED) begin

            run_clock_variation_test();
            phase.drop_objection(this);
            return;

        end

        // Se calcula la cantidad de instrucciones que serán generadas.
        // Para LOAD se reserva parte de la memoria para datos, por eso no se
        // llena toda la memoria con instrucciones.
        if (
            (instruction_selected == B_TYPE_SELECTED) ||
            (instruction_selected == J_TYPE_SELECTED)
        ) begin

            cantidad_instrucciones =
                $size($root.tb_top.dut.MEM);

        end

        else if (instruction_selected == I_JUMP_TYPE_SELECTED) begin

            cantidad_instrucciones =
                600;

        end

        else if (instruction_selected == MIXED_TYPE_SELECTED) begin

            cantidad_instrucciones =
                1000;

        end

        else begin

            cantidad_instrucciones =
                max_checked_instr;

        end

        // Se crea la secuencia correspondiente mediante el selector:
        base_sequence_obj =
            create_sequence_from_selector(
                instruction_selected
            );

        // Se verifica que la secuencia haya sido creada correctamente:
        if (base_sequence_obj == null) begin

            `uvm_fatal(
                get_type_name(),
                "No se pudo crear la secuencia selecciónada"
            )

        end

        // Se indica a la secuencia cuántas instrucciones debe generar:
        base_sequence_obj.cantidad_instrucciones =
            cantidad_instrucciones;

        // Se imprime el tipo de instrucciones que se generará:
        $display("");
        $display("=====================================================");
        $display("Configuración de generación de instrucciones");
        $display("=====================================================");
        $display(
            "Tipo de instrucción : %s",
            instruction_selector_name(instruction_selected)
        );
        $display(
            "Selector binario    : %04b",
            instruction_selected
        );
        $display(
            "Cantidad solicitada : %0d instrucciones",
            cantidad_instrucciones
        );
        $display("=====================================================");
        $display("");

        // Se mantienen algunos ciclos iniciales con el reset externo activo:
        repeat (2) @(posedge ifc_riscv_obj.XCLK);

        // Se inicia la secuencia en el sequencer del agente activo:
        base_sequence_obj.start(
            env_obj.agent_instruction_obj.sequencer_obj
        );

        // Se espera hasta que el driver indique que terminó de cargar todas las instrucciones:
        wait(ifc_riscv_obj.mem_loaded === 1'b1);

        // Se imprime únicamente el resumen final de la carga de memoria:
        $display("");
        $display("=====================================================");
        $display(
            "Memoria cargada con %0d instrucciones",
            ifc_riscv_obj.instr_count
        );
        $display("=====================================================");
        $display("");

        load_initial_registers(1'b1);

        // IMPORTANTE:
        // Los registros se inicializan antes de liberar el reset externo.
        // Esto evita que el DUT empiece a ejecutar con registros sin inicializar.

        // Si se están probando LOAD, se inicializa una zona de memoria de datos
        // separada de la zona donde se cargó el programa.
        if ((instruction_selected == I_LOAD_TYPE_SELECTED) ||
            (instruction_selected == MIXED_TYPE_SELECTED)) begin

            load_initial_data_memory();

        end

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

        // IMPORTANTE:
        // Los registros fueron forzados mientras el DUT estaba en reset.
        // Al terminar el reset interno se libera el force antes del siguiente
        // flanco negativo, que es cuando los monitores empiezan a observar.
        #1step;
        release_initial_register_forces();

        // Se espera al flanco negativo para comenzar desde un punto estable:
        @(negedge ifc_riscv_obj.XCLK);

        $display("");
        $display("Reset interno desactivado.");
        $display("Iniciando ejecución y verificación del DUT.");
        $display("");

        // Se calcula la cantidad de ciclos de ejecución.
        // Para LOAD se da más margen porque los loads pueden reflejarse más lento
        // en el monitor debido a la latencia de memoria/pipeline.
        if (instruction_selected == MIXED_TYPE_SELECTED) begin

            ciclos_ejecucion =
                (4 * cantidad_instrucciones) + 200;

        end

        else if (instruction_selected == I_LOAD_TYPE_SELECTED) begin

            ciclos_ejecucion =
                (2 * cantidad_instrucciones) + 50;

        end

        else if (
            (instruction_selected == I_JUMP_TYPE_SELECTED) ||
            (instruction_selected == J_TYPE_SELECTED)
        ) begin

            ciclos_ejecucion =
                (3 * cantidad_instrucciones) + 100;

        end

        else begin

            ciclos_ejecucion =
                cantidad_instrucciones + 50;

        end

        // Se deja ejecutar el procesador únicamente durante los ciclos necesarios.
        // Esto evita que el DUT siga ejecutando demasíado fuera del programa cargado.
        repeat (ciclos_ejecucion) @(posedge ifc_riscv_obj.XCLK);

        $display("");
        $display("Fin de la simulación.");
        $display("");

        // Se baja la objeción para permitir que UVM termine la simulación:
        phase.drop_objection(this);

    endtask

endclass
