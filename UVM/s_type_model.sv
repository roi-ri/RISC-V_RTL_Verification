/*
*
* =============================================================================
*
* - File        : s_type_model.sv
* - Autor       : Brandon Jiménez Campos (C33972)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       :
* - Descripción : Modelo de referencia encargado de calcular la dirección y el
*                 dato esperado para instrucciones S-Type.
*
* =============================================================================
*/

package s_type_model;

    import model_values::*;

    function automatic result s_type_model_reference(
        input result       current_reference,
        input logic [31:0] instr,
        input logic [31:0] rs1_value,
        input logic [31:0] rs2_value
    );

        result reference;

        reference = current_reference;

        reference.rs1 = instr[19:15];
        reference.rs2 = instr[24:20];
        reference.rd  = 5'd0;

        reference.rs1_val = rs1_value;
        reference.rs2_val = rs2_value;

        reference.imm = {
            {20{instr[31]}},
            instr[31:25],
            instr[11:7]
        };

        reference.shamt     = 5'd0;
        reference.branch    = 1'b0;
        reference.pc_4      = 1'b1;
        reference.writes_rd = 1'b0;

        case (reference.instr_name)

            "SB",
            "SH",
            "SW": begin
                reference.res_ref = reference.rs1_val + reference.imm;
            end

            default: begin
                reference.res_ref = 32'd0;
            end

        endcase

        return reference;

    endfunction

endpackage
