`timescale 1ns/1ps

module tb_top;

    // Se importa el paquete de UVM:
    import uvm_pkg::*;

    // Se declara el reloj externo del DUT:
    logic XCLK;

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
            #5 XCLK = ~XCLK;
        end
    end

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