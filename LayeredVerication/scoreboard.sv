/*
*
* =============================================================================
*
* - File        : scoreboard.sv
* - Autor       : Brandon Jiménez Campos (C33972)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 06-5-2026
* - Descripción : Scoreboard encargado de generar los valores de referencia
*                 para que el checker pueda comparar los valores esperados del 
*                 RISC-V para verificar su correcto funcionamiento
*
* =============================================================================
*/ 
//`include "instr_pkg.sv"
//`include "decode_pkg.sv" 
//se deben de instanciar en el testbench estos pkg

class scoreboard;

    import instr_pkg::*;
    import decode_pkg::*;

    //struct para enviar datos con información relevante al monitor
    typedef struct {
            logic       [31:0]  res_ref;
            logic       [4:0]   rd;
            string              instr_name;
            instr_set           instr_type;
            logic       [31:0]  pc_ref;
            logic               branch; // 1 si se tomo el salto, 0 si no
            logic       [31:0]  pc_ref_next; // el valor de pc siguiente, util para ver si se cumple el salto 
        } result;


        //se crea el struct en donde se van a guardar los datos
        result reference;

        //queue para almacenar los resultados
        result res_mem[$];
        //se crea una memoria de registros para el scoreboard
        logic       [31:0]      reg_mem [31:0];
        logic                   pc_4; //señal que indica si la pc aumenta en 4 o no
        
        //constructor
        function new();
            this.reference.pc_ref_next      = '0;
            this.reference.pc_ref           = '0;
            this.reference.branch           = '0;
            this.reference.res_ref          = '0;
            this.reference.rd               = '0;
            this.reference.instr_name       = "";
            this.reference.instr_type       = R_TYPE;
            this.pc_4                       =  0; 
            for (int i = 0; i < 32; i++) begin
                this.reg_mem[i]             = '0;
            end
        endfunction

        //funcion para calcular el resultado esperado
        function void ref_model(logic [31:0] instr, logic rst); 

            reference.branch        = '0;
            pc_4                    =  0;
            reference.res_ref       = '0;
            reference.rd            = '0;
            reference.instr_name    = "";
            reference.instr_type    = R_TYPE;
            reference.pc_ref        = reference.pc_ref_next; // colocar el pc actual al inicio por los JAL
            



            if (rst) begin 
                reference.res_ref       = '0;
                reference.rd            = '0;
                reference.instr_name    = "";
                reference.instr_type    = R_TYPE;
                reference.pc_ref        = '0;
                reference.pc_ref_next   = '0;
                pc_4                    =  0;
                reference.branch        = '0;
                res_mem.delete(); //se borra el queue 
                return;
            end 
            else begin

                //Colocar el tipo de instruccion y el nombre utilizando funciones
                //del decode 
                reference.instr_type        = get_instr_type(instr);
                reference.instr_name        = get_instr_name(instr);

                case (reference.instr_type)
                    R_TYPE: begin
                        //se asigna los valores correspondientes según una
                        //instrucción R-TYPE
                        logic   [4:0]   rs2;
                        logic   [4:0]   rs1;
                        logic   [31:0]  rs2_val;
                        logic   [31:0]  rs1_val;

                        rs2             = instr[24:20];
                        rs1             = instr[19:15];
                        reference.rd    = instr[11:7];

                        //se leen los registros del modelo de referencia
                        if (rs1 == 5'd0) begin
                            rs1_val = 32'd0;
                        end
                        else begin
                            rs1_val = reg_mem[rs1];
                        end

                        if (rs2 == 5'd0) begin
                            rs2_val = 32'd0;
                        end
                        else begin
                            rs2_val = reg_mem[rs2];
                        end

                        //según el nombre de la instrucción se realiza la
                        //operacion
                        case (reference.instr_name)
                            "ADD": begin
                                reference.res_ref = rs1_val + rs2_val;
                            end

                            "SUB": begin
                                reference.res_ref = rs1_val - rs2_val;
                            end

                            "SLL": begin
                                reference.res_ref = rs1_val << rs2_val[4:0];
                            end

                            "SLT": begin
                                if ($signed(rs1_val) < $signed(rs2_val)) begin
                                    reference.res_ref = 32'd1;
                                end
                                else begin
                                    reference.res_ref = 32'd0;
                                end
                            end

                            "SLTU": begin
                                if (rs1_val < rs2_val) begin
                                    reference.res_ref = 32'd1;
                                end
                                else begin
                                    reference.res_ref = 32'd0;
                                end
                            end

                            "XOR": begin
                                reference.res_ref = rs1_val ^ rs2_val;
                            end

                            "SRL": begin
                                reference.res_ref = rs1_val >> rs2_val[4:0];
                            end

                            "SRA": begin
                                reference.res_ref = $signed(rs1_val) >>> rs2_val[4:0];
                            end

                            "OR": begin
                                reference.res_ref = rs1_val | rs2_val;
                            end

                            "AND": begin
                                reference.res_ref = rs1_val & rs2_val;
                            end

                            default: begin
                                
                            end
                        endcase //fin case según función R-TYPE

                        //se actualiza el banco de registros de referencia
                        //x0 no se modifica porque siempre debe ser cero
                        if (reference.rd != 5'd0) begin
                            reg_mem[reference.rd] = reference.res_ref;
                        end

                        pc_4 = 1;
                    end //fin case de instrucciones R-TYPE


                    I_TYPE_ARITHMETIC: begin 
                        //se asigna los valores correspondientes según una
                        //instrucción I_TYPE 
                        logic signed [31:0]  imm;
                        logic        [4:0]   rs1;
                        logic        [31:0]  rs1_val;
                        
                        //se debe de extender el signo para lograr un
                        //inmediato de 32 bits, por esto se coloca el 20, ya
                        //que el bit 31 es el que se extiende
                        imm                 = {{20{instr[31]}}, instr[31:20]}; 
                        rs1                 = instr[19:15];
                        reference.rd        = instr[11:7];

                        //se lee el registro fuente
                        if (rs1 == 5'd0) begin
                            rs1_val = 32'd0;
                        end
                        else begin
                            rs1_val = reg_mem[rs1];
                        end

                        case (reference.instr_name)
                            "ADDI": begin 
                                reference.res_ref = rs1_val + imm;
                            end

                            "SLTI": begin 
                                if ($signed(rs1_val) < imm) begin
                                    reference.res_ref = 32'd1;
                                end
                                else begin
                                    reference.res_ref = 32'd0;
                                end
                            end

                            "SLTIU": begin 
                                if (rs1_val < $unsigned(imm)) begin
                                    reference.res_ref = 32'd1;
                                end
                                else begin
                                    reference.res_ref = 32'd0;
                                end
                            end

                            "XORI": begin 
                                reference.res_ref = rs1_val ^ imm;
                            end

                            "ORI": begin 
                                reference.res_ref = rs1_val | imm;
                            end

                            "ANDI": begin 
                                reference.res_ref = rs1_val & imm;
                            end

                            default: begin 
                                
                            end 
                        endcase

                        //se actualiza el banco de registros de referencia
                        //x0 no se modifica porque siempre debe ser cero
                        if (reference.rd != 5'd0) begin
                            reg_mem[reference.rd] = reference.res_ref;
                        end

                        pc_4 = 1;
                    end // fin case de instrucciones I_TYPE_ARITHMETIC


                    I_TYPE_SHIFT: begin 
                        logic       [11:0]  imm;
                        logic       [4:0]   rs1;
                        logic       [4:0]   shamt;
                        logic       [31:0]  rs1_val;

                        imm             = instr[31:20]; //no se expande el imm, debido a que este tiene shampt y es diferente
                        rs1             = instr[19:15];
                        reference.rd    = instr[11:7];
                        shamt           = instr[24:20]; //solo para las operaciones SLLI, SRLI y SRAI 

                        //se lee el registro fuente
                        if (rs1 == 5'd0) begin
                            rs1_val = 32'd0;
                        end
                        else begin
                            rs1_val = reg_mem[rs1];
                        end

                        case(reference.instr_name) 
                            "SLLI":begin 
                                reference.res_ref = rs1_val << shamt; // desplazamiento hacia la izquierda
                            end

                            "SRLI":begin 
                                reference.res_ref = rs1_val >> shamt; // es lógico, no mantiene signo (>>)
                            end

                            "SRAI":begin 
                                reference.res_ref = $signed(rs1_val) >>> shamt; // es aritmético, por lo que mantiene signo (>>>)
                            end

                            default: begin 
                            end
                        endcase // fin case para las operaciones de la instruccion I_TYPE_SHIFT 

                        //se actualiza el banco de registros de referencia
                        //x0 no se modifica porque siempre debe ser cero
                        if (reference.rd != 5'd0) begin
                            reg_mem[reference.rd] = reference.res_ref;
                        end

                        pc_4 = 1;
                    end // fin case instruccion I_TYPE_SHIFT


                    I_TYPE_LOAD: begin 
                        logic signed [31:0]  imm;
                        logic        [4:0]   rs1;
                        logic        [31:0]  rs1_val;
                        logic        [31:0]  addr;

                        imm                 = {{20{instr[31]}}, instr[31:20]};
                        rs1                 = instr[19:15];
                        reference.rd        = instr[11:7];

                        //falta implementación

                        pc_4 = 1;
                    end // fin case instruccion I_TYPE_LOAD


                    I_TYPE_JUMP: begin 
                        logic signed [31:0]  imm;
                        logic        [4:0]   rs1;
                        logic        [31:0]  rs1_val;

                        imm                 = {{20{instr[31]}}, instr[31:20]};
                        rs1                 = instr[19:15];
                        reference.rd        = instr[11:7];

                       //falta implementar
                       pc_4 = 1; //en realidad aquí no se utiliza el pc_4, porque se usa un imm para saltar
                                //es sólo para que no se quede pegado
                    end 


                    I_TYPE_MEMORY_SYSTEM: begin 
                        //falta implementar 

                        pc_4 = 1;
                    end // fin case instruccion I_TYPE_MEMORY_SYSTEM


                    S_TYPE: begin 
                        logic        [31:0]  imm;
                        logic        [4:0]   rs1;
                        logic        [4:0]   rs2;
                        logic        [31:0]  rs1_val;
                        logic        [31:0]  rs2_val;
                        logic        [31:0]  addr;
                       //falta implementarlo 

                        pc_4 = 1;
                    end // fin case de instrucciones S_TYPE


                    B_TYPE: begin 
                        logic signed [31:0]  imm;
                        logic        [4:0]   rs1;
                        logic        [4:0]   rs2;
                        logic        [31:0]  rs1_val;
                        logic        [31:0]  rs2_val;

                        imm                 = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
                        rs1                 = instr[19:15];
                        rs2                 = instr[24:20];
                        reference.rd        = '0;

                        //se leen los registros fuente
                        if (rs1 == 5'd0) begin
                            rs1_val = 32'd0;
                        end
                        else begin
                            rs1_val = reg_mem[rs1];
                        end

                        if (rs2 == 5'd0) begin
                            rs2_val = 32'd0;
                        end
                        else begin
                            rs2_val = reg_mem[rs2];
                        end

                        reference.branch            = 1'b0;

                        case (reference.instr_name)
                            "BEQ": begin
                                if (rs1_val == rs2_val) begin
                                    reference.branch = 1'b1;
                                end
                                else begin
                                    reference.branch = 1'b0;
                                end
                            end

                            "BNE": begin
                                if (rs1_val != rs2_val) begin
                                    reference.branch = 1'b1;
                                end
                                else begin
                                    reference.branch = 1'b0;
                                end
                            end

                            "BLT": begin
                                if ($signed(rs1_val) < $signed(rs2_val)) begin
                                    reference.branch = 1'b1;
                                end
                                else begin
                                    reference.branch = 1'b0;
                                end
                            end

                            "BGE": begin
                                if ($signed(rs1_val) >= $signed(rs2_val)) begin
                                    reference.branch = 1'b1;
                                end
                                else begin
                                    reference.branch = 1'b0;
                                end
                            end

                            "BLTU": begin
                                if (rs1_val < rs2_val) begin
                                    reference.branch = 1'b1;
                                end
                                else begin
                                    reference.branch = 1'b0;
                                end
                            end

                            "BGEU": begin
                                if (rs1_val >= rs2_val) begin
                                    reference.branch = 1'b1;
                                end
                                else begin
                                    reference.branch = 1'b0;
                                end
                            end

                            default: begin
                                
                            end
                        endcase

                        //en este tipo lo que se debe de evaluar es si branch
                        //es igual, por lo que res_ref se deja de lado
                        reference.res_ref = '0;

                        if (reference.branch) begin
                            reference.pc_ref_next = reference.pc_ref + imm;
                            pc_4 = 0;
                        end
                        else begin
                            pc_4 = 1;
                        end
                    end // fin case de instrucciones B_TYPE


                    U_TYPE: begin 
                        logic       [31:0]  imm;

                        imm                 = {instr[31:12], 12'b0};
                        reference.rd        = instr[11:7];

                        case (reference.instr_name)
                            "LUI": begin
                                reference.res_ref = imm;
                            end

                            "AUIPC": begin
                                //falta implementar 
                            end

                            default: begin
                                
                            end
                        endcase

                        //se actualiza el banco de registros de referencia
                        //x0 no se modifica porque siempre debe ser cero
                        if (reference.rd != 5'd0) begin
                            reg_mem[reference.rd] = reference.res_ref;
                        end

                        pc_4 = 1;
                    end // fin case de instrucciones U_TYPE


                    J_TYPE: begin 
                        logic signed [31:0]  imm;
                        //falta implementar 
                        pc_4 = 1;
                    end // fin case de instrucciones J_TYPE

                    default: begin
                        
                        pc_4 = 1;
                    end
                endcase //fin case de tipo de instrucciones
 
                if (pc_4) begin 
                    reference.pc_ref_next = reference.pc_ref + 32'd4;
                end 

                res_mem.push_back(reference); //se guarda el resultado de referencia en el último lugar

            end //fin del else 
        endfunction
        
        

endclass
