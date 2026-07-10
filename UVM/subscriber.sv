/*
* =============================================================================
*
* - File        : subscriber.sv
* - Autor       : Brandon Jimenez Campos (C33972)
* - Curso       : Verificacion Funcional del Diseno de Circuitos Integrados
* - Fecha       : 06-5-2026
* - Descripcion : Subscriber encargado de recolectar la cobertura funcional
*                 de las instrucciones generadas para el RISC-V.
*
* =============================================================================
*/

import instr_pkg::*;
import instruction_selector_pkg::*;


// Se crea el subscriber que recibe las instrucciones observadas por el monitor:
class subscriber extends uvm_subscriber #(my_sequence_item);

    `uvm_component_utils(subscriber)


    // Identificadores internos usados para crear bins y cruces por instruccion:
    localparam int OP_ADD   = 0;
    localparam int OP_SUB   = 1;
    localparam int OP_SLL   = 2;
    localparam int OP_SLT   = 3;
    localparam int OP_SLTU  = 4;
    localparam int OP_XOR   = 5;
    localparam int OP_SRL   = 6;
    localparam int OP_SRA   = 7;
    localparam int OP_OR    = 8;
    localparam int OP_AND   = 9;
    localparam int OP_ADDI  = 10;
    localparam int OP_SLTI  = 11;
    localparam int OP_SLTIU = 12;
    localparam int OP_XORI  = 13;
    localparam int OP_ORI   = 14;
    localparam int OP_ANDI  = 15;
    localparam int OP_SLLI  = 16;
    localparam int OP_SRLI  = 17;
    localparam int OP_SRAI  = 18;
    localparam int OP_LUI   = 19;
    localparam int OP_AUIPC = 20;
    localparam int OP_LW    = 21;
    localparam int OP_SW    = 22;
    localparam int OP_BEQ   = 23;
    localparam int OP_BNE   = 24;
    localparam int OP_BLT   = 25;
    localparam int OP_BGE   = 26;
    localparam int OP_BLTU  = 27;
    localparam int OP_BGEU  = 28;
    localparam int OP_JAL   = 29;
    localparam int OP_JALR  = 30;
    localparam int OP_OTHER = 31;
    localparam int OP_LB    = 32;
    localparam int OP_LH    = 33;
    localparam int OP_LBU   = 34;
    localparam int OP_LHU   = 35;
    localparam int OP_SB    = 36;
    localparam int OP_SH    = 37;


    // Banderas para indicar cuales covergroups fueron creados segun el selector:
    bit cov_r_enable;
    bit cov_i_arit_enable;
    bit cov_i_shift_enable;
    bit cov_u_enable;
    bit cov_load_enable;
    bit cov_store_enable;
    bit cov_branch_enable;
    bit cov_jump_enable;
    bit cov_mixed_enable;
    bit cov_shift_enable;
    bit cov_immediate_enable;


    // Cobertura funcional para instrucciones R:
    covergroup R_types with function sample(
        logic [6:0] opcode,
        int         op_id,
        logic [4:0] rd,
        logic [4:0] rs1,
        logic [4:0] rs2,
        logic [2:0] zero_use
    );

        option.per_instance = 1;

        cp_r_opcode: coverpoint opcode {
            bins r_opcode = {7'b0110011};
        }

        cp_r_function: coverpoint op_id {
            bins add  = {OP_ADD};
            bins sub  = {OP_SUB};
            bins sll  = {OP_SLL};
            bins slt  = {OP_SLT};
            bins sltu = {OP_SLTU};
            bins xor_ = {OP_XOR};
            bins srl  = {OP_SRL};
            bins sra  = {OP_SRA};
            bins or_  = {OP_OR};
            bins and_ = {OP_AND};
        }

        cp_r_rd: coverpoint rd {
            bins x0 = {5'd0};
            bins x1_to_x7 = {[5'd1:5'd7]};
            bins x8_to_x15 = {[5'd8:5'd15]};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_r_rs1: coverpoint rs1 {
            bins x0 = {5'd0};
            bins x1_to_x7 = {[5'd1:5'd7]};
            bins x8_to_x15 = {[5'd8:5'd15]};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_r_rs2: coverpoint rs2 {
            bins x0 = {5'd0};
            bins x1_to_x7 = {[5'd1:5'd7]};
            bins x8_to_x15 = {[5'd8:5'd15]};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_r_zero_use: coverpoint zero_use {
            bins no_zero = {3'b000};
            bins rd_zero = {3'b100};
            bins rs1_zero = {3'b010};
            bins rs2_zero = {3'b001};
            bins multiple_zero = {[3'b011:3'b111]};
        }

        cross_r_function_rd: cross cp_r_function, cp_r_rd;
        cross_r_function_rs1: cross cp_r_function, cp_r_rs1;
        cross_r_function_rs2: cross cp_r_function, cp_r_rs2;

    endgroup


    // Cobertura funcional para instrucciones I aritméticas:
    covergroup I_ARIT_types with function sample(
        logic [6:0]  opcode,
        int          op_id,
        logic [4:0]  rd,
        logic [4:0]  rs1,
        logic [11:0] imm_i
    );

        option.per_instance = 1;

        cp_i_opcode: coverpoint opcode {
            bins i_arithmetic_shift = {7'b0010011};
        }

        cp_i_arit_function: coverpoint op_id {
            bins addi  = {OP_ADDI};
            bins slti  = {OP_SLTI};
            bins sltiu = {OP_SLTIU};
            bins xori  = {OP_XORI};
            bins ori   = {OP_ORI};
            bins andi  = {OP_ANDI};
        }

        cp_i_rd: coverpoint rd {
            bins x0 = {5'd0};
            bins x1_to_x7 = {[5'd1:5'd7]};
            bins x8_to_x15 = {[5'd8:5'd15]};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_i_rs1: coverpoint rs1 {
            bins x0 = {5'd0};
            bins x1_to_x7 = {[5'd1:5'd7]};
            bins x8_to_x15 = {[5'd8:5'd15]};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_i_immediate: coverpoint imm_i {
            bins zero = {12'h000};
            bins positive = {[12'h001:12'h7ff]};
            bins negative = {[12'h800:12'hfff]};
        }

        cross_i_arit_function_rd: cross cp_i_arit_function, cp_i_rd;
        cross_i_arit_function_rs1: cross cp_i_arit_function, cp_i_rs1;
        cross_i_arit_function_immediate: cross cp_i_arit_function, cp_i_immediate;

    endgroup


    // Cobertura funcional para instrucciones I de desplazamiento:
    covergroup I_SHIFT_types with function sample(
        logic [6:0] opcode,
        int         op_id,
        logic [4:0] rd,
        logic [4:0] rs1,
        logic [4:0] shamt
    );

        option.per_instance = 1;

        cp_i_shift_opcode: coverpoint opcode {
            bins i_shift = {7'b0010011};
        }

        cp_i_shift_function: coverpoint op_id {
            bins slli = {OP_SLLI};
            bins srli = {OP_SRLI};
            bins srai = {OP_SRAI};
        }

        cp_i_shift_rd: coverpoint rd {
            bins x0 = {5'd0};
            bins x1_to_x7 = {[5'd1:5'd7]};
            bins x8_to_x15 = {[5'd8:5'd15]};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_i_shift_rs1: coverpoint rs1 {
            bins x0 = {5'd0};
            bins x1_to_x7 = {[5'd1:5'd7]};
            bins x8_to_x15 = {[5'd8:5'd15]};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_i_shift_shamt: coverpoint shamt {
            bins zero = {5'd0};
            bins low = {[5'd1:5'd7]};
            bins mid = {[5'd8:5'd15]};
            bins high = {[5'd16:5'd31]};
        }

        cross_i_shift_function_rd: cross cp_i_shift_function, cp_i_shift_rd;
        cross_i_shift_function_rs1: cross cp_i_shift_function, cp_i_shift_rs1;
        cross_i_shift_function_shamt: cross cp_i_shift_function, cp_i_shift_shamt;

    endgroup


    // Cobertura funcional para instrucciones U:
    covergroup U_types with function sample(
        logic [6:0]  opcode,
        int          op_id,
        logic [4:0]  rd,
        logic [19:0] imm_u,
        logic        sign_bit,
        logic [3:0]  imm_low
    );

        option.per_instance = 1;

        cp_u_opcode: coverpoint opcode {
            bins lui = {7'b0110111};
            bins auipc = {7'b0010111};
        }

        cp_u_function: coverpoint op_id {
            bins lui = {OP_LUI};
            bins auipc = {OP_AUIPC};
        }

        cp_u_rd: coverpoint rd {
            bins x0 = {5'd0};
            bins x1_to_x7 = {[5'd1:5'd7]};
            bins x8_to_x15 = {[5'd8:5'd15]};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_u_immediate: coverpoint imm_u {
            bins zero = {20'h00000};
            bins low = {[20'h00001:20'h00fff]};
            bins mid = {[20'h01000:20'h7ffff]};
            bins high = {[20'h80000:20'hfffff]};
        }

        cp_u_sign: coverpoint sign_bit {
            bins positive_region = {1'b0};
            bins negative_region = {1'b1};
        }

        cp_u_imm_low: coverpoint imm_low {
            bins aligned_zero = {4'h0};
            bins nonzero = {[4'h1:4'hf]};
        }

        cross_u_function_rd: cross cp_u_function, cp_u_rd;
        cross_u_function_immediate: cross cp_u_function, cp_u_immediate;
        cross_u_rd_sign: cross cp_u_rd, cp_u_sign;

    endgroup


    // Cobertura funcional para instrucciones LOAD:
    covergroup LOAD_types with function sample(
        logic [6:0]  opcode,
        int          op_id,
        logic [4:0]  rd,
        logic [4:0]  rs1,
        logic [11:0] imm_i,
        logic [1:0]  addr_align
    );

        option.per_instance = 1;

        cp_load_opcode: coverpoint opcode {
            bins load_opcode = {7'b0000011};
        }

        cp_load_function: coverpoint op_id {
            bins lb = {OP_LB};
            bins lh = {OP_LH};
            bins lw = {OP_LW};
            bins lbu = {OP_LBU};
            bins lhu = {OP_LHU};
        }

        cp_load_rd: coverpoint rd {
            bins x0 = {5'd0};
            bins x1_to_x7 = {[5'd1:5'd7]};
            bins x8_to_x15 = {[5'd8:5'd15]};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_load_base: coverpoint rs1 {
            bins data_base = {5'd15};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_load_offset: coverpoint imm_i {
            bins zero = {12'h000};
            bins data_window = {[12'h001:12'h078]};
        }

        cp_load_alignment: coverpoint addr_align {
            bins byte_offsets[] = {[2'b00:2'b11]};
        }

        cross_load_function_rd: cross cp_load_function, cp_load_rd;
        cross_load_base_offset: cross cp_load_base, cp_load_offset;

    endgroup


    // Cobertura funcional para instrucciones STORE:
    covergroup STORE_types with function sample(
        logic [6:0]  opcode,
        int          op_id,
        logic [4:0]  rs1,
        logic [4:0]  rs2,
        logic [11:0] imm_s,
        logic [1:0]  addr_align
    );

        option.per_instance = 1;

        cp_store_opcode: coverpoint opcode {
            bins store_opcode = {7'b0100011};
        }

        cp_store_function: coverpoint op_id {
            bins sb = {OP_SB};
            bins sh = {OP_SH};
            bins sw = {OP_SW};
        }

        cp_store_base: coverpoint rs1 {
            bins data_base = {5'd15};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_store_source: coverpoint rs2 {
            bins x0 = {5'd0};
            bins x1_to_x7 = {[5'd1:5'd7]};
            bins x8_to_x15 = {[5'd8:5'd15]};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_store_offset: coverpoint imm_s {
            bins zero = {12'h000};
            bins data_window = {[12'h001:12'h078]};
        }

        cp_store_alignment: coverpoint addr_align {
            bins byte_offsets[] = {[2'b00:2'b11]};
        }

        cross_store_function_base: cross cp_store_function, cp_store_base;
        cross_store_function_source: cross cp_store_function, cp_store_source;
        cross_store_base_offset: cross cp_store_base, cp_store_offset;

    endgroup


    // Cobertura funcional para instrucciones BRANCH:
    covergroup BRANCH_types with function sample(
        logic [6:0]  opcode,
        int          op_id,
        logic [4:0]  rs1,
        logic [4:0]  rs2,
        logic [12:0] imm_b,
        logic        backward
    );

        option.per_instance = 1;

        cp_branch_opcode: coverpoint opcode {
            bins branch_opcode = {7'b1100011};
        }

        cp_branch_function: coverpoint op_id {
            bins beq = {OP_BEQ};
            bins bne = {OP_BNE};
            bins blt = {OP_BLT};
            bins bge = {OP_BGE};
            bins bltu = {OP_BLTU};
            bins bgeu = {OP_BGEU};
        }

        cp_branch_rs1: coverpoint rs1 {
            bins x0 = {5'd0};
            bins x1_to_x7 = {[5'd1:5'd7]};
            bins x8_to_x15 = {[5'd8:5'd15]};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_branch_rs2: coverpoint rs2 {
            bins x0 = {5'd0};
            bins x1_to_x7 = {[5'd1:5'd7]};
            bins x8_to_x15 = {[5'd8:5'd15]};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_branch_offset: coverpoint imm_b {
            bins forward_small = {13'd4, 13'd8};
        }

        cp_branch_direction: coverpoint backward {
            bins forward = {1'b0};
        }

        cross_branch_function_rs1: cross cp_branch_function, cp_branch_rs1;
        cross_branch_function_rs2: cross cp_branch_function, cp_branch_rs2;
        cross_branch_function_direction: cross cp_branch_function, cp_branch_direction;

    endgroup


    // Cobertura funcional para instrucciones JUMP:
    covergroup JUMP_types with function sample(
        logic [6:0]  opcode,
        int          op_id,
        logic [4:0]  rd,
        logic [4:0]  rs1,
        logic [20:0] imm_j,
        logic        link_reg
    );

        option.per_instance = 1;

        cp_jump_opcode: coverpoint opcode {
            bins jump_opcode = {7'b1101111, 7'b1100111};
        }

        cp_jump_function: coverpoint op_id {
            bins jump_function = {OP_JAL, OP_JALR};
        }

        cp_jump_rd: coverpoint rd {
            bins x0 = {5'd0};
            bins link_x1 = {5'd1};
            bins link_x5 = {5'd5};
            bins x2_to_x4 = {[5'd2:5'd4]};
            bins x6_to_x15 = {[5'd6:5'd15]};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_jump_rs1: coverpoint rs1 {
            bins observed_bits = {[5'd0:5'd15]};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_jump_offset: coverpoint imm_j {
            bins controlled_forward = {[21'h000004:21'h000008]};
            bins jalr_chain = {[21'h00000c:21'h0007fc]};
        }

        cp_jump_link_reg: coverpoint link_reg {
            bins link_register = {1'b1};
            bins other_register = {1'b0};
        }

        cross_jump_function_rd: cross cp_jump_function, cp_jump_rd;
        cross_jump_function_link: cross cp_jump_function, cp_jump_link_reg;

    endgroup


    // Cobertura general para programas mixtos:
    covergroup MIXED_types with function sample(
        instr_pkg::instr_set instr_type,
        logic [6:0]          opcode,
        int                  op_id,
        logic [4:0]          rd,
        logic [4:0]          rs1,
        bit                  writes_rd
    );

        option.per_instance = 1;

        cp_mixed_type: coverpoint instr_type {
            bins r_type = {instr_pkg::R_TYPE};
            bins i_arithmetic = {instr_pkg::I_TYPE_ARITHMETIC};
            bins i_shift = {instr_pkg::I_TYPE_SHIFT};
            bins i_load = {instr_pkg::I_TYPE_LOAD};
            bins i_jump = {instr_pkg::I_TYPE_JUMP};
            bins s_type = {instr_pkg::S_TYPE};
            bins b_type = {instr_pkg::B_TYPE};
            bins u_type = {instr_pkg::U_TYPE};
            bins j_type = {instr_pkg::J_TYPE};
        }

        cp_mixed_opcode: coverpoint opcode {
            bins opcodes[] = {
                7'b0110011, 7'b0010011, 7'b0000011, 7'b0100011,
                7'b1100011, 7'b0110111, 7'b0010111, 7'b1101111,
                7'b1100111
            };
        }

        cp_mixed_function: coverpoint op_id {
            bins known_ops[] = {[OP_ADD:OP_JALR], [OP_LB:OP_SH]};
            ignore_bins other = {OP_OTHER};
        }

        cp_mixed_rd: coverpoint rd {
            bins x0 = {5'd0};
            bins x1_to_x7 = {[5'd1:5'd7]};
            bins x8_to_x15 = {[5'd8:5'd15]};
        }

        cp_mixed_rs1: coverpoint rs1 {
            bins x0 = {5'd0};
            bins x1_to_x7 = {[5'd1:5'd7]};
            bins x8_to_x15 = {[5'd8:5'd15]};
        }

        cp_mixed_writes_rd: coverpoint writes_rd {
            bins writes = {1'b1};
            bins no_write = {1'b0};
        }

        cross_mixed_type_opcode: cross cp_mixed_type, cp_mixed_opcode {
            ignore_bins invalid_r = binsof(cp_mixed_type.r_type) && !binsof(cp_mixed_opcode) intersect {7'b0110011};
            ignore_bins invalid_i_arit = binsof(cp_mixed_type.i_arithmetic) && !binsof(cp_mixed_opcode) intersect {7'b0010011};
            ignore_bins invalid_i_shift = binsof(cp_mixed_type.i_shift) && !binsof(cp_mixed_opcode) intersect {7'b0010011};
            ignore_bins invalid_load = binsof(cp_mixed_type.i_load) && !binsof(cp_mixed_opcode) intersect {7'b0000011};
            ignore_bins invalid_jalr = binsof(cp_mixed_type.i_jump) && !binsof(cp_mixed_opcode) intersect {7'b1100111};
            ignore_bins invalid_store = binsof(cp_mixed_type.s_type) && !binsof(cp_mixed_opcode) intersect {7'b0100011};
            ignore_bins invalid_branch = binsof(cp_mixed_type.b_type) && !binsof(cp_mixed_opcode) intersect {7'b1100011};
            ignore_bins invalid_u = binsof(cp_mixed_type.u_type) && !binsof(cp_mixed_opcode) intersect {7'b0110111, 7'b0010111};
            ignore_bins invalid_j = binsof(cp_mixed_type.j_type) && !binsof(cp_mixed_opcode) intersect {7'b1101111};
        }

        cross_mixed_type_rd: cross cp_mixed_type, cp_mixed_rd {
            ignore_bins no_rd_store = binsof(cp_mixed_type.s_type);
            ignore_bins no_rd_branch = binsof(cp_mixed_type.b_type);
        }

        cross_mixed_type_write: cross cp_mixed_type, cp_mixed_writes_rd {
            ignore_bins store_never_writes = binsof(cp_mixed_type.s_type) && binsof(cp_mixed_writes_rd.writes);
            ignore_bins branch_never_writes = binsof(cp_mixed_type.b_type) && binsof(cp_mixed_writes_rd.writes);
        }

    endgroup


    // Cobertura adicional para cantidades de desplazamiento:
    covergroup SHIFT_amounts with function sample(
        int         op_id,
        logic [4:0] shamt
    );

        option.per_instance = 1;

        cp_shift_function: coverpoint op_id {
            bins slli = {OP_SLLI};
            bins srli = {OP_SRLI};
            bins srai = {OP_SRAI};
        }

        cp_shift_amount: coverpoint shamt {
            bins zero = {5'd0};
            bins small_shift = {[5'd1:5'd7]};
            bins medium_shift = {[5'd8:5'd15]};
            bins large_shift = {[5'd16:5'd31]};
        }

        cross_shift_function_amount: cross cp_shift_function, cp_shift_amount;

    endgroup


    // Cobertura adicional para immediatos positivos, negativos y cero:
    covergroup IMMEDIATE_values with function sample(logic [31:0] imm_ext);

        option.per_instance = 1;

        cp_imm_sign: coverpoint imm_ext {
            bins zero = {32'h00000000};
            bins positive = {[32'h00000001:32'h7fffffff]};
            bins negative = {[32'h80000000:32'hffffffff]};
        }

    endgroup


    // Se crean solamente los covergroups relacionados con la instruccion seleccionada:
    function new(
        string name = "SubscriberOBJ",
        uvm_component parent = null
    );

        super.new(name, parent);


        cov_r_enable         = 1'b0;
        cov_i_arit_enable    = 1'b0;
        cov_i_shift_enable   = 1'b0;
        cov_u_enable         = 1'b0;
        cov_load_enable      = 1'b0;
        cov_store_enable     = 1'b0;
        cov_branch_enable    = 1'b0;
        cov_jump_enable      = 1'b0;
        cov_mixed_enable     = 1'b0;
        cov_shift_enable     = 1'b0;
        cov_immediate_enable = 1'b0;


        case (INSTRUCTION_SELECTED)


            R_TYPE_SELECTED: begin

                R_types = new();
                cov_r_enable = 1'b1;

            end


            I_ARIT_TYPE_SELECTED: begin

                I_ARIT_types = new();
                IMMEDIATE_values = new();

                cov_i_arit_enable = 1'b1;
                cov_immediate_enable = 1'b1;

            end


            I_SHIFT_TYPE_SELECTED: begin

                I_SHIFT_types = new();
                SHIFT_amounts = new();

                cov_i_shift_enable = 1'b1;
                cov_shift_enable = 1'b1;

            end


            I_LOAD_TYPE_SELECTED: begin

                LOAD_types = new();

                cov_load_enable = 1'b1;

            end


            I_JUMP_TYPE_SELECTED: begin

                JUMP_types = new();

                cov_jump_enable = 1'b1;

            end


            S_TYPE_SELECTED: begin

                STORE_types = new();

                cov_store_enable = 1'b1;

            end


            B_TYPE_SELECTED: begin

                BRANCH_types = new();

                cov_branch_enable = 1'b1;

            end


            U_TYPE_SELECTED: begin

                U_types = new();
                IMMEDIATE_values = new();

                cov_u_enable = 1'b1;
                cov_immediate_enable = 1'b1;

            end


            J_TYPE_SELECTED: begin

                JUMP_types = new();

                cov_jump_enable = 1'b1;

            end

            RESET_LOGIC_TEST_SELECTED,
            CLOCK_VARIATION_TEST_SELECTED: begin
            end


            default: begin

                MIXED_types = new();

                cov_mixed_enable = 1'b1;

            end

        endcase

    endfunction


    // Se convierte el nombre de la instruccion en un identificador numerico:
    function automatic int get_op_id(string instr_name);

        case (instr_name)

            "ADD":   return OP_ADD;
            "SUB":   return OP_SUB;
            "SLL":   return OP_SLL;
            "SLT":   return OP_SLT;
            "SLTU":  return OP_SLTU;
            "XOR":   return OP_XOR;
            "SRL":   return OP_SRL;
            "SRA":   return OP_SRA;
            "OR":    return OP_OR;
            "AND":   return OP_AND;
            "ADDI":  return OP_ADDI;
            "SLTI":  return OP_SLTI;
            "SLTIU": return OP_SLTIU;
            "XORI":  return OP_XORI;
            "ORI":   return OP_ORI;
            "ANDI":  return OP_ANDI;
            "SLLI":  return OP_SLLI;
            "SRLI":  return OP_SRLI;
            "SRAI":  return OP_SRAI;
            "LUI":   return OP_LUI;
            "AUIPC": return OP_AUIPC;
            "LB":    return OP_LB;
            "LH":    return OP_LH;
            "LW":    return OP_LW;
            "LBU":   return OP_LBU;
            "LHU":   return OP_LHU;
            "SB":    return OP_SB;
            "SH":    return OP_SH;
            "SW":    return OP_SW;
            "BEQ":   return OP_BEQ;
            "BNE":   return OP_BNE;
            "BLT":   return OP_BLT;
            "BGE":   return OP_BGE;
            "BLTU":  return OP_BLTU;
            "BGEU":  return OP_BGEU;
            "JAL":   return OP_JAL;
            "JALR":  return OP_JALR;
            default: return OP_OTHER;

        endcase

    endfunction


    // Se extiende el signo de los immediatos antes de clasificarlos:
    function automatic logic [31:0] sign_extend(
        input logic [31:0] value,
        input int unsigned width
    );

        logic [31:0] mask;
        logic [31:0] sign_mask;


        if (width >= 32) begin

            return value;

        end


        mask = (32'h00000001 << width) - 1;

        sign_mask = 32'h00000001 << (width - 1);


        if ((value & sign_mask) != 32'd0) begin

            return value | ~mask;

        end


        return value & mask;

    endfunction


    // Se decodifica cada instruccion recibida y se muestrean las coberturas:
    virtual function void write(my_sequence_item t);

        logic [31:0] instr;
        logic [6:0]  opcode;
        logic [2:0]  funct3;
        logic [6:0]  funct7;
        logic [4:0]  rd;
        logic [4:0]  rs1;
        logic [4:0]  rs2;
        logic [11:0] imm_i;
        logic [11:0] imm_s;
        logic [12:0] imm_b;
        logic [19:0] imm_u;
        logic [20:0] imm_j;
        logic [20:0] jump_imm;
        logic [31:0] imm_ext;
        logic [4:0]  shamt;
        logic [1:0]  addr_align;
        logic [2:0]  zero_use;
        logic        backward;
        logic        link_reg;

        bit          is_shift_instruction;
        bit          has_immediate;
        bit          writes_rd;

        int          op_id;

        instr_pkg::instr_set instr_type;

        string       instr_name;


        instr = t.instr;

        opcode = instr[6:0];
        rd = instr[11:7];
        funct3 = instr[14:12];
        rs1 = instr[19:15];
        rs2 = instr[24:20];
        funct7 = instr[31:25];

        imm_i = instr[31:20];
        imm_s = {instr[31:25], instr[11:7]};
        imm_b = {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
        imm_u = instr[31:12];
        imm_j = {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

        jump_imm = (opcode == 7'b1100111) ? {{9{imm_i[11]}}, imm_i} : imm_j;

        shamt = instr[24:20];

        instr_type = decode_pkg::get_instr_type(instr);
        instr_name = decode_pkg::get_instr_name(instr);
        op_id = get_op_id(instr_name);


        // Se calculan campos auxiliares usados por los covergroups:
        addr_align = (instr_type == instr_pkg::S_TYPE) ? imm_s[1:0] : imm_i[1:0];

        zero_use = {
            (rd == 5'd0),
            (rs1 == 5'd0),
            (rs2 == 5'd0)
        };

        backward = (instr_type == instr_pkg::B_TYPE) ? imm_b[12] : imm_j[20];

        link_reg = (rd == 5'd1) || (rd == 5'd5);

        is_shift_instruction = (op_id inside {
            OP_SLL,
            OP_SRL,
            OP_SRA,
            OP_SLLI,
            OP_SRLI,
            OP_SRAI
        });

        has_immediate = (instr_type inside {
            instr_pkg::I_TYPE_ARITHMETIC,
            instr_pkg::I_TYPE_SHIFT,
            instr_pkg::I_TYPE_LOAD,
            instr_pkg::I_TYPE_JUMP,
            instr_pkg::S_TYPE,
            instr_pkg::B_TYPE,
            instr_pkg::U_TYPE,
            instr_pkg::J_TYPE
        });


        // Se calcula el immediato con signo segun el formato de instruccion:
        case (instr_type)

            instr_pkg::I_TYPE_ARITHMETIC,
            instr_pkg::I_TYPE_SHIFT,
            instr_pkg::I_TYPE_LOAD,
            instr_pkg::I_TYPE_JUMP: begin

                imm_ext = sign_extend(
                    {20'd0, imm_i},
                    12
                );

            end


            instr_pkg::S_TYPE: begin

                imm_ext = sign_extend(
                    {20'd0, imm_s},
                    12
                );

            end


            instr_pkg::B_TYPE: begin

                imm_ext = sign_extend(
                    {19'd0, imm_b},
                    13
                );

            end


            instr_pkg::U_TYPE: begin

                imm_ext = {
                    imm_u,
                    12'd0
                };

            end


            instr_pkg::J_TYPE: begin

                imm_ext = sign_extend(
                    {11'd0, imm_j},
                    21
                );

            end


            default: begin

                imm_ext = 32'd0;

            end

        endcase


        // Se identifica si la instruccion realiza escritura efectiva:
        writes_rd =
            (instr_type inside {
                instr_pkg::R_TYPE,
                instr_pkg::I_TYPE_ARITHMETIC,
                instr_pkg::I_TYPE_SHIFT,
                instr_pkg::I_TYPE_LOAD,
                instr_pkg::I_TYPE_JUMP,
                instr_pkg::U_TYPE,
                instr_pkg::J_TYPE
            }) &&
            (rd != 5'd0);


        // Se selecciona la cobertura especifica segun el tipo de instruccion:
        if (instr_type == instr_pkg::R_TYPE) begin

            assert (
                ((funct3 inside {3'b000, 3'b101}) &&
                 (funct7 inside {7'b0000000, 7'b0100000})) ||
                (!(funct3 inside {3'b000, 3'b101}) &&
                 (funct7 == 7'b0000000))
            )
            else begin

                `uvm_error(
                    get_type_name(),
                    "Encoding invalido para instruccion R-TYPE"
                )

            end


            assert ((rd <= 5'd15) && (rs1 <= 5'd15) && (rs2 <= 5'd15))
            else begin

                `uvm_error(
                    get_type_name(),
                    "R-TYPE usa registros fuera de x0-x15"
                )

            end


            if (cov_r_enable) begin

                R_types.sample(
                    opcode,
                    op_id,
                    rd,
                    rs1,
                    rs2,
                    zero_use
                );

            end

        end


        else if (
            instr_type inside {
                instr_pkg::I_TYPE_ARITHMETIC,
                instr_pkg::I_TYPE_SHIFT
            }
        ) begin

            if (instr_type == instr_pkg::I_TYPE_SHIFT) begin

                assert (
                    ((funct3 == 3'b001) && (funct7 == 7'b0000000)) ||
                    ((funct3 == 3'b101) &&
                     (funct7 inside {7'b0000000, 7'b0100000}))
                )
                else begin

                    `uvm_error(
                        get_type_name(),
                        "Encoding invalido para instruccion I-SHIFT"
                    )

                end

            end


            assert ((rd <= 5'd15) && (rs1 <= 5'd15))
            else begin

                `uvm_error(
                    get_type_name(),
                    "I-TYPE usa registros fuera de x0-x15"
                )

            end


            if (
                cov_i_arit_enable &&
                instr_type == instr_pkg::I_TYPE_ARITHMETIC
            ) begin

                I_ARIT_types.sample(
                    opcode,
                    op_id,
                    rd,
                    rs1,
                    imm_i
                );

            end

            if (
                cov_i_shift_enable &&
                instr_type == instr_pkg::I_TYPE_SHIFT
            ) begin

                I_SHIFT_types.sample(
                    opcode,
                    op_id,
                    rd,
                    rs1,
                    shamt
                );

            end

        end


        else if (instr_type == instr_pkg::U_TYPE) begin

            assert (rd <= 5'd15)
            else begin

                `uvm_error(
                    get_type_name(),
                    "U-TYPE usa rd fuera de x0-x15"
                )

            end


            if (cov_u_enable) begin

                U_types.sample(
                    opcode,
                    op_id,
                    rd,
                    imm_u,
                    imm_u[19],
                    imm_u[3:0]
                );

            end

        end


        else if (instr_type == instr_pkg::I_TYPE_LOAD) begin

            assert ((rd <= 5'd15) && (rs1 <= 5'd15))
            else begin

                `uvm_error(
                    get_type_name(),
                    "LOAD usa registros fuera de x0-x15"
                )

            end


            if (cov_load_enable) begin

                LOAD_types.sample(
                    opcode,
                    op_id,
                    rd,
                    rs1,
                    imm_i,
                    addr_align
                );

            end

        end


        else if (instr_type == instr_pkg::S_TYPE) begin

            assert ((rs1 <= 5'd15) && (rs2 <= 5'd15))
            else begin

                `uvm_error(
                    get_type_name(),
                    "STORE usa registros fuera de x0-x15"
                )

            end


            if (cov_store_enable) begin

                STORE_types.sample(
                    opcode,
                    op_id,
                    rs1,
                    rs2,
                    imm_s,
                    addr_align
                );

            end

        end


        else if (instr_type == instr_pkg::B_TYPE) begin

            assert ((rs1 <= 5'd15) && (rs2 <= 5'd15))
            else begin

                `uvm_error(
                    get_type_name(),
                    "BRANCH usa registros fuera de x0-x15"
                )

            end


            if (cov_branch_enable) begin

                BRANCH_types.sample(
                    opcode,
                    op_id,
                    rs1,
                    rs2,
                    imm_b,
                    backward
                );

            end

        end


        else if (
            (instr_type == instr_pkg::J_TYPE) ||
            (instr_type == instr_pkg::I_TYPE_JUMP)
        ) begin

            assert (
                (rd <= 5'd15) &&
                (
                    (instr_type == instr_pkg::J_TYPE) ||
                    (rs1 <= 5'd15)
                )
            )
            else begin

                `uvm_error(
                    get_type_name(),
                    "JUMP usa registros fuera de x0-x15"
                )

            end


            if (cov_jump_enable) begin

                JUMP_types.sample(
                    opcode,
                    op_id,
                    rd,
                    rs1,
                    jump_imm,
                    link_reg
                );

            end

        end


        // Se muestrean coberturas transversales solamente cuando fueron creadas:
        if (
            cov_shift_enable &&
            is_shift_instruction
        ) begin

            SHIFT_amounts.sample(
                op_id,
                shamt
            );

        end


        if (
            cov_immediate_enable &&
            has_immediate
        ) begin

            IMMEDIATE_values.sample(imm_ext);

        end


        if (cov_mixed_enable) begin

            MIXED_types.sample(
                instr_type,
                opcode,
                op_id,
                rd,
                rs1,
                writes_rd
            );

        end

    endfunction

endclass
