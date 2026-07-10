/*
* =============================================================================
*
* - File        : i_type_model.sv
* - Autor       : Luis Diego Ramírez Leitón (C36421), Rodrigo Sánchez Araya (C37259), Brandon Jiménez Campos (C33972)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 09-07-2026
* - Descripción : Modelo de referencia para instrucciones tipo I. Calcula los
*                 resultados esperados de operaciones aritméticas, shifts,
*                 loads y saltos indirectos usados por el scoreboard.
*
* =============================================================================
*/

// Se crea el paquete con el modelo de referencia para instrucciones tipo I:
package i_type_model;

    // Se importan los paquetes necesarios para decodificar y transportar resultados:
    import instr_pkg::*;
    import model_values::*;

    // Función para calcular la referencia esperada de una instrucción tipo I:
	function automatic result i_type_model_reference(
    	input result       current_reference,
    	input logic [31:0] instr,
    	input logic [31:0] rs1_value
	);

        result reference;

        reference = current_reference;

        // Campos comunes de las instrucciones I-TYPE:
        reference.rs1 = instr[19:15];
        reference.rd  = instr[11:7];

        reference.rs1_val = rs1_value;

        // I-TYPE no utiliza rs2:
        reference.rs2     = 5'd0;
        reference.rs2_val = 32'd0;
        reference.branch = 1'b0;

        case (reference.instr_type)

            // ========================================================
            // I-TYPE ARITHMETIC
            // ========================================================

            I_TYPE_ARITHMETIC: begin

                reference.imm = {
                    {20{instr[31]}},
                    instr[31:20]
                };

                reference.shamt = 5'd0;

                case (reference.instr_name)

                    "ADDI": begin
                        reference.res_ref = reference.rs1_val + reference.imm;
                    end

                    "SLTI": begin
                      	reference.res_ref = ($signed(reference.rs1_val) < $signed(reference.imm));
                    end

                    "SLTIU": begin
                      	reference.res_ref = ($unsigned(reference.rs1_val) < $unsigned(reference.imm));
                    end

                    "XORI": begin
                        reference.res_ref = reference.rs1_val ^ reference.imm;
                    end

                    "ORI": begin
                        reference.res_ref = reference.rs1_val | reference.imm;
                    end

                    "ANDI": begin
                        reference.res_ref = reference.rs1_val & reference.imm;
                    end

                    default: begin
                        reference.res_ref = 32'd0;
                    end

                endcase

                reference.pc_4 = 1'b1;

            end

            // ========================================================
            // I-TYPE SHIFT
            // ========================================================

            I_TYPE_SHIFT: begin

              reference.imm = {20'd0, instr[31:20]};

                reference.shamt = instr[24:20];

                case (reference.instr_name)

                    "SLLI": begin
                        reference.res_ref = reference.rs1_val << reference.shamt;
                    end

                    "SRLI": begin
                        reference.res_ref = reference.rs1_val >> reference.shamt;
                    end

                    "SRAI": begin
                      	reference.res_ref = $signed(reference.rs1_val) >>> reference.shamt;
                    end

                    default: begin
                        reference.res_ref = 32'd0;
                    end

                endcase

                reference.pc_4 = 1'b1;

            end

            // ========================================================
            // I-TYPE LOAD : se implementó en el scoreboard
            // ========================================================

            // ========================================================
            // I-TYPE JUMP: JALR
            // ========================================================

            I_TYPE_JUMP: begin

                reference.imm = {{20{instr[31]}}, instr[31:20]};
                reference.shamt = 5'd0;

                case (reference.instr_name)

                    "JALR": begin

                        reference.res_ref = reference.pc_ref + 32'd4;
                        reference.pc_ref_next = (reference.rs1_val + reference.imm) & 32'hFFFF_FFFE;
                        reference.branch = 1'b1;
                        reference.pc_4   = 1'b0;

                    end

                    default: begin
                        reference.res_ref = 32'd0;
                        reference.branch  = 1'b0;
                        reference.pc_4    = 1'b1;
                    end

                endcase

            end

            default: begin

                reference.res_ref = 32'd0;
                reference.imm     = 32'd0;
                reference.shamt   = 5'd0;
                reference.branch  = 1'b0;
                reference.pc_4    = 1'b1;

            end

        endcase

        return reference;

    endfunction

endpackage
