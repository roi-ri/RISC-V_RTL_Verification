/*
*
* =============================================================================
*
* - File        : u_type_model.sv
* - Autor       : Brandon Jiménez Campos (C33972)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       :
* - Descripción : Modelo de referencia encargado de calcular el resultado
*                 esperado para las instrucciones U-Type del procesador RISC-V.
*
* =============================================================================
*/
package u_type_model;

    import model_values::*;

    function automatic result u_type_model_reference(
        input result       current_reference,
        input logic [31:0] instr
    );

        result reference;

        // Se copia el struct actual para conservar instr_name, instr_type, pc_ref y pc_ref_next.
        reference = current_reference;

        // Campos de la instrucción U-TYPE
        reference.rd = instr[11:7];

        // Las instrucciones U-TYPE no utilizan registros fuente:
        reference.rs1     = 5'd0;
        reference.rs2     = 5'd0;
        reference.rs1_val = 32'd0;
        reference.rs2_val = 32'd0;

        // El inmediato U-TYPE se coloca en los 20 bits superiores y llena los bits restantes con ceros
        reference.imm = {
            instr[31:12],
            12'd0
        };

        // No utiliza shamt ni realiza un salto:
        reference.shamt  = 5'd0;
        reference.branch = 1'b0;

        // Implementación de LUI

        case (reference.instr_name)
          
            "LUI": begin
              	// LUI coloca el inmediato en los bits [31:12] y llena los bits [11:0] con ceros
                reference.res_ref = reference.imm;
            end

            default: begin
                reference.res_ref = 32'd0;
            end
          
        endcase

        // El PC avanza normalmente en 4:
        reference.pc_4 = 1'b1;

        // Se devuelve el struct completo actualizado:
        return reference;

    endfunction

endpackage