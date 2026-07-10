/*
 * =============================================================================
 *
 * - File        : driver.sv
 * - Autor       : Rodrigo Sánchez Araya (C37259)
 * - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
 * - Fecha       : 5/12/2026
 *
 * - Descripción :
 *              Driver UVM encargado de recibir elementos de secuencia,
 *              construir la palabra de instrucción RISC-V correspondiente
 *              según su formato y escribirla en la memoria interna del DUT.
 *              Utiliza la interfaz virtual para conectarse con el ambiente
 *              de verificación y el paquete de instrucciones para codificar
 *              los campos de cada operación generada.
 *
 * =============================================================================
 */

import instr_pkg::*;

// Se crea la clase driver parametrizada con el item de secuencia:
class driver extends uvm_driver #(my_sequence_item);

    // Se registra la clase en la fábrica:
    `uvm_component_utils(driver)

    // Se declara la interfaz virtual utilizada para comúnicarse con el DUT:
    virtual ifc_riscv ifc_riscv_obj;

    // Se declara la palabra de instrucción que será escrita en memoria:
    logic [31:0] instr_wrd;

    // Se declaran las estructuras utilizadas para codificar instrucciones tipo R:
    instr_pkg::r_instr_t r_instr;

    // Se declara la estructura utilizada para codificar instrucciones tipo I aritméticas:
    instr_pkg::i_arithmetic_instr_t i_arithmetic_instr;

    // Se declara la estructura utilizada para codificar instrucciones tipo I de desplazamiento:
    instr_pkg::i_shift_instr_t i_shift_instr;

    // Se declara la estructura utilizada para codificar instrucciones tipo LOAD:
    instr_pkg::i_load_instr_t i_load_instr;

    // Se declara la estructura utilizada para codificar instrucciones tipo JALR:
    instr_pkg::i_jump_instr_t i_jump_instr;

    // Se declara la estructura utilizada para codificar instrucciones tipo STORE:
    instr_pkg::s_store_inst_t s_store_instr;

    // Se declara la estructura utilizada para codificar instrucciones tipo BRANCH:
    instr_pkg::b_branch_instr_t b_branch_instr;

    // Se declara la estructura utilizada para codificar instrucciones tipo U:
    instr_pkg::u_intr_t u_instr;

    // Se declara la estructura utilizada para codificar instrucciones tipo J:
    instr_pkg::j_instr_t j_instr;

    // Se crea el constructor:
    function new(
        string name = "DriverOBJ",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction

    // En build phase se obtiene la interfaz virtual desde la base de datos de UVM:
    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        // Se verifica que la interfaz virtual haya sido registrada correctamente:
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

    // En run phase se reciben las instrucciones generadas por la secuencia:
    virtual task run_phase(uvm_phase phase);

        // Se declara el item utilizado para recibir cada instrucción:
        my_sequence_item my_sequence_item_obj;

        super.run_phase(phase);

        // Se inicializa la bandera que indica si la memoria ya fue cargada:
        ifc_riscv_obj.mem_loaded = 1'b0;

        // Se inicializa el contador de instrucciones cargadas:
        ifc_riscv_obj.instr_count = 0;

        // Se limpia la memoria del DUT antes de cargar el programa generado:
        clear_mem();

        // Se procesan continuamente los items enviados por el sequencer:
        forever begin

            // Se obtiene el siguiente item de secuencia:
            seq_item_port.get_next_item(
                my_sequence_item_obj
            );

            // Se construye la instrucción y se escribe en la memoria del DUT:
            create_write_instr(
                my_sequence_item_obj
            );

            // Se actualiza el contador de instrucciones cargadas:
            ifc_riscv_obj.instr_count =
                my_sequence_item_obj.addr + 1;

            // Se indica que la memoria terminó de cargarse al recibir el último item real de la secuencia:
            if (my_sequence_item_obj.last_item) begin

                ifc_riscv_obj.mem_loaded = 1'b1;

            end

            // Se informa al sequencer que el item fue procesado:
            seq_item_port.item_done();

        end

    endtask

    // Se limpia la memoria interna del DUT escribiendo instrucciones NOP:
    function void clear_mem();

        // Se recorre toda la memoria interna del DUT:
        for (
            int i = 0;
            i < $size($root.tb_top.dut.MEM);
            i++
        ) begin

            // Se escribe una instrucción NOP en cada posición de memoria:
            $root.tb_top.dut.MEM[i] = 32'h00000013;

        end

    endfunction

    // Se construye la instrucción según el tipo recibido y se escribe en memoria:
    task create_write_instr(
        my_sequence_item my_sequence_item_obj
    );

        // Se inicializa la instrucción como NOP por defecto:
        instr_wrd = 32'h00000013;

        // Se seleccióna el formato de instrucción que debe codificarse:
        case (my_sequence_item_obj.instr_type)

            R_TYPE: begin

                // Se asigna el opcode común para las instrucciones tipo R:
                r_instr.opcode = 7'b0110011;

                // Se asignan los registros utilizados por la instrucción:
                r_instr.rd  = my_sequence_item_obj.rd;
                r_instr.rs1 = my_sequence_item_obj.rs1;
                r_instr.rs2 = my_sequence_item_obj.rs2;

                // Se seleccióna la operación tipo R específica:
                case (my_sequence_item_obj.r_instr)

                    ADD: begin

                        // Se asignan los campos de función de la instrucción ADD:
                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b000;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = r_instr;

                    end

                    SUB: begin

                        // Se asignan los campos de función de la instrucción SUB:
                        r_instr.funct7 = 7'b0100000;
                        r_instr.funct3 = 3'b000;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = r_instr;

                    end

                    SLL: begin

                        // Se asignan los campos de función de la instrucción SLL:
                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b001;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = r_instr;

                    end

                    SLT: begin

                        // Se asignan los campos de función de la instrucción SLT:
                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b010;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = r_instr;

                    end

                    SLTU: begin

                        // Se asignan los campos de función de la instrucción SLTU:
                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b011;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = r_instr;

                    end

                    XOR: begin

                        // Se asignan los campos de función de la instrucción XOR:
                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b100;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = r_instr;

                    end

                    SRL: begin

                        // Se asignan los campos de función de la instrucción SRL:
                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b101;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = r_instr;

                    end

                    SRA: begin

                        // Se asignan los campos de función de la instrucción SRA:
                        r_instr.funct7 = 7'b0100000;
                        r_instr.funct3 = 3'b101;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = r_instr;

                    end

                    OR: begin

                        // Se asignan los campos de función de la instrucción OR:
                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b110;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = r_instr;

                    end

                    AND: begin

                        // Se asignan los campos de función de la instrucción AND:
                        r_instr.funct7 = 7'b0000000;
                        r_instr.funct3 = 3'b111;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = r_instr;

                    end

                    default: begin

                        // Se mantiene una instrucción NOP si la operación no es válida:
                        instr_wrd = 32'h00000013;

                    end

                endcase

            end

            I_TYPE_ARITHMETIC: begin

                // Se asigna el opcode común para instrucciones tipo I aritméticas:
                i_arithmetic_instr.opcode = 7'b0010011;

                // Se asignan los campos comunes de la instrucción:
                i_arithmetic_instr.rd  = my_sequence_item_obj.rd;
                i_arithmetic_instr.rs1 = my_sequence_item_obj.rs1;
                i_arithmetic_instr.imm = my_sequence_item_obj.imm_i;

                // Se seleccióna la operación tipo I aritmética específica:
                case (my_sequence_item_obj.i_arith_instr)

                    ADDI: begin

                        // Se asigna el campo de función de la instrucción ADDI:
                        i_arithmetic_instr.funct3 = 3'b000;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = i_arithmetic_instr;

                    end

                    SLTI: begin

                        // Se asigna el campo de función de la instrucción SLTI:
                        i_arithmetic_instr.funct3 = 3'b010;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = i_arithmetic_instr;

                    end

                    SLTIU: begin

                        // Se asigna el campo de función de la instrucción SLTIU:
                        i_arithmetic_instr.funct3 = 3'b011;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = i_arithmetic_instr;

                    end

                    XORI: begin

                        // Se asigna el campo de función de la instrucción XORI:
                        i_arithmetic_instr.funct3 = 3'b100;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = i_arithmetic_instr;

                    end

                    ORI: begin

                        // Se asigna el campo de función de la instrucción ORI:
                        i_arithmetic_instr.funct3 = 3'b110;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = i_arithmetic_instr;

                    end

                    ANDI: begin

                        // Se asigna el campo de función de la instrucción ANDI:
                        i_arithmetic_instr.funct3 = 3'b111;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = i_arithmetic_instr;

                    end

                    default: begin

                        // Se mantiene una instrucción NOP si la operación no es válida:
                        instr_wrd = 32'h00000013;

                    end

                endcase

            end

            I_TYPE_SHIFT: begin

                // Se asigna el opcode común para instrucciones tipo I de desplazamiento:
                i_shift_instr.opcode = 7'b0010011;

                // Se asignan los campos comunes de la instrucción:
                i_shift_instr.shamt = my_sequence_item_obj.shamt;
                i_shift_instr.rs1   = my_sequence_item_obj.rs1;
                i_shift_instr.rd    = my_sequence_item_obj.rd;

                // Se seleccióna la operación tipo I de desplazamiento específica:
                case (my_sequence_item_obj.i_shift_instr)

                    SLLI: begin

                        // Se asignan los campos de función de la instrucción SLLI:
                        i_shift_instr.funct7 = 7'b0000000;
                        i_shift_instr.funct3 = 3'b001;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = i_shift_instr;

                    end

                    SRLI: begin

                        // Se asignan los campos de función de la instrucción SRLI:
                        i_shift_instr.funct7 = 7'b0000000;
                        i_shift_instr.funct3 = 3'b101;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = i_shift_instr;

                    end

                    SRAI: begin

                        // Se asignan los campos de función de la instrucción SRAI:
                        i_shift_instr.funct7 = 7'b0100000;
                        i_shift_instr.funct3 = 3'b101;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = i_shift_instr;

                    end

                    default: begin

                        // Se mantiene una instrucción NOP si la operación no es válida:
                        instr_wrd = 32'h00000013;

                    end

                endcase

            end

            I_TYPE_LOAD: begin

                // Se asigna el opcode común para instrucciones tipo LOAD:
                i_load_instr.opcode = 7'b0000011;

                // Se asignan los campos comunes de la instrucción:
                i_load_instr.rs1    = my_sequence_item_obj.rs1;
                i_load_instr.rd     = my_sequence_item_obj.rd;
                i_load_instr.offset = my_sequence_item_obj.imm_i;

                // Se seleccióna la operación tipo LOAD específica:
                case (my_sequence_item_obj.i_load_instr)

                    LB: begin

                        // Se asigna el campo de función de la instrucción LB:
                        i_load_instr.funct3 = 3'b000;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = i_load_instr;

                    end

                    LH: begin

                        // Se asigna el campo de función de la instrucción LH:
                        i_load_instr.funct3 = 3'b001;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = i_load_instr;

                    end

                    LW: begin

                        // Se asigna el campo de función de la instrucción LW:
                        i_load_instr.funct3 = 3'b010;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = i_load_instr;

                    end

                    LBU: begin

                        // Se asigna el campo de función de la instrucción LBU:
                        i_load_instr.funct3 = 3'b100;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = i_load_instr;

                    end

                    LHU: begin

                        // Se asigna el campo de función de la instrucción LHU:
                        i_load_instr.funct3 = 3'b101;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = i_load_instr;

                    end

                    default: begin

                        // Se mantiene una instrucción NOP si la operación no es válida:
                        instr_wrd = 32'h00000013;

                    end

                endcase

            end

            S_TYPE: begin

                // Se asigna el opcode común para instrucciones tipo STORE:
                s_store_instr.opcode = 7'b0100011;

                // Se asignan los campos del inmediato dividido y los registros fuente:
                s_store_instr.imm_11_5 = my_sequence_item_obj.imm_s[11:5];
                s_store_instr.imm_4_0  = my_sequence_item_obj.imm_s[4:0];
                s_store_instr.rs1      = my_sequence_item_obj.rs1;
                s_store_instr.rs2      = my_sequence_item_obj.rs2;

                // Se seleccióna la operación tipo STORE específica:
                case (my_sequence_item_obj.s_instr)

                    SB: begin

                        // Se asigna el campo de función de la instrucción SB:
                        s_store_instr.funct3 = 3'b000;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = s_store_instr;

                    end

                    SH: begin

                        // Se asigna el campo de función de la instrucción SH:
                        s_store_instr.funct3 = 3'b001;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = s_store_instr;

                    end

                    SW: begin

                        // Se asigna el campo de función de la instrucción SW:
                        s_store_instr.funct3 = 3'b010;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = s_store_instr;

                    end

                    default: begin

                        // Se mantiene una instrucción NOP si la operación no es válida:
                        instr_wrd = 32'h00000013;

                    end

                endcase

            end

            I_TYPE_JUMP: begin

                // Se asignan los campos comunes de la instrucción JALR:
                i_jump_instr.opcode = 7'b1100111;
                i_jump_instr.funct3 = 3'b000;
                i_jump_instr.offset = my_sequence_item_obj.imm_i;
                i_jump_instr.rs1    = my_sequence_item_obj.rs1;
                i_jump_instr.rd     = my_sequence_item_obj.rd;

                // Se seleccióna la operación tipo salto indirecto:
                case (my_sequence_item_obj.i_jump_instr)

                    JALR: begin

                        // Se construye la palabra final de instrucción:
                        instr_wrd = i_jump_instr;

                    end

                    default: begin

                        // Se mantiene una instrucción NOP si la operación no es válida:
                        instr_wrd = 32'h00000013;

                    end

                endcase

            end

            B_TYPE: begin

                // Se asigna el opcode común para instrucciones tipo BRANCH:
                b_branch_instr.opcode = 7'b1100011;

                // Se asignan los campos del inmediato dividido:
                b_branch_instr.imm_12   = my_sequence_item_obj.imm_b[12];
                b_branch_instr.imm_10_5 = my_sequence_item_obj.imm_b[10:5];
                b_branch_instr.imm_4_1  = my_sequence_item_obj.imm_b[4:1];
                b_branch_instr.imm_11   = my_sequence_item_obj.imm_b[11];

                // Se asignan los registros fuente de la comparación:
                b_branch_instr.rs1 = my_sequence_item_obj.rs1;
                b_branch_instr.rs2 = my_sequence_item_obj.rs2;

                // Se seleccióna la operación tipo BRANCH específica:
                case (my_sequence_item_obj.b_instr)

                    BEQ: begin

                        // Se asigna el campo de función de la instrucción BEQ:
                        b_branch_instr.funct3 = 3'b000;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = b_branch_instr;

                    end

                    BNE: begin

                        // Se asigna el campo de función de la instrucción BNE:
                        b_branch_instr.funct3 = 3'b001;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = b_branch_instr;

                    end

                    BLT: begin

                        // Se asigna el campo de función de la instrucción BLT:
                        b_branch_instr.funct3 = 3'b100;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = b_branch_instr;

                    end

                    BGE: begin

                        // Se asigna el campo de función de la instrucción BGE:
                        b_branch_instr.funct3 = 3'b101;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = b_branch_instr;

                    end

                    BLTU: begin

                        // Se asigna el campo de función de la instrucción BLTU:
                        b_branch_instr.funct3 = 3'b110;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = b_branch_instr;

                    end

                    BGEU: begin

                        // Se asigna el campo de función de la instrucción BGEU:
                        b_branch_instr.funct3 = 3'b111;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = b_branch_instr;

                    end

                    default: begin

                        // Se mantiene una instrucción NOP si la operación no es válida:
                        instr_wrd = 32'h00000013;

                    end

                endcase

            end

            U_TYPE: begin

                // Se asignan los campos comunes de las instrucciones tipo U:
                u_instr.imm_31_12 = my_sequence_item_obj.imm_u;
                u_instr.rd        = my_sequence_item_obj.rd;

                // Se seleccióna la operación tipo U específica:
                case (my_sequence_item_obj.u_instr)

                    LUI: begin

                        // Se asigna el opcode de la instrucción LUI:
                        u_instr.opcode = 7'b0110111;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = u_instr;

                    end

                    AUIPC: begin

                        // Se asigna el opcode de la instrucción AUIPC:
                        u_instr.opcode = 7'b0010111;

                        // Se construye la palabra final de instrucción:
                        instr_wrd = u_instr;

                    end

                    default: begin
                        // Se mantiene una instrucción NOP si la operación no es válida:
                        instr_wrd = 32'h00000013;
                    end
                endcase
            end

            J_TYPE: begin

                // Se asigna el opcode de la instrucción JAL:
                j_instr.opcode = 7'b1101111;

                // Se asignan los campos del inmediato dividido:
                j_instr.imm_20    = my_sequence_item_obj.imm_j[20];
                j_instr.imm_10_1  = my_sequence_item_obj.imm_j[10:1];
                j_instr.imm_11    = my_sequence_item_obj.imm_j[11];
                j_instr.imm_19_12 = my_sequence_item_obj.imm_j[19:12];

                // Se asigna el registro destino:
                j_instr.rd = my_sequence_item_obj.rd;

                // Se seleccióna la operación tipo J específica:
                case (my_sequence_item_obj.j_instr)

                    JAL: begin

                        // Se construye la palabra final de instrucción:
                        instr_wrd = j_instr;

                    end

                    default: begin

                        // Se mantiene una instrucción NOP si la operación no es válida:
                        instr_wrd = 32'h00000013;
                    end
                endcase

            end

          default: begin

                // Se mantiene una instrucción NOP si el tipo no está habilitado o no es válido:
                instr_wrd = 32'h00000013;

            end

        endcase

        // Se guarda la instrucción codificada dentro del item de secuencia:
        my_sequence_item_obj.instr = instr_wrd;

        // Se escribe directamente la instrucción en la memoria interna del DUT:
        $root.tb_top.dut.MEM[my_sequence_item_obj.addr] = instr_wrd;

    endtask

endclass
