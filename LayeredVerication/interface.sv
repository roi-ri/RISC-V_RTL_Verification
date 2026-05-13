/*
* =============================================================================
*
* - File        : interface.sv
* - Autor       : Rodrigo Sanchez Araya (C37259)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción :Interfaz que agrupa las señales externas del DUT darksocv
*                 utilizadas por el ambiente de verificación: reloj, reset, UART,
*                 LEDs y DEBUG. Sirve como punto de conexión entre el testbench
*                 y los componentes de verificación. 
*
* =============================================================================
*/
interface ifc_riscv (
    input logic XCLK
);

    logic XRES;

    logic UART_RXD;
    logic UART_TXD;

    logic [3:0] LED;
    logic [3:0] DEBUG;

endinterface





