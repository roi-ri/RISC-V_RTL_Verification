/*
* =============================================================================
*
* - File        : r_type_model.sv
* - Autor       : Luis Diego Ramírez Leitón (C36421), Rodrigo Sánchez Araya (C37259), Brandon Jiménez Campos (C33972)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 09-07-2026
* - Descripción : Modelo de referencia para instrucciones tipo R. Decodifica
*                 registros fuente y destino, calcula operaciones ALU y entrega
*                 el resultado esperado al scoreboard.
*
* =============================================================================
*/

// Se crea el paquete con el modelo de referencia para instrucciones tipo R:
package r_type_model;

    // Se importa la estructura comun de resultados teóricos:
    import model_values::*;

    // Función para calcular operaciones ALU entre registros fuente:
    function automatic result r_type_model_reference(
        input result       current_reference,
        input logic [31:0] instr,
        input logic [31:0] rs1_value,
        input logic [31:0] rs2_value
    );

        result reference;

        // Se conserva la información del struct actual:
        reference = current_reference;

        // Campos de la instrucción R-TYPE:
        reference.rs2 = instr[24:20];
        reference.rs1 = instr[19:15];
        reference.rd  = instr[11:7];
        reference.imm    = 32'd0;
        reference.branch = 1'b0;

        // Los valores ya fueron leídos por el scoreboard:
        if (reference.rs1 == 5'd0) begin
            reference.rs1_val = 32'd0;
        end else begin
            reference.rs1_val = rs1_value;
        end

        if (reference.rs2 == 5'd0) begin
            reference.rs2_val = 32'd0;
        end else begin
            reference.rs2_val = rs2_value;
        end

        // Las instrucciones R-TYPE de desplazamiento utilizan los cinco bits menos significativos de rs2:
        reference.shamt = reference.rs2_val[4:0];

        case (reference.instr_name)

            "ADD": begin
                reference.res_ref = reference.rs1_val + reference.rs2_val;
            end

            "SUB": begin
                reference.res_ref = reference.rs1_val - reference.rs2_val;
            end

            "SLL": begin
                reference.res_ref = reference.rs1_val << reference.shamt;
            end

            "SLT": begin
              	if ($signed(reference.rs1_val) < $signed(reference.rs2_val)) begin
                    reference.res_ref = 32'd1;
                end else begin
                    reference.res_ref = 32'd0;
                end
            end

            "SLTU": begin
                if (reference.rs1_val < reference.rs2_val) begin
                    reference.res_ref = 32'd1;
                end else begin
                    reference.res_ref = 32'd0;
                end
            end

            "XOR": begin
                reference.res_ref = reference.rs1_val ^ reference.rs2_val;
            end

            "SRL": begin
                reference.res_ref = reference.rs1_val >> reference.shamt;
            end

            "SRA": begin
              	reference.res_ref = $signed(reference.rs1_val) >>> reference.shamt;
            end

            "OR": begin
                reference.res_ref = reference.rs1_val | reference.rs2_val;
            end

            "AND": begin
                reference.res_ref = reference.rs1_val & reference.rs2_val;
            end

            default: begin
                reference.res_ref = 32'd0;
            end

        endcase

        reference.pc_4 = 1'b1;

        return reference;

    endfunction

endpackage
