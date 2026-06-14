/*
* =============================================================================
*
* - File        : driver.sv
* - Autor       : Rodrigo Sanchez Araya (C37259)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción :Driver UVM encargado de recibir elementos de secuencia,
*                 construir la palabra de instrucción RISC-V correspondiente
*                 según su formato y escribirla en la memoria interna del DUT.
*                 Utiliza la interfaz virtual para conectarse con el ambiente
*                 de verificación y el paquete de instrucciones para codificar
*                 los campos de cada operación generada.
*
* =============================================================================
*/

import instr_pkg::*;

class driver extends uvm_driver #(my_sequence_item);

    //Registrando en la fabrica 
    `uvm_component_utils(driver)

    //Declaracion de la interfaz
    virtual ifc_riscv ifc_riscv_obj; 

    //creacion del constructor 
    function new(string name = "DriverOBJ", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    logic [31:0] instr_wrd;

    instr_pkg::r_instr_t            r_instr;
    instr_pkg::i_arithmetic_instr_t i_arithmetic_instr;
    instr_pkg::i_shift_instr_t      i_shift_instr;
    instr_pkg::i_load_instr_t       i_load_instr;
    instr_pkg::i_jump_instr_t       i_jump_instr;
    instr_pkg::s_store_inst_t       s_store_instr;
    instr_pkg::b_branch_instr_t     b_branch_instr;
    instr_pkg::u_intr_t             u_instr;
    instr_pkg::j_instr_t            j_instr;


    virtual function void build_phase(uvm_phase phase); 
        super.build_phase(phase); 

        if (!uvm_config_db #(virtual ifc_riscv)::get(
                this,
                "",
                "ifc_riscv_obj",
                ifc_riscv_obj
            )) begin

            `uvm_fatal(
                get_type_name(),
                "No se encontró la interfaz virtual"
            )

        end

    endfunction 


    virtual task run_phase(uvm_phase phase);

        my_sequence_item my_sequence_item_obj; // Esto establece un espacio en la memoria del tipo de elemento de la secuencia

        //Se define una secuencia        
        super.run_phase(phase);


        //
        ifc_riscv_obj.mem_loaded = 1'b0;

        //
        ifc_riscv_obj.instr_count = 0;

        //
        clear_mem();


        forever begin

            `uvm_info(
                get_type_name(),
                "Esperando dato del sequencer",
                UVM_MEDIUM
            )

            seq_item_port.get_next_item(
                my_sequence_item_obj
            );

            `uvm_info(
                get_type_name(),
                "Objeto recibido del sequencer:",
                UVM_MEDIUM
            )

            my_sequence_item_obj.print();

            create_write_instr(
                my_sequence_item_obj
            );


            //
            ifc_riscv_obj.instr_count =
                my_sequence_item_obj.addr + 1;


            //
          if ( my_sequence_item_obj.addr == (($size($root.tb_top.dut.MEM) / 16) - 1)) begin
                ifc_riscv_obj.mem_loaded = 1'b1;
            end


            seq_item_port.item_done();

        end

    endtask


    // Utilizar $root dar como la raiz de toda la gerarquia de simulacion
    function void clear_mem();

        for (
            int i = 0;
            i < $size($root.tb_top.dut.MEM);
            i++
        ) begin

            $root.tb_top.dut.MEM[i] = 32'h00000013; // Esperar a ver como lo va a llamar luis, pero esto escribe NOP

            //Sirve para escribir directamente una
            // instruccion dentro de la memoria interna del DUT

        end

    endfunction


    task create_write_instr(
        my_sequence_item my_sequence_item_obj
    ); 

        $display("Creando instruccion aleatoria");

        //
        instr_wrd = 32'h00000013;


        case (my_sequence_item_obj.instr_type) 

            R_TYPE: begin

                //Definicion de campos por defecto para cada instruccion 
                r_instr.opcode = 7'b0110011; 

                // Asignacion de las variables aleatorias
                // creadas en el stimulus.sv
                r_instr.rd  = my_sequence_item_obj.rd;
                r_instr.rs1 = my_sequence_item_obj.rs1;
                r_instr.rs2 = my_sequence_item_obj.rs2; 

                case (my_sequence_item_obj.r_instr)

                    ADD: begin

                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b000;

                        //construccion final de la
                        //instruccion
                        instr_wrd = r_instr; 

                        $display(
                            "Instruccion ADD creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    SUB: begin 

                        r_instr.funct7 = 7'b0100000;
                        r_instr.funct3 = 3'b000;

                        //construccion final de la
                        //instruccion
                        instr_wrd = r_instr; 

                        $display(
                            "Instruccion SUB creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    SLL: begin 

                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b001;

                        //construccion final de la
                        //instruccion
                        instr_wrd = r_instr; 

                        $display(
                            "Instruccion SLL creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    SLT: begin 

                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b010;

                        //construccion final de la
                        //instruccion
                        instr_wrd = r_instr; 

                        $display(
                            "Instruccion SLT creada: 0x%08h",
                            instr_wrd
                        ); 

                    end 


                    SLTU: begin 

                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b011;

                        //construccion final de la
                        //instruccion
                        instr_wrd = r_instr; 

                        $display(
                            "Instruccion SLTU creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    XOR: begin

                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b100;

                        //construccion final de la
                        //instruccion
                        instr_wrd = r_instr; 

                        $display(
                            "Instruccion XOR creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    SRL: begin 

                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b101;

                        //construccion final de la
                        //instruccion
                        instr_wrd = r_instr; 

                        $display(
                            "Instruccion SRL creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    SRA: begin

                        r_instr.funct7 = 7'b0100000;
                        r_instr.funct3 = 3'b101;

                        //construccion final de la
                        //instruccion
                        instr_wrd = r_instr; 

                        $display(
                            "Instruccion SRA creada: 0x%08h",
                            instr_wrd
                        );

                    end


                    OR: begin

                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b110;

                        //construccion final de la
                        //instruccionss
                        instr_wrd = r_instr; 

                        $display(
                            "Instruccion OR creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    AND: begin

                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b111;

                        //construccion final de la
                        //instruccion
                        instr_wrd = r_instr; 

                        $display(
                            "Instruccion AND creada: 0x%08h",
                            instr_wrd
                        );

                    end


                    default: begin

                        instr_wrd = 32'h00000013; // NOP: addi, x0, x0, 0

                        $display(
                            "Error en creacion de la instruccion"
                        );

                    end 

                endcase 

            end


            I_TYPE_ARITHMETIC: begin 

                //Definicion de campos por defecto para
                //cada instruccion 
                i_arithmetic_instr.opcode = 7'b0010011; 

                // Asignacion de las variables aleatorias
                // creadas en el stimulus.sv
                i_arithmetic_instr.rd  = my_sequence_item_obj.rd;
                i_arithmetic_instr.rs1 = my_sequence_item_obj.rs1;
                i_arithmetic_instr.imm = my_sequence_item_obj.imm_i; 

                case (my_sequence_item_obj.i_arith_instr) 

                    ADDI: begin 

                        i_arithmetic_instr.funct3 = 3'b000;

                        //construccion final de la
                        //instruccion
                        instr_wrd = i_arithmetic_instr; 

                        $display(
                            "Instruccion ADDI creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    SLTI: begin 

                        i_arithmetic_instr.funct3 = 3'b010;

                        //construccion final de la
                        //instruccion
                        instr_wrd = i_arithmetic_instr; 

                        $display(
                            "Instruccion SLTI creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    SLTIU: begin

                        i_arithmetic_instr.funct3 = 3'b011;

                        //construccion final de la
                        //instruccion
                        instr_wrd = i_arithmetic_instr; 

                        $display(
                            "Instruccion SLTIU creada: 0x%08h",
                            instr_wrd
                        );

                    end


                    XORI: begin 

                        i_arithmetic_instr.funct3 = 3'b100;

                        //construccion final de la
                        //instruccion
                        instr_wrd = i_arithmetic_instr; 

                        $display(
                            "Instruccion XORI creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    ORI: begin 

                        i_arithmetic_instr.funct3 = 3'b110;

                        //construccion final de la
                        //instruccion
                        instr_wrd = i_arithmetic_instr; 

                        $display(
                            "Instruccion ORI creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    ANDI: begin

                        i_arithmetic_instr.funct3 = 3'b111;

                        //construccion final de la
                        //instruccion
                        instr_wrd = i_arithmetic_instr; 

                        $display(
                            "Instruccion ANDI creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    default: begin 

                        instr_wrd = 32'h00000013; // NOP: addi, x0, x0, 0

                        $display(
                            "Error en creacion de la instruccion"
                        );

                    end

                endcase 

            end 
            

            I_TYPE_SHIFT: begin 

                i_shift_instr.opcode = 7'b0010011;
                i_shift_instr.shamt  = my_sequence_item_obj.shamt; 
                i_shift_instr.rs1    = my_sequence_item_obj.rs1; 
                i_shift_instr.rd     = my_sequence_item_obj.rd; 

                case (my_sequence_item_obj.i_shift_instr)

                    SLLI: begin

                        i_shift_instr.funct7 = 7'b0000000;
                        i_shift_instr.funct3 = 3'b001;
                        instr_wrd = i_shift_instr; 

                        $display(
                            "Instruccion SLLI creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    SRLI: begin 

                        i_shift_instr.funct7 = 7'b0000000;
                        i_shift_instr.funct3 = 3'b101;
                        instr_wrd = i_shift_instr; 

                        $display(
                            "Instruccion SRLI creada: 0x%08h",
                            instr_wrd
                        );

                    end


                    SRAI: begin

                        i_shift_instr.funct7 = 7'b0100000;
                        i_shift_instr.funct3 = 3'b101;
                        instr_wrd = i_shift_instr; 

                        $display(
                            "Instruccion SRAI creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    default: begin 

                        instr_wrd = 32'h00000013; // NOP: addi, x0, x0, 0

                        $display(
                            "Error en creacion de la instruccion"
                        );

                    end 

                endcase

            end


            I_TYPE_LOAD: begin 

                i_load_instr.opcode = 7'b0000011;
                i_load_instr.rs1    = my_sequence_item_obj.rs1; 
                i_load_instr.rd     = my_sequence_item_obj.rd; 
                i_load_instr.offset = my_sequence_item_obj.imm_i; 

                case (my_sequence_item_obj.i_load_instr)

                    LB: begin

                        i_load_instr.funct3 = 3'b000;
                        instr_wrd = i_load_instr;

                        $display(
                            "Instruccion LB creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    LH: begin

                        i_load_instr.funct3 = 3'b001;
                        instr_wrd = i_load_instr;

                        $display(
                            "Instruccion LH creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    LW: begin

                        i_load_instr.funct3 = 3'b010;
                        instr_wrd = i_load_instr;

                        $display(
                            "Instruccion LW creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    LBU: begin

                        i_load_instr.funct3 = 3'b100;
                        instr_wrd = i_load_instr;

                        $display(
                            "Instruccion LBU creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    LHU: begin

                        i_load_instr.funct3 = 3'b101;
                        instr_wrd = i_load_instr;

                        $display(
                            "Instruccion LHU creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    default: begin 

                        instr_wrd = 32'h00000013; // NOP: addi, x0, x0, 0

                        $display(
                            "Error en creacion de la instruccion"
                        );

                    end 

                endcase 

            end 


            S_TYPE: begin 

                s_store_instr.opcode   = 7'b0100011;
                s_store_instr.imm_11_5 = my_sequence_item_obj.imm_s[11:5];
                s_store_instr.imm_4_0  = my_sequence_item_obj.imm_s[4:0];
                s_store_instr.rs1      = my_sequence_item_obj.rs1; 
                s_store_instr.rs2      = my_sequence_item_obj.rs2; 

                case (my_sequence_item_obj.s_instr)

                    SB: begin 

                        s_store_instr.funct3 = 3'b000;
                        instr_wrd = s_store_instr;

                        $display(
                            "Instruccion SB creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    SH: begin 

                        s_store_instr.funct3 = 3'b001;
                        instr_wrd = s_store_instr;

                        $display(
                            "Instruccion SH creada: 0x%08h",
                            instr_wrd
                        );

                    end


                    SW: begin 

                        s_store_instr.funct3 = 3'b010;
                        instr_wrd = s_store_instr;

                        $display(
                            "Instruccion SW creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    default: begin 

                        instr_wrd = 32'h00000013; // NOP: addi, x0, x0, 0

                        $display(
                            "Error en creacion de la instruccion"
                        );

                    end 

                endcase 

            end 


            I_TYPE_JUMP: begin 

                i_jump_instr.opcode = 7'b1100111;
                i_jump_instr.funct3 = 3'b000;
                i_jump_instr.offset = my_sequence_item_obj.imm_i;
                i_jump_instr.rs1    = my_sequence_item_obj.rs1;
                i_jump_instr.rd     = my_sequence_item_obj.rd;

                case (my_sequence_item_obj.i_jump_instr)

                    JALR: begin 

                        instr_wrd = i_jump_instr;

                        $display(
                            "Instruccion JALR creada: 0x%08h",
                            instr_wrd
                        );

                    end 


                    default: begin

                        instr_wrd = 32'h00000013;

                        $display(
                            "Error en creacion de instruccion JALR"
                        );

                    end

                endcase 

            end     


            B_TYPE: begin

                b_branch_instr.opcode   = 7'b1100011;
                b_branch_instr.imm_12   = my_sequence_item_obj.imm_b[12];
                b_branch_instr.imm_10_5 = my_sequence_item_obj.imm_b[10:5];
                b_branch_instr.imm_4_1  = my_sequence_item_obj.imm_b[4:1];
                b_branch_instr.imm_11   = my_sequence_item_obj.imm_b[11];
                b_branch_instr.rs1      = my_sequence_item_obj.rs1;
                b_branch_instr.rs2      = my_sequence_item_obj.rs2;

                case (my_sequence_item_obj.b_instr)

                    BEQ: begin

                        b_branch_instr.funct3 = 3'b000;
                        instr_wrd = b_branch_instr;

                        $display(
                            "Instruccion BEQ creada: 0x%08h",
                            instr_wrd
                        );

                    end


                    BNE: begin

                        b_branch_instr.funct3 = 3'b001;
                        instr_wrd = b_branch_instr;

                        $display(
                            "Instruccion BNE creada: 0x%08h",
                            instr_wrd
                        );

                    end


                    BLT: begin

                        b_branch_instr.funct3 = 3'b100;
                        instr_wrd = b_branch_instr;

                        $display(
                            "Instruccion BLT creada: 0x%08h",
                            instr_wrd
                        );

                    end


                    BGE: begin

                        b_branch_instr.funct3 = 3'b101;
                        instr_wrd = b_branch_instr;

                        $display(
                            "Instruccion BGE creada: 0x%08h",
                            instr_wrd
                        );

                    end


                    BLTU: begin

                        b_branch_instr.funct3 = 3'b110;
                        instr_wrd = b_branch_instr;

                        $display(
                            "Instruccion BLTU creada: 0x%08h",
                            instr_wrd
                        );

                    end


                    BGEU: begin

                        b_branch_instr.funct3 = 3'b111;
                        instr_wrd = b_branch_instr;

                        $display(
                            "Instruccion BGEU creada: 0x%08h",
                            instr_wrd
                        );

                    end


                    default: begin

                        instr_wrd = 32'h00000013; // NOP: addi, x0, x0, 0

                        $display(
                            "Error en creacion de la instruccion"
                        );

                    end

                endcase

            end


            U_TYPE: begin

                u_instr.imm_31_12 = my_sequence_item_obj.imm_u;
                u_instr.rd        = my_sequence_item_obj.rd;

                case (my_sequence_item_obj.u_instr)

                    LUI: begin

                        u_instr.opcode = 7'b0110111;
                        instr_wrd = u_instr;

                        $display(
                            "Instruccion LUI creada: 0x%08h",
                            instr_wrd
                        );

                    end


                    default: begin

                        instr_wrd = 32'h00000013; // NOP: addi, x0, x0, 0

                        $display(
                            "Error en creacion de la instruccion"
                        );

                    end

                endcase

            end


            J_TYPE: begin

                j_instr.opcode    = 7'b1101111;
                j_instr.imm_20    = my_sequence_item_obj.imm_j[20];
                j_instr.imm_10_1  = my_sequence_item_obj.imm_j[10:1];
                j_instr.imm_11    = my_sequence_item_obj.imm_j[11];
                j_instr.imm_19_12 = my_sequence_item_obj.imm_j[19:12];
                j_instr.rd        = my_sequence_item_obj.rd;

                case (my_sequence_item_obj.j_instr)

                    JAL: begin

                        instr_wrd = j_instr;

                        $display(
                            "Instruccion JAL creada: 0x%08h",
                            instr_wrd
                        );

                    end


                    default: begin

                        instr_wrd = 32'h00000013; // NOP: addi, x0, x0, 0

                        $display(
                            "Error en creacion de la instruccion"
                        );

                    end

                endcase

            end


            // Las familias implementadas se habilitan desde instr_type_soportadas_c.
            // En el constrain de sequencer "instr_type_soportadas_c"
            // se pueden habilitar y desabilitar tipos de
            // instrucciones segun corresponda
            default: begin

                instr_wrd = 32'h00000013;

                $display(
                    "Tipo de instruccion no implementado, escribiendo NOP"
                );

            end 

        endcase 

        //
        my_sequence_item_obj.instr = instr_wrd;

      	$root.tb_top.dut.MEM[ my_sequence_item_obj.addr] = instr_wrd;

    endtask

endclass
