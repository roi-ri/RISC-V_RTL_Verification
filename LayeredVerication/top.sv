`timescale 1ns/1ps

module top;

    logic XCLK;

    ifc_riscv ifc_riscv_obj(XCLK);

    darksocv dut (
        .XCLK     (ifc_riscv_obj.XCLK),
        .XRES     (ifc_riscv_obj.XRES),
        .UART_RXD (ifc_riscv_obj.UART_RXD),
        .UART_TXD (ifc_riscv_obj.UART_TXD),
        .LED      (ifc_riscv_obj.LED),
        .DEBUG    (ifc_riscv_obj.DEBUG)
    );

    initial begin
        XCLK = 1'b0;
        forever #5 XCLK = ~XCLK;
    end

    assign ifc_riscv_obj.res    = dut.core0.RES;
    assign ifc_riscv_obj.rmdata = dut.core0.RMDATA;
    assign ifc_riscv_obj.nxpc2  = dut.core0.NXPC2;
    assign ifc_riscv_obj.simm   = dut.core0.SIMM;

    testcase test(ifc_riscv_obj);

endmodule
