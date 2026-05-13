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

    // Se importa el paquete con las etiquetas de las instrucciones: 
    import instr_pkg::*;

    // Se definen (instancian) las variables para el scoreboard y la interfaz.
    virtual ifc_darksocv ifc_darksocv_obj;      // Interfaz Virtual.
    scoreboard scoreboard_obj;                  // Scoreboard. 

    // Se dan valores a las variables cuando se crea el objeto de monitor:
    function new(virtual ifc_darksocv ifc_darksocv_obj, scoreboard scoreboard_obj);
        this.ifc_darksocv_obj = ifc_darksocv_obj;
        this.scoreboard_obj = scoreboard_obj;
    endfunction

    // Tarea encargada de revisar (checker):
    task check();
        // Se carga el struct con los parámetros de interés: 
        scoreboard::result reference;

        // Se crean variables para manejar los diferentes casos según la instrucción: 
        logic [31:0]  resul_teorico;
        logic [31:0]  resul_experimental;
        logic         comparar;
        string        instruccion; 

        // Se crea el forever para que se revise durante la simulación: 
        forever begin
            @(posedge ifc_darksocv_obj.clk);     // Se espera que se cargue la instrucción/valor.
            @(negedge ifc_darksocv_obj.clk);     // Se espera al negedge después del posedge, para asegurar estabilidad.
            
            // Se revisa que el scoreboard tenga datos para comparar: 
            if (scoreboard_obj.res_mem.size() == 0) begin
                $display("Monitor-checker: No hay datos por comparar (scoreboard vacío).");
                continue; 
            end 
            
            // Si hay datos, se carga el resultado teórico más antiguo.
            // El scoreboard utiliza el push_back, entonces aquí se carga usando pop_front.
            reference = scoreboard_obj.res_mem.pop_front(); 

            // Se inicializan las variables que se crearon: 
            resul_teorico       = 32'd0;
            resul_experimental  = 32'd';
            comparar            = 1'b0;
            instruccion         = "No está implementada"; 

            // Casos para los diferentes tipos de instrucciones (aquí según sea, se carga el valor de interés): 
            // Faltan de implementar varios tipos aún.
            case(reference.instr_type)

                R_TYPE: begin
                    // Si es un tipo R lo que cambia es el registro con el resultado:
                    resul_teorico = reference.res_ref;
                    resul_experimental = ifc_darksocv_obj.              //*********** Falta ver el dato de interés.
                    comparar = 1'b1;
                    instruccion = "R_TYPE"
                end 

                I_TYPE_ARITHMETIC: begin
                    // Si es un tipo I aritmético lo que cambia es el registro con el resultado:
                    resul_teorico = reference.res_ref;
                    resul_experimental = ifc_darksocv_obj.              //*********** Falta ver el dato de interés.
                    comparar = 1'b1;
                    instruccion = "I_TYPE_ARITHMETIC"
                end

                I_TYPE_SHIFT: begin
                    // Si es un tipo I de desplazamiento lo que cambia es el registro con el resultado:
                    resul_teorico = reference.res_ref;
                    resul_experimental = ifc_darksocv_obj.              //*********** Falta ver el dato de interés.
                    comparar = 1'b1;
                    instruccion = "I_TYPE_SHIFT"
                end

                B_TYPE: begin
                    // Si es un tipo B lo que cambia es el PC:
                    resul_teorico = reference.pc_ref_next;
                    resul_experimental = ifc_darksocv_obj.              //*********** Falta ver el dato de interés.
                    comparar = 1'b1;
                    instruccion = "B_TYPE"
                end

                U_TYPE: begin // Para esta sólo se implementó lui (eso en el scoreboard).
                    // Si es un tipo U lo que cambia es el registro con el resultado:
                    resul_teorico = reference.res_ref;

                    // Se realiza con un lui, por si se prueba otro de este tipo que no falle:
                    if (reference.instr_name == "LUI") begin
                        resul_experimental = ifc_darksocv_obj.              //*********** Falta ver el dato de interés.
                        comparar = 1'b1;
                        instruccion = "U_TYPE: LUI resultado escrito en registro."
                    end else begin
                        comparar = 1'b0;
                        instruccion = "U_TYPE: Instrucción no implementada."
                    end 
                end

                default: begin
                    comparar = 1'b0;
                    instruccion = "Tipo de instrucción no reconocida (no se ha implementado)."
                end 

            endcase

            // Si comparar es 1, es decir, se encontró la instrucción:
            if (comparar) begin
                $display("Monitor-checker:");
                $display("Instrucción: %s", reference.instr_name);
                $display("Tipo: %0d", reference.instr_type);
                $display("Resultado teórico: %h", resul_teorico);
                $display("Resultado experimental: %h", resul_experimental);

                 // Se revisa si ambos resultados coinciden o no: 
                if (resul_teorico != resul_experimental) begin 
                    $display("Monitor-checker: Los resultados no coinciden (Fallo).");
                end else begin
                    $display("Monitor-checker: Los resultados coinciden (Paso).");
                end     
            end else begin
                $display("Monitor-checker:");
                $display("Instrucción: %s", reference.instr_name);
                $display("Tipo: %0d", reference.instr_type);
                $display("Estado de la revisión: %s", instruccion);
            end 
                
        end

    endtask

endclass