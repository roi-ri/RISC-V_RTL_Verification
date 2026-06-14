/*
*
* =============================================================================
*
* - File        : j_type_model.sv
* - Autor       : Brandon Jiménez Campos (C33972)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       :
* - Descripción : Modelo de referencia encargado de calcular el valor de
*                 retorno y el PC siguiente para las instrucciones J-Type
*                 del procesador RISC-V.
*
* =============================================================================
*/
package j_type_model;

    import model_values::*;

    function automatic result j_type_model_reference(
        input result       current_reference,
        input logic [31:0] instr
    );

        result reference;

        // Se copia el struct actual para conservar los valores anteriores:
        reference = current_reference;

        // Falta implementar la instrucción J_TYPE:
        reference.pc_4 = 1'b1;

        // Se devuelve el struct completo:
        return reference;

    endfunction

endpackage