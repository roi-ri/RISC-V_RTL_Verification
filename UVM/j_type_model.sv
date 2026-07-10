/*
* =============================================================================
*
* - File        : j_type_model.sv
* - Autor       : Luis Diego Ramírez Leitón (C36421), Rodrigo Sánchez Araya (C37259), Brandon Jiménez Campos (C33972)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 09-07-2026
* - Descripción : Modelo de referencia para instrucciones tipo J. Calcula el
*                 enlace de JAL y el siguiente PC esperado para válidar el
*                 flujo de control observado en el DUT.
*
* =============================================================================
*/

// Se crea el paquete con el modelo de referencia para instrucciones tipo J:
package j_type_model;

    // Se importa la estructura comun de resultados teóricos:
    import model_values::*;

    // Función para calcular el enlace y destino de una instrucción JAL:
    function automatic result j_type_model_reference(
        input result       current_reference,
        input logic [31:0] instr
    );

        result reference;

        reference = current_reference;

        // Campos de la instrucción J-TYPE.
        reference.rd = instr[11:7];

        // JAL no utiliza registros fuente.
        reference.rs1     = 5'd0;
        reference.rs2     = 5'd0;
        reference.rs1_val = 32'd0;
        reference.rs2_val = 32'd0;
        reference.shamt   = 5'd0;

        // Inmediato J-TYPE con extensión de signo.
        reference.imm = {
            {11{instr[31]}},
            instr[31],
            instr[19:12],
            instr[20],
            instr[30:21],
            1'b0
        };

        case (reference.instr_name)

            "JAL": begin

                reference.res_ref     = reference.pc_ref + 32'd4;
                reference.pc_ref_next = reference.pc_ref + reference.imm;
                reference.branch      = 1'b1;
                reference.pc_4        = 1'b0;

            end

            default: begin

                reference.res_ref = 32'd0;
                reference.branch  = 1'b0;
                reference.pc_4    = 1'b1;

            end

        endcase

        return reference;

    endfunction

endpackage
