class subscriber extends uvm_subscriber #(my_sequence_item);

    `uvm_component_utils(subscriber)

    function new(string name = "SubscriberOBJ", uvm_component parent = null);
        super.new(name, parent);
        R_types = new();
        I_types = new();
        U_types = new();
        cross_types = new();
    endfunction

    covergroup R_types with function sample(
        logic [6:0] opcode,
        logic [2:0] funct3,
        logic [6:0] funct7,
        logic [4:0] rd,
        logic [4:0] rs1,
        logic [4:0] rs2
    );
        option.per_instance = 1;

        cp_r_opcode: coverpoint opcode {
            bins r_opcode = {7'b0110011};
        }

        cp_r_operation: coverpoint {funct7, funct3} {
            bins add  = {10'b0000000_000};
            bins sub  = {10'b0100000_000};
            bins sll  = {10'b0000000_001};
            bins slt  = {10'b0000000_010};
            bins sltu = {10'b0000000_011};
            bins xor_ = {10'b0000000_100};
            bins srl  = {10'b0000000_101};
            bins sra  = {10'b0100000_101};
            bins or_  = {10'b0000000_110};
            bins and_ = {10'b0000000_111};
        }

        cp_r_rd: coverpoint rd {
            bins x0 = {5'd0};
            bins valid_regs = {[5'd1:5'd15]};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_r_sources: coverpoint {rs1, rs2} {
            bins both_zero = {10'd0};
            bins normal_sources = default;
        }
    endgroup

    covergroup I_types with function sample(
        logic [6:0] opcode,
        logic [2:0] funct3,
        logic [6:0] funct7,
        logic [4:0] rd,
        logic [4:0] rs1,
        logic [11:0] imm_i
    );
        option.per_instance = 1;

        cp_i_opcode: coverpoint opcode {
            bins arithmetic_shift = {7'b0010011};
            bins load             = {7'b0000011};
            bins jump             = {7'b1100111};
        }

        cp_i_funct3: coverpoint funct3 {
            bins funct3_values[] = {[3'b000:3'b111]};
        }

        cp_i_imm: coverpoint imm_i {
            bins zero     = {12'h000};
            bins positive = {[12'h001:12'h7ff]};
            bins negative = {[12'h800:12'hfff]};
        }

        cp_i_regs: coverpoint {rd, rs1} {
            bins normal_regs = default;
        }
    endgroup

    covergroup U_types with function sample(
        logic [6:0] opcode,
        logic [4:0] rd,
        logic [19:0] imm_u
    );
        option.per_instance = 1;

        cp_u_opcode: coverpoint opcode {
            bins lui   = {7'b0110111};
            bins auipc = {7'b0010111};
        }

        cp_u_rd: coverpoint rd {
            bins x0 = {5'd0};
            bins valid_regs = {[5'd1:5'd15]};
            illegal_bins invalid_regs = {[5'd16:5'd31]};
        }

        cp_u_imm: coverpoint imm_u {
            bins zero_value = {20'h00000};
            bins low_value  = {[20'h00001:20'h00fff]};
            bins mid_value  = {[20'h01000:20'h7ffff]};
            bins high_value = {[20'h80000:20'hfffff]};
        }

        cp_u_sign: coverpoint imm_u[19] {
            bins positive_region = {1'b0};
            bins negative_region = {1'b1};
        }
    endgroup

    covergroup cross_types with function sample(
        instr_pkg::instr_set instr_type,
        logic [4:0] rd,
        logic [4:0] rs1,
        logic [2:0] funct3
    );
        option.per_instance = 1;

        cp_type: coverpoint instr_type {
            bins r_type = {instr_pkg::R_TYPE};
            bins i_arithmetic = {instr_pkg::I_TYPE_ARITHMETIC};
            bins i_shift = {instr_pkg::I_TYPE_SHIFT};
            bins i_load = {instr_pkg::I_TYPE_LOAD};
            bins i_jump = {instr_pkg::I_TYPE_JUMP};
            bins u_type = {instr_pkg::U_TYPE};
        }

        cp_rd: coverpoint rd {
            bins x0 = {5'd0};
            bins valid_regs = {[5'd1:5'd15]};
        }

        cp_funct3: coverpoint funct3 {
            bins funct3_values[] = {[3'b000:3'b111]};
        }

        cross_type_rd: cross cp_type, cp_rd;
        cross_type_funct3: cross cp_type, cp_funct3;
    endgroup

    virtual function void write(my_sequence_item t);

        logic [31:0] instr;
        logic [6:0]  opcode;
        logic [2:0]  funct3;
        logic [6:0]  funct7;
        logic [4:0]  rd;
        logic [4:0]  rs1;
        logic [4:0]  rs2;
        logic [11:0] imm_i;
        logic [19:0] imm_u;
        instr_pkg::instr_set instr_type;
        string instr_name;

        instr = t.instr;

        opcode = instr[6:0];
        rd     = instr[11:7];
        funct3 = instr[14:12];
        rs1    = instr[19:15];
        rs2    = instr[24:20];
        funct7 = instr[31:25];
        imm_i  = instr[31:20];
        imm_u  = instr[31:12];

        instr_type = decode_pkg::get_instr_type(instr);
        instr_name = decode_pkg::get_instr_name(instr);

        `uvm_info(
            get_type_name(),
            $sformatf("Subscriber recibe %s instr=%08h opcode=%07b rd=x%0d rs1=x%0d rs2=x%0d",
                instr_name, instr, opcode, rd, rs1, rs2),
            UVM_MEDIUM
        )

        // Assertion 1: encoding válido para R-TYPE.
        if (instr_type == instr_pkg::R_TYPE) begin
            assert (
                ((funct3 inside {3'b000, 3'b101}) &&
                 (funct7 inside {7'b0000000, 7'b0100000})) ||
                (!(funct3 inside {3'b000, 3'b101}) &&
                 (funct7 == 7'b0000000))
            )
            else `uvm_error(get_type_name(), "Encoding inválido para instrucción R-TYPE")
        end

        // Assertion 2: encoding válido para instrucciones I-SHIFT.
        if ((opcode == 7'b0010011) && (funct3 inside {3'b001, 3'b101})) begin
            assert (
                ((funct3 == 3'b001) && (funct7 == 7'b0000000)) ||
                ((funct3 == 3'b101) &&
                 (funct7 inside {7'b0000000, 7'b0100000}))
            )
            else `uvm_error(get_type_name(), "Encoding inválido para instrucción I-SHIFT")
        end

        // Assertion 3: registros dentro del rango RV32E x0-x15.
        if (instr_type == instr_pkg::R_TYPE) begin
            assert ((rd <= 5'd15) && (rs1 <= 5'd15) && (rs2 <= 5'd15))
            else `uvm_error(get_type_name(), "R-TYPE usa registros fuera de x0-x15")
        end
        else if (instr_type inside {
            instr_pkg::I_TYPE_ARITHMETIC,
            instr_pkg::I_TYPE_SHIFT,
            instr_pkg::I_TYPE_LOAD,
            instr_pkg::I_TYPE_JUMP
        }) begin
            assert ((rd <= 5'd15) && (rs1 <= 5'd15))
            else `uvm_error(get_type_name(), "I-TYPE usa registros fuera de x0-x15")
        end
        else if (instr_type == instr_pkg::U_TYPE) begin
            assert (rd <= 5'd15)
            else `uvm_error(get_type_name(), "U-TYPE usa rd fuera de x0-x15")
        end

        case (instr_type)
            instr_pkg::R_TYPE: begin
                R_types.sample(opcode, funct3, funct7, rd, rs1, rs2);
            end

            instr_pkg::I_TYPE_ARITHMETIC,
            instr_pkg::I_TYPE_SHIFT,
            instr_pkg::I_TYPE_LOAD,
            instr_pkg::I_TYPE_JUMP: begin
                I_types.sample(opcode, funct3, funct7, rd, rs1, imm_i);
            end

            instr_pkg::U_TYPE: begin
                U_types.sample(opcode, rd, imm_u);
            end
        endcase

        if (instr_type inside {
            instr_pkg::R_TYPE,
            instr_pkg::I_TYPE_ARITHMETIC,
            instr_pkg::I_TYPE_SHIFT,
            instr_pkg::I_TYPE_LOAD,
            instr_pkg::I_TYPE_JUMP,
            instr_pkg::U_TYPE
        }) begin
            cross_types.sample(instr_type, rd, rs1, funct3);
        end

    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        $display("=====================================================");
        $display("Subscriber functional coverage report");
        $display("=====================================================");
        $display("Overall coverage = %0f", $get_coverage());
        $display("R_types coverage = %0f", R_types.get_coverage());
        $display("I_types coverage = %0f", I_types.get_coverage());
        $display("U_types coverage = %0f", U_types.get_coverage());
        $display("Cross coverage = %0f", cross_types.get_coverage());
        $display("=====================================================");
    endfunction

endclass