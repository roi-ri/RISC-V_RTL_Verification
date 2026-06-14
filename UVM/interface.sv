/*
* ===================================================================================
*
* - File        : interface.sv
* - Autor       : Rodrigo Sanchez Araya (C37259) - Luis Diego Ramírez Leitón (C36421)
* - Curso       : IE0621 - Verificación Funcional del Diseño de Circuitos Integrados
*                 Universidad de Costa Rica.
* - Fecha       : 13/6/2026
*
* - Descripción : Interfaz que agrupa las señales externas del DUT darksocv
*                 utilizadas por el ambiente de verificación: reloj, reset, UART,
*                 LEDs y DEBUG. Sirve como punto de conexión entre el testbench
*                 y los componentes de verificación.
*
* ==================================================================================
*/

interface ifc_riscv (input logic XCLK);

    logic XRES;

    logic UART_RXD;
    logic UART_TXD;

    logic [3:0] LED;
    logic [3:0] DEBUG;

    // Señales internas que son de interés para el monitor:
    logic        clk;
    logic        res;

    logic [31:0] rmdata;
    logic [31:0] nxpc2;
    logic [31:0] simm;

    // Señales internas - Registros para revisar escritura - unpacked array:
    logic [31:0] regs [0:15];

    // Señales que representan la instrucción procesada en el ciclo actual:
    logic        commit_valid;
    logic [31:0] commit_instr;
    logic [31:0] commit_pc;

    // Señales relacionadas con el registro destino:
    logic        commit_writes_rd;
    logic [4:0]  commit_rd;

    // Señales registradas para información adicional:
    logic [31:0] commit_alu_result;
    logic [31:0] commit_simm;

    // Se usa el reloj externo como reloj del darkriscv:
    assign clk = XCLK;

    // Control desde el driver al monitor de instrucciones:
    logic        mem_loaded;
    int unsigned instr_count;

endinterface
