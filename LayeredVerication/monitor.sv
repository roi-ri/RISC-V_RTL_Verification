/*
* ==================================================================================
*
* - File        : monitor.sv (incluye el checker)
* - Autor       : Luis Diego Ramírez Leitón (C36421)
* - Curso       : IE0621 - Verificación Funcional del Diseño de Circuitos Integrados
*                 Universidad de Costa Rica.
* - Fecha       : 13-05-2026

* - Descripción :
*   Este programa se encarga de cargar los valores tanto teóricos como experiemntales,  
*   que sean de interés según la instrucción que se esté verificando. Posteriormente, 
*   los muestra, función que pertenece al monitor. Finalmente, los compara para 
*   verificar si son iguales o no, es decir, si la prueba pasó o falló.
* ==================================================================================
*/

// Se importa el paquete con las etiquetas de las instrucciones: 
import instr_pkg::*;

// Se crea la clase monitor para la simulación:
class monitor;

    // Se definen (instancian) las variables para el scoreboard y la interfaz.
    virtual ifc_riscv ifc_riscv_obj;            // Interfaz Virtual.
    scoreboard scoreboard_obj;                  // Scoreboard. 

    // Se dan valores a las variables cuando se crea el objeto de monitor:
    function new(virtual ifc_riscv ifc_riscv_obj, scoreboard scoreboard_obj);
        this.ifc_riscv_obj = ifc_riscv_obj;
        this.scoreboard_obj = scoreboard_obj;
    endfunction

    // Tarea encargada de revisar (checker):
    task check();
        // Se carga del scoreboard el struct con los parámetros de interés:
        scoreboard::result reference;

        // Se crean variables para manejar los diferentes casos según la instrucción: 
        logic [31:0]  resul_teorico;
        logic [31:0]  resul_experimental;
        logic         comparar;
        string        verificacion; 

        // Se crean contadores para llevar un resumen de las verificaciones:
        int unsigned contador_total;
        int unsigned contador;

        // Se inicializan los contadores:
        contador_total = 0;
        contador       = 0;

        // Se crea el forever para que se revise durante la simulación: 
        forever begin
            // Como el darkriscv empieza a procesar instrucciones hasta después:
            if (ifc_riscv_obj.res) begin
                // Se imprime el mensaje que indica que se espera a que baje el reset:
                $display("Monitor-checker:");
                $display("Monitor-checker: darkriscv en reset, esperando que salga.");
                $display("=====================================================");

                // Se espera hasta que el reset baje (RES == 0):
                wait(ifc_riscv_obj.res == 1'b0);

                // Se esperan dos ciclos de reloj para que aparezca la primera instrucción:
                repeat (2) @(posedge ifc_riscv_obj.clk);
                
                continue;
            end 
            
            @(posedge ifc_riscv_obj.clk);     // Se espera que se cargue la instrucción/valor.
            @(negedge ifc_riscv_obj.clk);     // Se espera al negedge después del posedge, para asegurar estabilidad.
            
            // Se revisa si no se ha activado el reset:
            if (ifc_riscv_obj.res) begin
                // Se imprime el mensaje que indica que se activó el reset:
                $display("Monitor-checker:");
                $display("Monitor-checker: Se activó reset en darkriscv.");
                $display("=====================================================");
                continue; 
            end 

            // Se revisa que el scoreboard tenga datos para comparar: 
            if (scoreboard_obj.res_mem.size() == 0) begin
                continue; 
            end 
            
            // Si hay datos, se carga el resultado teórico más antiguo.
            // El scoreboard utiliza el push_back, entonces aquí se carga usando pop_front (FIFO).
            reference = scoreboard_obj.res_mem.pop_front(); 

            // Se inicializan las variables que se crearon: 
            resul_teorico       = 32'd0;
            resul_experimental  = 32'd0;
            comparar            = 1'b0;
            verificacion        = "Instrucción no implementada"; 

            // Casos para los diferentes tipos de instrucciones (aquí según sea, se carga el valor de interés): 
            // Faltan de implementar varios tipos aún como J o I_TYPE_MEMORY_SYSTEM, entre otros.
            case(reference.instr_type)

                R_TYPE: begin
                    // Si es un tipo R lo que cambia es el registro con el resultado:
                    resul_teorico = reference.res_ref;
                    resul_experimental = ifc_riscv_obj.rmdata;              // La señal de interés es el RMDATA de darkriscv.
                    comparar = 1'b1;
                    verificacion = "R_TYPE: Registro de resultado.";
                end 

                I_TYPE_ARITHMETIC: begin
                    // Si es un tipo I aritmético lo que cambia es el registro con el resultado:
                    resul_teorico = reference.res_ref;
                    resul_experimental = ifc_riscv_obj.rmdata;              // La señal de interés es el RMDATA de darkriscv.
                    comparar = 1'b1;
                    verificacion = "I_TYPE_ARITHMETIC: Registro de resultado.";
                end

                I_TYPE_SHIFT: begin
                    // Si es un tipo I de desplazamiento lo que cambia es el registro con el resultado:
                    resul_teorico = reference.res_ref;
                    resul_experimental = ifc_riscv_obj.rmdata;              // La señal de interés es el RMDATA de darkriscv.
                    comparar = 1'b1;
                    verificacion = "I_TYPE_SHIFT: Registro de resultado.";
                end

                B_TYPE: begin
                    // Si es un tipo B lo que cambia es el PC (program counter, dirección de la próxima instrucción):
                    resul_teorico = reference.pc_ref_next;
                    resul_experimental = ifc_riscv_obj.nxpc2;               // La señal de interés es el NXPC2 de darkriscv.
                    comparar = 1'b1;
                    verificacion = "B_TYPE: Dirección de la próxima instrucción, salto.";
                end

                // Para esta sólo se implementó lui (eso en el scoreboard y por el momento).
                U_TYPE: begin 
                    // Si es un tipo U lo que cambia es el registro con el resultado, es decir, lo que carga:
                    resul_teorico = reference.res_ref;

                    // Se revisa que sea un lui, por si se prueba otra innstrucción de este tipo que indique que no se ha implementado:
                    if (reference.instr_name == "LUI") begin
                        resul_experimental = ifc_riscv_obj.simm;            // La señal de interés es el SIMM de darkriscv.
                        comparar = 1'b1;
                        verificacion = "U_TYPE: Registro de resultado.";
                    end else begin
                        comparar = 1'b0;
                        verificacion = "U_TYPE: Instrucción no implementada.";
                    end 
                end

                default: begin
                    comparar = 1'b0;
                    verificacion = "Tipo de instrucción no reconocida (o no se ha implementado).";
                end 

            endcase

            // Se revisa si se verificó o no la instrucción: 
            if (comparar) begin
                $display("Monitor-checker:");
                $display("Instrucción: %s", reference.instr_name);
                $display("Tipo: %s", reference.instr_type.name());
                $display("Resultado teórico: %h", resul_teorico);
                $display("Resultado experimental: %h", resul_experimental);
                $display("En revisión: %s", verificacion);

                // Se aumenta el contador total de instrucciones verificadas:
                contador_total++;

                // Se revisa si ambos resultados coinciden o no: 
                if (resul_teorico !== resul_experimental) begin 
                    $display("Verificación: Los resultados no coinciden (Falló).");
                end else begin
                    $display("Verificación: Los resultados coinciden (Pasó).");

                    // Se aumenta el contador de instrucciones que pasaron:
                    contador++;
                end  

                // Se muestra el resumen de verificaciones hasta el momento:
                $display("Pasaron: %0d/%0d", contador, contador_total);
                $display("=====================================================");
            end else begin
                $display("Monitor-checker:");
                $display("Instrucción: %s", reference.instr_name);
                $display("Tipo: %s", reference.instr_type.name());
                $display("En revisión: %s", verificacion);
                $display("=====================================================");
            end 

        end

    endtask

endclass            resul_experimental = ifc_riscv_obj.simm;            // La señal de interés es el SIMM de darkriscv.
                        comparar = 1'b1;
                        verificacion = "U_TYPE: Registro de resultado.";
                    end else begin
                        comparar = 1'b0;
                        verificacion = "U_TYPE: Instrucción no implementada.";
                    end 
                end

                default: begin
                    comparar = 1'b0;
                    verificacion = "Tipo de instrucción no reconocida (o no se ha implementado).";
                end 

            endcase

            // Se revisa si se verificó o no la instrucción: 
            if (comparar) begin
                // 
                $display("Monitor-checker:");
                $display("Instrucción: %s", reference.instr_name);
                $display("Tipo: %0d", reference.instr_type);
                $display("Resultado teórico: %h", resul_teorico);
                $display("Resultado experimental: %h", resul_experimental);
                $display("Estado de la revisión: %s",verificacion);

                 // Se revisa si ambos resultados coinciden o no: 
                if (resul_teorico !== resul_experimental) begin 
                    $display("Verificación: Los resultados no coinciden (Falló).");
                end else begin
                    $display("Verificación: Los resultados coinciden (Pasó).");
                end     
            end else begin
                $display("Monitor-checker:");
                $display("Instrucción: %s", reference.instr_name);
                $display("Tipo: %0d", reference.instr_type);
                $display("Estado de la revisión: %s",verificacion);
            end 

        end

    endtask

endclass
