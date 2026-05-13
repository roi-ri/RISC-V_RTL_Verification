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


    //función que a partir del opcode [6:0] retorna el tipo de instrucción como el enum intr_set definido en instr_pkg.
    function intr_set get_instr_type(input logic [31:0] instr);
        logic [6:0] opcode;
        logic [2:0] funct3;
        opcode = instr[6:0];
        funct3 = instr[14:12];
 
        case (opcode)
            7'b0110011: return R_TYPE;
            7'b0010011: begin
                // funct3 001 = SLLI, funct3 101 = SRLI o SRAI -> I_TYPE_SHIFT
                // resto de funct3 -> I_TYPE_ARITHMETIC
                if (funct3 == 3'b001 || funct3 == 3'b101)
                    return I_TYPE_SHIFT;
                else
                    return I_TYPE_ARITHMETIC;
            end
            7'b0000011: return I_TYPE_LOAD;
            7'b1100111: return I_TYPE_JUMP;
            7'b0001111: return I_TYPE_MEMORY_SYSTEM; // FENCE / FENCE.I
            7'b1110011: return I_TYPE_MEMORY_SYSTEM; // CSR / ECALL / EBREAK
            7'b0100011: return S_TYPE;
            7'b1100011: return B_TYPE;
            7'b0110111: return U_TYPE;               // LUI
            7'b0010111: return U_TYPE;               // AUIPC
            7'b1101111: return J_TYPE;
            default:    return R_TYPE;               // valor por defecto
        endcase
    endfunction
 
 

    // función para decodificar la instrucción completa a un string legible se utiliza opcode, funct3 y funct7/funct12 dependiendo del caso.
    function string get_instr_name(input logic [31:0] instr);
        logic [6:0] opcode;
        logic [2:0] funct3;
        logic [6:0] funct7;
        logic [11:0] funct12;
 
        opcode  = instr[6:0];
        funct3  = instr[14:12];
        funct7  = instr[31:25];
        funct12 = instr[31:20];
 
        case (opcode)
 
            
            // R-TYPE -> opcode = 7'b0110011
            7'b0110011: begin
                case (funct3)
                    3'b000: begin //se depende de funct7 para conocer si es sub o add 
                        if (funct7 == 7'b0100000)
                            return "SUB";
                        else
                            return "ADD";
                    end
                    3'b001: return "SLL";
                    3'b010: return "SLT";
                    3'b011: return "SLTU";
                    3'b100: return "XOR";
                    3'b101: begin //nuevamente se depende de funct7 para conocer si es sra o srl 
                        if (funct7 == 7'b0100000)
                            return "SRA";
                        else
                            return "SRL";
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
                        if (funct7 == 7'b0100000)
                            return "SRAI";
                        else
                            return "SRLI";
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
                if (funct3 == 3'b000) 
                    return "JALR";
                else                  
                    return "JALR_UNKNOWN";
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
                    3'b000: begin   // ECALL o EBREAK se distinguen por funct12
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
 
            // J-TYPE : JAL 
            7'b1101111: return "JAL";
 
            default: return "UNKNOWN_OPCODE";
 
        endcase
    endfunction
 
    
    /*
    * Esta parte se utiliza para probar que funcione correctamente el
    * decode_pkg
    * Para usarlo: decode_pkg::print_decoded_instr(instr_bits);
    */
   /*
    task print_decoded_instr(input logic [31:0] instr);
        $display("----------------------------------------------------");
        $display("Instruccion [31:0] : %08h  (%032b)", instr, instr);
        $display("  opcode  [6:0]    : %07b", instr[6:0]);
        $display("  funct3  [14:12]  : %03b",  instr[14:12]);
        $display("  funct7  [31:25]  : %07b", instr[31:25]);
        $display("  Tipo             : %s",   get_instr_type(instr).name());
        $display("  Instruccion      : %s",   get_instr_name(instr));
        $display("----------------------------------------------------");
    endtask
    */ 
 
endpackage
 
