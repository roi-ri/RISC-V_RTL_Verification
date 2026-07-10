/*
*
* =============================================================================
*
* - File        : decode_pkg.sv
* - Autor       : Brandon Jiménez Campos (C33972)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       :
* - Descripción : Recibe una instrucción de 32 bits y la decodifica a su
*                 tipo y nombre legible. Es el inverso de instr_pkg.sv.
*
* =============================================================================
*/

package decode_pkg;

    import instr_pkg::*;

    // Función que a partir del opcode [6:0] retorna el tipo de instrucción
    // como el enum instr_set definido en instr_pkg.
    function automatic instr_set get_instr_type(input logic [31:0] instr);

        logic [6:0] opcode;
        logic [2:0] funct3;

        opcode = instr[6:0];
        funct3 = instr[14:12];

        case (opcode)

            7'b0110011: return R_TYPE;

            7'b0010011: begin

                // funct3 001 = SLLI, funct3 101 = SRLI o SRAI -> I_TYPE_SHIFT
                // resto de funct3 -> I_TYPE_ARITHMETIC
                if (funct3 == 3'b001 || funct3 == 3'b101) begin

                    return I_TYPE_SHIFT;

                end

                else begin

                    return I_TYPE_ARITHMETIC;

                end

            end

            7'b0000011: return I_TYPE_LOAD;

            7'b1100111: return I_TYPE_JUMP;

            7'b0100011: return S_TYPE;

            7'b1100011: return B_TYPE;

            7'b0110111: return U_TYPE;               // LUI

            7'b0010111: return U_TYPE;               // AUIPC

            7'b1101111: return J_TYPE;

            default:    return R_TYPE;               // valor por defecto

        endcase

    endfunction

    // Función para decodificar la instrucción completa a un string legible.
    // Se utiliza opcode, funct3 y funct7/funct12 dependiendo del caso.
    function automatic string get_instr_name(input logic [31:0] instr);

        logic [6:0]  opcode;
        logic [2:0]  funct3;
        logic [6:0]  funct7;
        logic [11:0] funct12;

        opcode  = instr[6:0];
        funct3  = instr[14:12];
        funct7  = instr[31:25];
        funct12 = instr[31:20];

        case (opcode)

            // R-TYPE -> opcode = 7'b0110011
            7'b0110011: begin

                case (funct3)

                    3'b000: begin

                        // Se depende de funct7 para conocer si es SUB o ADD:
                        if (funct7 == 7'b0100000) begin

                            return "SUB";

                        end

                        else begin

                            return "ADD";

                        end

                    end

                    3'b001: return "SLL";

                    3'b010: return "SLT";

                    3'b011: return "SLTU";

                    3'b100: return "XOR";

                    3'b101: begin

                        // Se depende de funct7 para conocer si es SRA o SRL:
                        if (funct7 == 7'b0100000) begin

                            return "SRA";

                        end

                        else begin

                            return "SRL";

                        end

                    end 

                    3'b110: return "OR";

                    3'b111: return "AND";

                    default: return "R_TYPE_UNKNOWN";

                endcase

            end

            // I-TYPE ARITHMETIC / SHIFT -> opcode = 7'b0010011
            7'b0010011: begin

                case (funct3)

                    3'b000: return "ADDI";

                    3'b010: return "SLTI";

                    3'b011: return "SLTIU";

                    3'b100: return "XORI";

                    3'b110: return "ORI";

                    3'b111: return "ANDI";

                    3'b001: return "SLLI"; 

                    3'b101: begin 

                        if (funct7 == 7'b0100000) begin

                            return "SRAI";

                        end

                        else begin

                            return "SRLI";

                        end

                    end

                    default: return "I_ARITH_SHIFT_UNKNOWN";

                endcase

            end

            // I-TYPE LOAD -> opcode = 7'b0000011
            7'b0000011: begin

                case (funct3)

                    3'b000: return "LB";

                    3'b001: return "LH";

                    3'b010: return "LW";

                    3'b100: return "LBU";

                    3'b101: return "LHU";

                    default: return "LOAD_UNKNOWN";

                endcase

            end

            // I-TYPE JUMP -> opcode = 7'b1100111
            7'b1100111: begin

                if (funct3 == 3'b000) begin

                    return "JALR";

                end

                else begin

                    return "JALR_UNKNOWN";

                end

            end

            // FENCE / FENCE.I -> opcode = 7'b0001111
            7'b0001111: begin

                case (funct3)

                    3'b000: return "FENCE";

                    3'b001: return "FENCE.I";

                    default: return "FENCE_UNKNOWN";

                endcase

            end

            // SYSTEM (CSR / ECALL / EBREAK) -> opcode = 7'b1110011
            7'b1110011: begin

                case (funct3)

                    3'b000: begin

                        case (funct12)

                            12'b000000000000: return "ECALL";

                            12'b000000000001: return "EBREAK";

                            default:          return "SYSTEM_UNKNOWN";

                        endcase

                    end

                    3'b001: return "CSRRW";

                    3'b010: return "CSRRS";

                    3'b011: return "CSRRC";

                    3'b101: return "CSRRWI";

                    3'b110: return "CSRRSI";

                    3'b111: return "CSRRCI";

                    default: return "CSR_UNKNOWN";

                endcase

            end

            // S-TYPE STORE -> opcode = 7'b0100011
            7'b0100011: begin

                case (funct3)

                    3'b000: return "SB";

                    3'b001: return "SH";

                    3'b010: return "SW";

                    default: return "STORE_UNKNOWN";

                endcase

            end

            // B-TYPE BRANCH -> opcode = 7'b1100011
            7'b1100011: begin

                case (funct3)

                    3'b000: return "BEQ";

                    3'b001: return "BNE";

                    3'b100: return "BLT";

                    3'b101: return "BGE";

                    3'b110: return "BLTU";

                    3'b111: return "BGEU";

                    default: return "BRANCH_UNKNOWN";

                endcase

            end

            // U-TYPE -> LUI / AUIPC
            7'b0110111: return "LUI";

            7'b0010111: return "AUIPC";

            // J-TYPE -> JAL
            7'b1101111: return "JAL";

            default: return "UNKNOWN_OPCODE";

        endcase

    endfunction 

endpackage
