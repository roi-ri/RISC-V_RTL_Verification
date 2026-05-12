/*
* ==================================================================================
*
* - File        : top.sv 
* - Autor       : Luis Diego Ramírez Leitón (C36421)  *Modificación inicial*
* - Curso       : IE0621 - Verificación Funcional del Diseño de Circuitos Integrados
*                 Universidad de Costa Rica.
* - Fecha       : 13-05-2026

* - Descripción :
*   Se agrega lo necesario para realizar la prueba inicial, es decir: Generador
*   del clk y reset, instancia del DUT (darksocv.v) y algunas partes adicionales
*   como la lógica para abrir EPWave, junto a la lógica para finalizar la 
*   simulación. 
* ==================================================================================
*/

`timescale 1ns/1ps
module top ();
  
  	// Lógica necesaria para abrir EPWave:
  	initial begin
      $dumpfile("dump.vcd");
      $dumpvars(0, top);
    end 
	
  	// Definición del clk y reset:
    logic clk;
    logic reset;
	
  	// Generador del clk:
    initial begin
      clk = 0;
      forever begin
        #1 clk = ~clk;
      end
    end
  	
  	// Generador de reset:
    initial begin
      reset = 1;
      #2 
      reset = 0;
    end
  	
  	// Instanciación del darksocv.v (DUT).
    darksocv DUT (
      // Solo interesa la salida con la instrucción:
      .XCLK(clk),
      .XRES(reset)
    );
  	
  	// Para finalizar la simulación:
	initial begin
     #565;
      $finish;
    end

endmodule