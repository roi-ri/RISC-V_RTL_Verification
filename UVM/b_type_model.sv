/*
*
* =============================================================================
*
* - File        : b_type_model.sv
* - Autor       : Brandon Jiménez Campos (C33972)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       :
* - Descripción : Modelo de referencia encargado de calcular el resultado de
*                 la condición y el PC siguiente para las instrucciones B-Type
*                 del procesador RISC-V.
*
* =============================================================================
*/
package b_type_model;

    import model_values::*;

    function automatic result b_type_model_reference(
        input result       current_reference,
        input logic [31:0] instr,
        input logic [31:0] reg_mem[]
    );

        result reference;

        logic [2:0]  funct3;
        logic [4:0]  rs1;
        logic [4:0]  rs2;
        logic [31:0] rs1_value;
        logic [31:0] rs2_value;


        // Conservar la información anterior
        reference = current_reference;

        // Campos de la instrucción B-TYPE

        funct3 = instr[14:12];
        rs1    = instr[19:15];
        rs2    = instr[24:20];

        reference.rs1 = rs1;
        reference.rs2 = rs2;

        // Las instrucciones B no tienen registro destino:
        reference.rd        = 5'd0;
        reference.shamt     = 5'd0;
        reference.res_ref   = 32'd0;
        reference.writes_rd = 1'b0;

        // Inmediato B-TYPE con extensión de signo

        reference.imm = {
            {19{instr[31]}},
            instr[31],
            instr[7],
            instr[30:25],
            instr[11:8],
            1'b0
        };


        // Lectura del banco de registros

        if (rs1 == 5'd0) begin
            rs1_value = 32'd0;
        end else begin
            rs1_value = reg_mem[rs1];
        end

        if (rs2 == 5'd0) begin
            rs2_value = 32'd0;
        end else begin
            rs2_value = reg_mem[rs2];
        end

        reference.rs1_val = rs1_value;
        reference.rs2_val = rs2_value;


        // Evaluación de la condición del branch

        reference.branch = 1'b0;

        case (funct3)

            // BEQ:
            3'b000: begin
                reference.branch = (rs1_value == rs2_value);
            end

            // BNE:
            3'b001: begin
                reference.branch = (rs1_value != rs2_value);
            end

            // BLT: comparación con signo
            3'b100: begin
                reference.branch = ($signed(rs1_value) < $signed(rs2_value));
            end

            // BGE: comparación con signo
            3'b101: begin
                reference.branch = ($signed(rs1_value) >= $signed(rs2_value));
            end

            // BLTU: comparación sin signo
            3'b110: begin
                reference.branch = ($unsigned(rs1_value) < $unsigned(rs2_value));
            end

            // BGEU: comparación sin signo
            3'b111: begin
                reference.branch = ($unsigned(rs1_value) >= $unsigned(rs2_value));
            end
          
            default: begin
                reference.branch = 1'b0;
            end

        endcase

        // Cálculo del siguiente PC

        if (reference.branch) begin
            // Salto tomado:
            reference.pc_ref_next = reference.pc_ref + reference.imm;
            reference.pc_4 = 1'b0;
        end else begin
            // Salto no tomado:
            reference.pc_ref_next = reference.pc_ref + 32'd4;
            reference.pc_4 = 1'b1;
        end

    endfunction

endpackage