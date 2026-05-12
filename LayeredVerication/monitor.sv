/*
* ==================================================================================
*
* - File        : monitor.sv (incluye el checker)
* - Autor       : Luis Diego Ramírez Leitón (C36421)
* - Curso       : IE0621 - Verificación Funcional del Diseño de Circuitos Integrados
*                 Universidad de Costa Rica.
* - Fecha       : 13-05-2026

* - Descripción :
*   
*   
*   
*   
* ==================================================================================
*/

// Se crea el objeto monitor para la simulación:
class monitor;

    // Se definen (instancian) las variables para el scoreboard y la interfaz.
    virtual ifc_darksocv ifc_darksocv_obj;      // Interfaz Virtual.
    scoreboard scoreboard_obj;                  // Scoreboard. 

    // Se dan valores a las variables cuando se crea el objeto de monitor:
    function new(virtual ifc_darksocv ifc_darksocv_obj, scoreboard scoreboard_obj);
        this.ifc_darksocv_obj = ifc_darksocv_obj;
        this.scoreboard_obj = scoreboard_obj;
    endfunction

    

endclass

