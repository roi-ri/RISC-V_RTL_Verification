/*
* =============================================================================
*
* - File        : driver.sv
* - Autor       : Rodrigo Sanchez Araya (C37259)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 
* - Descripción : Driver encargado de generar instrucciones RISC-V a partir de
*                 los campos randomizados por instruction_stimulus, construir la
*                 palabra final de 32 bits mediante los structs definidos en
*                 instr_pkg y escribirla directamente en la memoria interna MEM
*                 del DUT darksocv. También incluye un task para inicializar
*                 la memoria con instrucciones NOP antes de cargar un nuevo
*                 programa. Actualmente solo se implementa la construcción de
*                 instrucciones R_TYPE e I_TYPE_ARITHMETIC; las demás familias
*                 de instrucciones quedan pendientes y, por ahora, se reemplazan
*                 por NOP (igual su ingreso esta restringido con el contrain
*                 en stimulus.sv pero por cualquier fallo, se mantiene asi). 
*
* =============================================================================
*
*/




import instr_pkg::*;
class riscv_driver;
    instruction_stimulus stimulus_obj; 
    scoreboard scoreboard_obj; 
    virtual ifc_ricsv ifc_riscv_obj; 


    logic [31:0] instr_wrd; 
    
    //Puntero a los structs de cada tipo de funcion
    // Actualmente el driver solo construye instrucciones R_TYPE e
    // I_TYPE_ARITHMETIC. Conforme se implementen más familias, se van a ir  agregando
    // los structs correspondientes y sus casos de construcción.
    instr_pkg::r_instr_t r_instr; 
    instr_pkg::i_arithmetic_instr_t i_arithmetic_instr;
    instr_pkg::i_shift_instr_t i_shift_instr; 
    instr_pkg::i_load_instr_t i_load_instr;
    instr_pkg::s_store_inst_t s_store_instr;
    instr_pkg::i_jump_instr_t i_jump_instr;


    function new (virtual ifc_ricsv ifc_riscv_obj, scoreboard scoreboard_obj);
        this.ifc_riscv_obj = ifc_riscv_obj;
        this.scoreboard_obj = scoreboard_obj;
    endfunction

    // Utilizar $root dar como la raiz de toda la gerarquia de simulacion
    function void clear_mem();
        for (int i = 0; i < $size($root.top.dut.MEM); i++) begin
        $root.top.dut.MEM[i] = 32'h00000013; // Esperar a ver como lo va a llamar luis, pero esto escribe NOP
        //Sirve para escribir directamente una
        // instruccion dentro de la memoria interna del DUT

        end
    endfunction


    task create_write_instr(input int addr);
        stimulus_obj = new();
      	void'(stimulus_obj.randomize()); 
        $display("Creando instruccion aleatoria");
        case (stimulus_obj.instr_type) 
            R_TYPE: begin
                //Definicion de campos por defecto para cada instruccion 
                r_instr.opcode   = 7'b0110011; 

                // Asignacion de las variables aleatorias
                // creadas en el stimulus.sv
                r_instr.rd       = stimulus_obj.rd;
                r_instr.rs1      = stimulus_obj.rs1;
                r_instr.rs2      = stimulus_obj.rs2; 
                case (stimulus_obj.r_instr)
                    ADD: begin
                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b000;
                        //construccion final de la
                        //instruccion
                         instr_wrd = r_instr; 
                        $display("Instruccion ADD creada: 0x%08h", instr_wrd);
                    end 
                    SUB: begin 
                        r_instr.funct7 = 7'b0100000;
                        r_instr.funct3 = 3'b000;
                        //construccion final de la
                        //instruccion
                         instr_wrd = r_instr; 
                        $display("Instruccion SUB creada: 0x%08h", instr_wrd);
                    end 
                    SLL:begin 
                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b001;
                        //construccion final de la
                        //instruccion
                         instr_wrd = r_instr; 
                        $display("Instruccion SLL creada: 0x%08h", instr_wrd);
                    end 
                    SLT: begin 
                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b010;
                        //construccion final de la
                        //instruccion
                         instr_wrd = r_instr; 
                        $display("Instruccion SLT creada: 0x%08h", instr_wrd); 
                    end 
                    SLTU: begin 
                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b011;
                        //construccion final de la
                        //instruccion
                        instr_wrd = r_instr; 
                        $display("Instruccion SLTU creada: 0x%08h", instr_wrd);
                    end 
                    XOR: begin
                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b100;
                        //construccion final de la
                        //instruccion
                         instr_wrd = r_instr; 
                        $display("Instruccion XOR creada: 0x%08h", instr_wrd);
                    end 
                    SRL: begin 
                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b101;
                        //construccion final de la
                        //instruccion
                         instr_wrd = r_instr; 
                        $display("Instruccion SRL creada: 0x%08h", instr_wrd);
                    end 
                    SRA: begin
                        r_instr.funct7 = 7'b0100000;
                        r_instr.funct3 = 3'b101;
                        //construccion final de la
                        //instruccion
                         instr_wrd = r_instr; 
                        $display("Instruccion SRA creada: 0x%08h", instr_wrd);
                    end
                    OR: begin
                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b110;
                        //construccion final de la
                        //instruccionss
                         instr_wrd = r_instr; 
                        $display("Instruccion OR creada: 0x%08h", instr_wrd);
                    end 
                    AND: begin
                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b111;
                        //construccion final de la
                        //instruccion
                         instr_wrd = r_instr; 
                        $display("Instruccion AND creada: 0x%08h", instr_wrd);
                    end
                    default: begin instr_wrd = 32'h00000013; // NOP: addi, x0, x0, 0
                        $display("Error en creacion de la instruccion");
                    end 
                endcase 
            end
 
                
            I_TYPE_ARITHMETIC: begin 
                //Definicion de campos por defecto para
                //cada instruccion 
                i_arithmetic_instr.opcode   = 7'b0010011; 

                // Asignacion de las variables aleatorias
                // creadas en el stimulus.sv
                i_arithmetic_instr.rd       = stimulus_obj.rd;
                i_arithmetic_instr.rs1      = stimulus_obj.rs1;
                i_arithmetic_instr.imm      = stimulus_obj.imm_i; 

            case (stimulus_obj.i_arith_instr) 
                ADDI: begin 
                    i_arithmetic_instr.funct3 = 3'b000;
                    //construccion final de la
                     //instruccion
                     instr_wrd = i_arithmetic_instr; 
                    $display("Instruccion ADDI creada: 0x%08h", instr_wrd);
                end 
                SLTI: begin 
                    i_arithmetic_instr.funct3 = 3'b010;
                    //construccion final de la
                    //instruccion
                    instr_wrd = i_arithmetic_instr; 
                    $display("Instruccion SLTI creada: 0x%08h", instr_wrd);
                end 
                SLTIU:begin
                    i_arithmetic_instr.funct3 = 3'b011;
                    //construccion final de la
                    //instruccion
                    instr_wrd = i_arithmetic_instr; 
                    $display("Instruccion ADDI creada: 0x%08h", instr_wrd);
                end
                XORI: begin 
                    i_arithmetic_instr.funct3 = 3'b100;
                    //construccion final de la
                    //instruccion
                    instr_wrd = i_arithmetic_instr; 
                    $display("Instruccion ADDI creada: 0x%08h", instr_wrd);
                end 
                ORI: begin 
                    i_arithmetic_instr.funct3 = 3'b110;
                    //construccion final de la
                    //instruccion
                    instr_wrd = i_arithmetic_instr; 
                    $display("Instruccion ADDI creada: 0x%08h", instr_wrd);
                end 
    ANDI: begin
                    i_arithmetic_instr.funct3 = 3'b111;
                    //construccion final de la
    //instruccion
                    instr_wrd = i_arithmetic_instr; 
                    $display("Instruccion ADDI creada: 0x%08h", instr_wrd);
                end 
                default: begin 
                    instr_wrd = 32'h00000013; // NOP: addi, x0, x0, 0
                    $display("Error en creacion de la instruccion");
                end
                endcase 
            end 
            
            I_TYPE_SHIFT: begin 
                i_shift_instr.opcode = 7'b0010011;
                i_shift_instr.shamt  = stimulus_obj.shamt; 
                i_shift_instr.rs1    = stimulus_obj.rs1; 
                i_shift_instr.rd     = stimulus_obj.rd; 

                case(stimulus_obj.i_shift_instr)
                    SLLI: begin
                        i_shift_instr.funct7 = 7'b0000000;
                        i_shift_instr.funct3 = 3'b001;
                        instr_wrd = i_shift_instr; 
                        $display("Instruccion SLLI creada: 0x%08h", instr_wrd);
                    end 
                    SRLI: begin 
                        i_shift_instr.funct7 = 7'b0000000;
                        i_shift_instr.funct3 = 3'b101;
                        instr_wrd = i_shift_instr; 
                        $display("Instruccion SRLI creada: 0x%08h", instr_wrd);
                    end
                    SRAI: begin
                        i_shift_instr.funct7 = 7'b0100000;
                        i_shift_instr.funct3 = 3'b101;
                        instr_wrd = i_shift_instr; 
                        $display("Instruccion SRAI creada: 0x%08h", instr_wrd);
                    end 
                default: begin 
                    instr_wrd = 32'h00000013; // NOP: addi, x0, x0, 0
                    $display("Error en creacion de la instruccion");
                end 
            endcase
            end

            I_TYPE_LOAD: begin 
                i_load_instr.opcode = 7'b0000011;
                i_load_instr.rs1 = stimulus_obj.rs1; 
                i_load_instr.rd = stimulus_obj.rd; 
                i_load_instr.offset = stimulus_obj.imm_i; 

                case(stimulus_obj.i_load_instr)
                    LB: begin
                        i_load_instr.funct3 = 3'b000;
                        instr_wrd = i_load_instr;
                         $display("Instruccion LB creada: 0x%08h", instr_wrd);
                    end 
                    LH: begin
                        i_load_instr.funct3 = 3'b001;
                        instr_wrd = i_load_instr;
                         $display("Instruccion LH creada: 0x%08h", instr_wrd);
                    end 
                    LW: begin
                        i_load_instr.funct3 = 3'b010;
                        instr_wrd = i_load_instr;
                         $display("Instruccion LW creada: 0x%08h", instr_wrd);
                    end 
                    LBU: begin
                        i_load_instr.funct3 = 3'b100;
                        instr_wrd = i_load_instr;
                         $display("Instruccion LBU creada: 0x%08h", instr_wrd);
                    end 
                    LHU: begin
                        i_load_instr.funct3 = 3'b101;
                        instr_wrd = i_load_instr;
                         $display("Instruccion LHU creada: 0x%08h", instr_wrd);
                    end 
                    default: begin 
                        instr_wrd = 32'h00000013; // NOP: addi, x0, x0, 0
                        $display("Error en creacion de la instruccion");
                    end 
                endcase 
            end 

            S_TYPE: begin 
                s_store_instr.opcode = 7'b0100011;
                s_store_instr.imm_11_5 = stimulus_obj.imm_s[11:5];
                s_store_instr.imm_4_0 = stimulus_obj.imm_s[4:0];
                s_store_instr.rs1 = stimulus_obj.rs1; 
                s_store_instr.rs2 = stimulus_obj.rs2; 
                case(stimulus_obj.s_instr)
                    SB: begin 
                        s_store_instr.funct3 = 3'b000;
                        instr_wrd = i_load_instr;
                         $display("Instruccion SB creada: 0x%08h", instr_wrd);
                    end 
                    SH: begin 
                        s_store_instr.funct3 = 3'b001;
                        instr_wrd = i_load_instr;
                         $display("Instruccion SH creada: 0x%08h", instr_wrd);
                    end
                    SW: begin 
                        s_store_instr.funct3 = 3'b010;
                        instr_wrd = i_load_instr;
                         $display("Instruccion SW creada: 0x%08h", instr_wrd);

                    end 
                    default: begin 
                        instr_wrd = 32'h00000013; // NOP: addi, x0, x0, 0
                        $display("Error en creacion de la instruccion");
                    end 
                endcase 
            end 
            I_TYPE_JUMP: begin 
                i_jump_instr.opcode = 7'b1100111;
                i_jump_instr.funct3 = 3'b000;
                i_jump_instr.offset = stimulus_obj.imm_i;
                i_jump_instr.rs1    = stimulus_obj.rs1;
                i_jump_instr.rd     = stimulus_obj.rd;

                case(stimulus_obj.i_jump_instr)
                    JALR: begin 
                        instr_wrd = i_jump_instr;
                        $display("Instruccion JALR creada: 0x%08h", instr_wrd);
                    end 
                    default: begin
                        instr_wrd = 32'h00000013;
                        $display("Error en creacion de instruccion JALR");
                    end
            endcase 

            end     



            // TODO: Implementar las familias restantes de instrucciones:
            // I_TYPE_LOAD, I_TYPE_MEMORY_SYSTEM -> (Ver si se separa esta en dos), I_TYPE_JUMP,
            // S_TYPE, B_TYPE, U_TYPE y J_TYPE. Mientras no estén soportadas,
            // se escribe una instrucción NOP para evitar insertar valores
            // inválidos en la memoria del DUT -> (aunque esto se esta limitando
            // en el constrain de stimulus.sv).
            default: begin
                instr_wrd = 32'h00000013;
                $display("Tipo de instruccion no implementado, escribiendo NOP");
            end 

            
        endcase 
        $root.top.dut.MEM[addr] = instr_wrd;
    endtask



endclass
