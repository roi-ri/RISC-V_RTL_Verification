/*
* =============================================================================
*
* - File        : tb_top.sv
* - Autor       : Luis Diego Ramírez Leitón (C36421), Rodrigo Sánchez Araya (C37259), Brandon Jiménez Campos (C33972)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 09-07-2026
* - Descripción : Módulo superior del testbench. Instancia el DUT, conecta la
*                 interfaz de verificación, genera el reloj y expone señales
*                 internas necesarias para monitores y scoreboard.
*
* =============================================================================
*/

`timescale 1ns/1ps

module tb_top;

    // Se importa el paquete de UVM:
    import uvm_pkg::*;

    // Se declara el reloj externo del DUT:
    logic XCLK;
    time clock_half_period = 5ns;

    // Se instancia la interfaz utilizada por los componentes de verificación:
    ifc_riscv ifc_riscv_obj(XCLK);

    // Se instancia el DUT:
    darksocv dut (
        .XCLK     (ifc_riscv_obj.XCLK),
        .XRES     (ifc_riscv_obj.XRES),
        .UART_RXD (ifc_riscv_obj.UART_RXD),
        .UART_TXD (ifc_riscv_obj.UART_TXD),
        .LED      (ifc_riscv_obj.LED),
        .DEBUG    (ifc_riscv_obj.DEBUG)
    );

    // Se genera el reloj externo:
    initial begin
        XCLK = 1'b0;

        forever begin
            #(clock_half_period) XCLK = ~XCLK;
        end
    end

    task set_clock_half_period(input time new_half_period);
        if (new_half_period > 0) begin
            clock_half_period = new_half_period;
        end
    endtask

    // Se conectan con la interfaz las señales internas del DUT:
    assign ifc_riscv_obj.res = dut.core0.XRES;
    assign ifc_riscv_obj.rmdata = dut.core0.RMDATA;
    assign ifc_riscv_obj.nxpc2 = dut.core0.NXPC2;
    assign ifc_riscv_obj.simm = dut.core0.SIMM;

    // Se asignan los registros con un for, porque REGS corresponde a un arreglo unpacked:
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : conectar_regs
            assign ifc_riscv_obj.regs[i] =
                dut.core0.REGS[i];
        end
    endgenerate

    task force_initial_regs(
        input logic [31:0] reg15_value
    );

        force dut.core0.REGS[0]  = 32'd0;
        force dut.core0.REGS[1]  = 32'h0000_0011;
        force dut.core0.REGS[2]  = 32'h0000_0023;
        force dut.core0.REGS[3]  = 32'h0000_0047;
        force dut.core0.REGS[4]  = 32'h0000_0089;
        force dut.core0.REGS[5]  = 32'h0000_0101;
        force dut.core0.REGS[6]  = 32'h0000_0203;
        force dut.core0.REGS[7]  = 32'h0000_0407;
        force dut.core0.REGS[8]  = 32'h7fff_ff00;
        force dut.core0.REGS[9]  = 32'h8000_0010;
        force dut.core0.REGS[10] = 32'hffff_ff80;
        force dut.core0.REGS[11] = 32'h0000_0f0f;
        force dut.core0.REGS[12] = 32'h00ff_00ff;
        force dut.core0.REGS[13] = 32'h55aa_55aa;
        force dut.core0.REGS[14] = 32'haa55_aa55;
        force dut.core0.REGS[15] = reg15_value;

    endtask

    task release_initial_regs();

        release dut.core0.REGS[0];
        release dut.core0.REGS[1];
        release dut.core0.REGS[2];
        release dut.core0.REGS[3];
        release dut.core0.REGS[4];
        release dut.core0.REGS[5];
        release dut.core0.REGS[6];
        release dut.core0.REGS[7];
        release dut.core0.REGS[8];
        release dut.core0.REGS[9];
        release dut.core0.REGS[10];
        release dut.core0.REGS[11];
        release dut.core0.REGS[12];
        release dut.core0.REGS[13];
        release dut.core0.REGS[14];
        release dut.core0.REGS[15];

    endtask

    // Se capturan los datos correspondientes a la instrucción procesada por el darkriscv:
    always @(posedge XCLK) begin

        // No existe una instrucción válida durante el reset interno:
      if ((dut.core0.XRES === 1'b1) || (dut.core0.OPCODE == 7'd0)) begin
            ifc_riscv_obj.commit_valid      <= 1'b0;
            ifc_riscv_obj.commit_instr      <= 32'd0;
            ifc_riscv_obj.commit_pc         <= 32'd0;
            ifc_riscv_obj.commit_writes_rd  <= 1'b0;
            ifc_riscv_obj.commit_rd         <= 5'd0;
            ifc_riscv_obj.commit_alu_result <= 32'd0;
            ifc_riscv_obj.commit_simm       <= 32'd0;
        end else begin

            // Se indica una instrucción válida:
            ifc_riscv_obj.commit_valid <= 1'b1;

            // Se guarda la instrucción procesada:
            ifc_riscv_obj.commit_instr <= dut.core0.XIDATA;

            // Se guarda el PC asociado con la instrucción:
            ifc_riscv_obj.commit_pc <= dut.core0.PC;

          	// Se indica si la instrucción escribe en el banco de registros (la sacamos del EPWave):
            ifc_riscv_obj.commit_writes_rd <=
                (
                    dut.core0.RCC   ||
                    dut.core0.MCC   ||
                    dut.core0.LCC   ||
                    dut.core0.LUI   ||
                    dut.core0.AUIPC ||
                    dut.core0.JAL   ||
                    dut.core0.JALR
                ) && (dut.core0.DPTR != 0);

          	// Se saca la el DPTR, dirección del registro (lo sacamos del EPWave):
            ifc_riscv_obj.commit_rd <= {1'b0, dut.core0.DPTR[3:0]};

            // Se guarda el resultado de la ALU asociado con la instrucción:
            ifc_riscv_obj.commit_alu_result <= dut.core0.RMDATA;

            // Se guarda el inmediato con extensión de signo:
            ifc_riscv_obj.commit_simm <= dut.core0.SIMM;

        end

    end

    // Se definen funciones auxiliares para escribir las aserciones de forma legible:
    function automatic bit is_jal(input logic [31:0] instr);
        return instr[6:0] == 7'b1101111;
    endfunction

    function automatic bit is_jalr(input logic [31:0] instr);
        return instr[6:0] == 7'b1100111;
    endfunction

    function automatic bit is_branch(input logic [31:0] instr);
        return instr[6:0] == 7'b1100011;
    endfunction

    function automatic bit is_store(input logic [31:0] instr);
        return instr[6:0] == 7'b0100011;
    endfunction

    function automatic bit is_load(input logic [31:0] instr);
        return instr[6:0] == 7'b0000011;
    endfunction

    function automatic bit is_lui(input logic [31:0] instr);
        return instr[6:0] == 7'b0110111;
    endfunction

    function automatic logic [4:0] get_rd(input logic [31:0] instr);
        return instr[11:7];
    endfunction

    function automatic logic [4:0] get_rs1(input logic [31:0] instr);
        return instr[19:15];
    endfunction

    function automatic logic [4:0] get_rs2(input logic [31:0] instr);
        return instr[24:20];
    endfunction

    function automatic logic [31:0] imm_i(input logic [31:0] instr);
        return {{20{instr[31]}}, instr[31:20]};
    endfunction

    function automatic logic [31:0] imm_s(input logic [31:0] instr);
        return {{20{instr[31]}}, instr[31:25], instr[11:7]};
    endfunction

    function automatic logic [31:0] imm_b(input logic [31:0] instr);
        return {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    endfunction

    function automatic logic [31:0] imm_u(input logic [31:0] instr);
        return {instr[31:12], 12'd0};
    endfunction

    function automatic logic [31:0] imm_j(input logic [31:0] instr);
        return {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
    endfunction

    function automatic logic [31:0] expected_imm(input logic [31:0] instr);
        case (instr[6:0])
            7'b0100011: expected_imm = imm_s(instr);
            7'b1100011: expected_imm = imm_b(instr);
            7'b0110111,
            7'b0010111: expected_imm = imm_u(instr);
            7'b1101111: expected_imm = imm_j(instr);
            default:    expected_imm = imm_i(instr);
        endcase
    endfunction

    function automatic bit pc_inside_loaded_program(input logic [31:0] pc);
        return (ifc_riscv_obj.instr_count != 0) && (pc < (ifc_riscv_obj.instr_count * 4));
    endfunction

    function automatic bit branch_taken(input logic [31:0] instr);
        logic [3:0]  rs1_idx;
        logic [3:0]  rs2_idx;
        logic [31:0] rs1_val;
        logic [31:0] rs2_val;

        rs1_idx = instr[18:15];
        rs2_idx = instr[23:20];
        rs1_val = ifc_riscv_obj.regs[rs1_idx];
        rs2_val = ifc_riscv_obj.regs[rs2_idx];

        case (instr[14:12])
            3'b000: return rs1_val == rs2_val;
            3'b001: return rs1_val != rs2_val;
            3'b100: return $signed(rs1_val) < $signed(rs2_val);
            3'b101: return $signed(rs1_val) >= $signed(rs2_val);
            3'b110: return rs1_val < rs2_val;
            3'b111: return rs1_val >= rs2_val;
            default: return 1'b0;
        endcase
    endfunction

    // =========================================================================
    // Aserciones para validar las señales observadas por el ambiente UVM.
    // Se revisan en negedge porque los monitores toman las transacciones ahí.
    // =========================================================================

    // 1) Durante el reset interno sostenido, la instrucción registrada debe permanecer en cero.
    property p_xidata_zero_during_core_reset;
        @(negedge XCLK)
        (dut.core0.XRES ##1 dut.core0.XRES) |-> dut.core0.XIDATA == 32'h0000_0000;
    endproperty

    assert property (p_xidata_zero_during_core_reset)
        else $error("Fallo en la aserción: XIDATA diferente de cero durante reset interno sostenido del core en %0t", $time);

    // 2) Si hay instrucción válida, la instrucción no debe ser cero.
    property p_commit_instr_not_zero;
        @(negedge XCLK) disable iff (ifc_riscv_obj.res)
        ifc_riscv_obj.commit_valid |-> ifc_riscv_obj.commit_instr != 32'h0000_0000;
    endproperty

    assert property (p_commit_instr_not_zero)
        else $error("Fallo en la aserción: instrucción válida igual a cero en %0t", $time);

    // 3) El registro x0 siempre debe conservar el valor cero.
    property p_x0_always_zero;
        @(negedge XCLK) disable iff (ifc_riscv_obj.res)
        ifc_riscv_obj.regs[0] == 32'h0000_0000;
    endproperty

    assert property (p_x0_always_zero)
        else $error("Fallo en la aserción: el registro x0 cambió de valor en %0t", $time);

    // 4) Toda escritura efectiva debe apuntar a un registro válido distinto de x0.
    property p_writeback_rd_valid;
        @(negedge XCLK) disable iff (ifc_riscv_obj.res)
        (ifc_riscv_obj.commit_valid && ifc_riscv_obj.commit_writes_rd)
        |-> ((ifc_riscv_obj.commit_rd != 5'd0) && (ifc_riscv_obj.commit_rd < 5'd16));
    endproperty

    assert property (p_writeback_rd_valid)
        else $error("Fallo en la aserción: escritura efectiva hacia rd inválido en %0t", $time);

    // 5) El PC de una instrucción válida debe estar alineado a 4 bytes.
    property p_pc_aligned;
        @(negedge XCLK) disable iff (ifc_riscv_obj.res)
        ifc_riscv_obj.commit_valid |-> ifc_riscv_obj.commit_pc[1:0] == 2'b00;
    endproperty

    assert property (p_pc_aligned)
        else $error("Fallo en la aserción: PC no alineado a 4 bytes en %0t", $time);

    // 6) Las instrucciones ejecutadas deben tener un opcode soportado por el ambiente.
    property p_supported_opcode;
        @(negedge XCLK) disable iff (ifc_riscv_obj.res)
        (ifc_riscv_obj.commit_valid && pc_inside_loaded_program(ifc_riscv_obj.commit_pc)) |->
            (ifc_riscv_obj.commit_instr[6:0] inside {
                7'b0110011, 7'b0010011, 7'b0000011,
                7'b0100011, 7'b1100011, 7'b0110111,
                7'b0010111, 7'b1101111, 7'b1100111
            });
    endproperty

    assert property (p_supported_opcode)
        else $error("Fallo en la aserción: opcode no soportado observado en %0t", $time);

    // 7) Las señales registradas del commit no deben contener valores desconocidos.
    property p_commit_signals_known;
        @(negedge XCLK) disable iff (ifc_riscv_obj.res)
        ifc_riscv_obj.commit_valid |->
            !$isunknown({ifc_riscv_obj.commit_instr, ifc_riscv_obj.commit_pc, ifc_riscv_obj.commit_writes_rd, ifc_riscv_obj.commit_rd});
    endproperty

    assert property (p_commit_signals_known)
        else $error("Fallo en la aserción: señales de commit con X/Z en %0t", $time);

    // 8) JAL debe usar un rd dentro del banco visible.
    property p_jal_rd_valid;
        @(negedge XCLK) disable iff (ifc_riscv_obj.res)
        (ifc_riscv_obj.commit_valid && is_jal(ifc_riscv_obj.commit_instr))
        |-> get_rd(ifc_riscv_obj.commit_instr) < 5'd16;
    endproperty

    assert property (p_jal_rd_valid)
        else $error("Fallo en la aserción: JAL usa rd fuera de x0-x15 en %0t", $time);

    // 9) STORE y BRANCH no deben escribir en el banco de registros.
    property p_store_branch_no_writeback;
        @(negedge XCLK) disable iff (ifc_riscv_obj.res)
        (ifc_riscv_obj.commit_valid && (is_store(ifc_riscv_obj.commit_instr) || is_branch(ifc_riscv_obj.commit_instr)))
        |-> !ifc_riscv_obj.commit_writes_rd;
    endproperty

    assert property (p_store_branch_no_writeback)
        else $error("Fallo en la aserción: STORE o BRANCH intentó escribir rd en %0t", $time);

    // 10) LOAD debe usar rd y rs1 dentro del banco visible.
    property p_load_registers_valid;
        @(negedge XCLK) disable iff (ifc_riscv_obj.res)
        (ifc_riscv_obj.commit_valid && is_load(ifc_riscv_obj.commit_instr))
        |-> ((get_rd(ifc_riscv_obj.commit_instr) < 5'd16) && (get_rs1(ifc_riscv_obj.commit_instr) < 5'd16));
    endproperty

    assert property (p_load_registers_valid)
        else $error("Fallo en la aserción: LOAD usa registros fuera de x0-x15 en %0t", $time);

    // 11) STORE debe usar rs1 y rs2 dentro del banco visible.
    property p_store_registers_valid;
        @(negedge XCLK) disable iff (ifc_riscv_obj.res)
        (ifc_riscv_obj.commit_valid && is_store(ifc_riscv_obj.commit_instr))
        |-> ((get_rs1(ifc_riscv_obj.commit_instr) < 5'd16) && (get_rs2(ifc_riscv_obj.commit_instr) < 5'd16));
    endproperty

    assert property (p_store_registers_valid)
        else $error("Fallo en la aserción: STORE usa registros fuera de x0-x15 en %0t", $time);

    // 12) BRANCH debe usar rs1 y rs2 dentro del banco visible.
    property p_branch_registers_valid;
        @(negedge XCLK) disable iff (ifc_riscv_obj.res)
        (ifc_riscv_obj.commit_valid && is_branch(ifc_riscv_obj.commit_instr))
        |-> ((get_rs1(ifc_riscv_obj.commit_instr) < 5'd16) && (get_rs2(ifc_riscv_obj.commit_instr) < 5'd16));
    endproperty

    assert property (p_branch_registers_valid)
        else $error("Fallo en la aserción: BRANCH usa registros fuera de x0-x15 en %0t", $time);

    // Se habilita la generación del archivo VCD y se inicia el test UVM:
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);

        $display("VCD habilitado en el tiempo %0t", $time);

      	uvm_config_db #(virtual ifc_riscv)::set(null, "*", "ifc_riscv_obj", ifc_riscv_obj);

        // Se inicia el test registrado en la fábrica:
        run_test("base_test");
    end

endmodule
