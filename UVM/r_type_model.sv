/*
*
* =============================================================================
*
* - File        : r_type_model.sv
* - Autor       : Brandon Jiménez Campos (C33972)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       :
* - Descripción : Modelo de referencia encargado de calcular el resultado
*                 esperado para las instrucciones R-Type del procesador RISC-V.
*
* =============================================================================
*/
package r_type_model;

    import model_values::*;

    function automatic result r_type_model_reference(
        input result       current_reference,
        input logic [31:0] instr,
        input logic [31:0] rs1_value,
        input logic [31:0] rs2_value
    );

        result reference;

        // Se conserva la información del struct actual:
        reference = current_reference;
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