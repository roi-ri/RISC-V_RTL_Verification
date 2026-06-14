/*
* =============================================================================
*
* - File        : scoreboard.sv
* - Autor       : Brandon Jiménez Campos (C33972)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 06-5-2026
* - Descripción : Scoreboard encargado de generar los valores de referencia
*                 para que el checker pueda comparar los valores esperados del
*                 RISC-V para verificar su correcto funcionamiento.
* =============================================================================
*/

import instr_pkg::*;
import decode_pkg::*;
import r_type_model::*;
import i_type_model::*;
import b_type_model::*;
import j_type_model::*;
import u_type_model::*;
import model_values::*;

`uvm_analysis_imp_decl( _rdifc )
`uvm_analysis_imp_decl( _wrifc )


class scoreboard #(
        parameter NUM_REGS   = 16,
        parameter REGS_ADDR  = $clog2(NUM_REGS),
        parameter DATA_WIDTH = 32,
        parameter MEM_BYTES  = 1024
    )
    extends uvm_scoreboard;


    `uvm_component_param_utils(scoreboard)

    // Puertos de análisis
    uvm_analysis_imp_rdifc #(output_sequence_item, scoreboard)
        uvm_analysis_imp_rdifc_obj;

    uvm_analysis_imp_wrifc #(my_sequence_item, scoreboard)
        uvm_analysis_imp_wrifc_obj;


    // Banco de registros del modelo de referencia
    logic [DATA_WIDTH-1:0] reg_mem [NUM_REGS-1:0];


    // Banco de memoria del modelo de referencia
    logic [7:0] data_mem [0 : MEM_BYTES - 1];


    // Struct de referencia; se inicializa para evitar X en el primer ciclo
    result reference = '{
        default:   '0,
        instr_name: "",
        instr_type: R_TYPE,
        valid:      1'b1,
        writes_rd:  1'b0,
        check_pc:   1'b0
    };


    // Queue de resultados esperados
    result res_mem[$];

    // Constructor
    function new(
        string name = "ScoreboardOBJ",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    // Build phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        uvm_analysis_imp_rdifc_obj =
            new("uvm_analysis_imp_rdifc_obj", this);

        uvm_analysis_imp_wrifc_obj =
            new("uvm_analysis_imp_wrifc_obj", this);
    endfunction


    // Función para leer el registro y obtener el valor que se encuentra en el registro
    function automatic logic [31:0] read_reg(
        input logic [4:0] addr,
        input string      reg_name
    );

        if (addr < NUM_REGS) begin
            return reg_mem[addr];
        end

        `uvm_warning(
            "SCOREBOARD",
            $sformatf(
                "%s=x%0d fuera del banco de %0d registros",
                reg_name,
                addr,
                NUM_REGS))
        return 32'd0;
    endfunction


    // Función para leer la memoria y obtener el valor según el tipo de LOAD
    function automatic logic [31:0] read_load(
        input  logic [31:0] addr,
        input  logic [2:0]  funct3,
        output logic        access_ok
    );

        int unsigned mem_addr;

        mem_addr  = addr;
        access_ok = 1'b1;

        case (funct3)

            // LB: lectura de un byte con extensión de signo
            3'b000: begin

                if (mem_addr < MEM_BYTES) begin
                    return {{24{data_mem[mem_addr][7]}},data_mem[mem_addr]};
                end
            end


            // LH: lectura de 16 bits con extensión de signo
            3'b001: begin

                if ((mem_addr + 1) < MEM_BYTES) begin
                  	return {{16{data_mem[mem_addr + 1][7]}},data_mem[mem_addr + 1], data_mem[mem_addr]};
                end
            end


            // LW: lectura de una palabra de 32 bits
            3'b010: begin

                if ((mem_addr + 3) < MEM_BYTES) begin

                    return {
                        data_mem[mem_addr + 3],
                        data_mem[mem_addr + 2],
                        data_mem[mem_addr + 1],
                        data_mem[mem_addr]
                    };
                end
            end

            // LBU: lectura de un byte con extensión de ceros
            3'b100: begin

                if (mem_addr < MEM_BYTES) begin

                    return {24'd0,data_mem[mem_addr]};
                end
            end


            // LHU: lectura de 16 bits con extensión de ceros
            3'b101: begin

                if ((mem_addr + 1) < MEM_BYTES) begin

                    return {16'd0,data_mem[mem_addr + 1],data_mem[mem_addr]};
                end
            end

            default: begin

                access_ok = 1'b0;

                `uvm_warning(
                    "SCOREBOARD",
                    $sformatf(
                        "funct3 inválido para LOAD: %03b",
                        funct3))

                return 32'd0;
            end

        endcase

        access_ok = 1'b0;

        `uvm_warning(
            "SCOREBOARD",
            $sformatf(
                "Lectura fuera del banco de memoria en la dirección %h",
                addr))
        return 32'd0;
    endfunction


    // ref_model: calcula el resultado esperado para una instrucción dada
    function void ref_model(
        logic [31:0] instr,
        logic        rst
    );

        logic [31:0] rs1_data;
        logic [31:0] rs2_data;
        logic [31:0] load_addr;
        logic        load_ok;


        reference.pc_ref      = reference.pc_ref_next;  // avanzar PC
        reference.pc_ref_next = reference.pc_ref;      

        reference.res_ref = '0;
        reference.rd      = '0;

        reference.branch = 1'b0;
        reference.pc_4   = 1'b1;

        reference.rs1     = '0;
        reference.rs2     = '0;
        reference.rs1_val = '0;
        reference.rs2_val = '0;
        reference.imm     = '0;
        reference.shamt   = '0;

        reference.instr_name = "";
        reference.instr_type = R_TYPE;


        reference.valid     = 1'b1;
        reference.writes_rd = 1'b0;
        reference.check_pc  = 1'b0;


        // Reset 
        if (rst) begin

            reference.pc_ref      = '0;
            reference.pc_ref_next = '0;
            reference.pc_4        = 1'b0;
            reference.valid       = 1'b0;

            rs1_data = 32'd0;
            rs2_data = 32'd0;

            res_mem.delete();

            for (int i = 0; i < NUM_REGS; i++) begin
                reg_mem[i] = '0;
            end
            return;

        end

        // Decodificación 
        reference.instr_type = get_instr_type(instr);
        reference.instr_name = get_instr_name(instr);

        // Modelo por tipo de instrucción 
        case (reference.instr_type)

            R_TYPE: begin

                rs1_data = read_reg(instr[19:15],"rs1");

                rs2_data = read_reg(instr[24:20],"rs2");

                reference = r_type_model_reference(
                    reference,
                    instr,
                    rs1_data,
                    rs2_data
                );

              	// La instrucción es válida, escribe en el registro destino
				// y no requiere verificar el valor del PC siguiente
                reference.valid     = 1'b1;
                reference.writes_rd = 1'b1;
                reference.check_pc  = 1'b0;
            end

            I_TYPE_ARITHMETIC,
            I_TYPE_SHIFT,
            I_TYPE_LOAD,
            I_TYPE_JUMP: begin

                rs1_data = read_reg(instr[19:15],"rs1");

                reference = i_type_model_reference(
                    reference,
                    instr,
                    rs1_data
                );

                case (reference.instr_type)

                    I_TYPE_ARITHMETIC,
                    I_TYPE_SHIFT: begin

                        reference.valid     = 1'b1;
                        reference.writes_rd = 1'b1;
                        reference.check_pc  = 1'b0;

                    end

                    I_TYPE_LOAD: begin

                        // Extensión de signo del inmediato de 12 bits
                        reference.imm = {
                            {20{instr[31]}},
                            instr[31:20]
                        };

                        // Cálculo de la dirección efectiva
                        load_addr =
                            reference.rs1_val +
                            reference.imm;

                        // Lectura de la memoria según el tipo de LOAD
                        reference.res_ref = read_load(
                            load_addr,
                            instr[14:12],
                            load_ok
                        );

                        reference.valid     = load_ok;
                        reference.writes_rd = load_ok;
                        reference.check_pc  = 1'b0;

                    end

                    I_TYPE_JUMP: begin

                        reference.valid     = 1'b1;
                        reference.writes_rd = 1'b1;

                        // Colocar en 1 cuando se compare pc_ref_next con el DUT
                        reference.check_pc = 1'b1;
                    end
                  
                    default: begin

                        reference.valid     = 1'b0;
                        reference.writes_rd = 1'b0;
                        reference.check_pc  = 1'b0;

                    end
                endcase
            end

            B_TYPE: begin

                reference = b_type_model_reference(
                    reference,
                    instr,
                    reg_mem
                );

                reference.valid     = 1'b1;
                reference.writes_rd = 1'b0;
                reference.check_pc  = 1'b1;

            end

            U_TYPE: begin

                reference = u_type_model_reference(
                    reference,
                    instr
                );

                // Solamente se implementó la LUI, ya que se mencionó que AUIPC no
                if (
                    (reference.instr_name == "LUI") &&
                    (reference.rd < NUM_REGS)
                ) begin

                    reference.valid     = 1'b1;
                    reference.writes_rd = 1'b1;
                    reference.check_pc  = 1'b0;
                end
                else begin

                    reference.valid     = 1'b0;
                    reference.writes_rd = 1'b0;
                    reference.check_pc  = 1'b0;
                end
            end

            J_TYPE: begin

                reference = j_type_model_reference(
                    reference,
                    instr
                );

                // Verificar que el rd solicitado no se exceda de los numeros del reg del riscv
                if (reference.rd < NUM_REGS) begin

                    reference.valid     = 1'b1;
                    reference.writes_rd = 1'b1;
                    reference.check_pc  = 1'b1;
                end
                else begin

                    reference.valid     = 1'b0;
                    reference.writes_rd = 1'b0;
                    reference.check_pc  = 1'b0;
                end
            end

            default: begin

                reference.res_ref   = '0;
                reference.rd        = '0;
                reference.pc_4      = 1'b1;
                reference.branch    = 1'b0;
                reference.valid     = 1'b0;
                reference.writes_rd = 1'b0;
                reference.check_pc  = 1'b0;
            end
        endcase


        // Avance del PC 
        if (reference.pc_4) begin
            reference.pc_ref_next = reference.pc_ref + 4;
        end

        // Si pc_4 == 0, el modelo ya calculó pc_ref_next (JALR, JAL, branch)
        // Actualización del banco de registros 
        // Solo se actualiza cuando la instrucción está implementada y escribe rd
        if (reference.valid && reference.writes_rd) begin
          	if ((reference.rd !== 5'd0) && (reference.rd < NUM_REGS)) begin
              	reg_mem[reference.rd] = reference.res_ref;
            end
        end

        // x0 siempre permanece en cero
        reg_mem[0] = '0;
      	// guardar los valores importantes en el queu
        res_mem.push_back(reference);
    endfunction

    // write_wrifc: recibe instrucción y reset desde el monitor de entrada
    virtual function void write_wrifc(my_sequence_item my_sequence_item_obj);

        `uvm_info(
            get_type_name(),
            $sformatf(
                "Se recibe la instrucción %h",
                my_sequence_item_obj.instr
            ),UVM_MEDIUM)
      
		// Se calculan los resultados esperados
        ref_model(my_sequence_item_obj.instr,my_sequence_item_obj.rst);
    endfunction

    // write_rdifc: recibe resultado del DUT y lo compara con la referencia
    virtual function void write_rdifc(output_sequence_item output_item_obj);

      	// Se crea el struct para poder guardar los valores que se van a extraer del ref model
        result expected;

        //
      	if (output_item_obj.output_data.rst || !output_item_obj.output_data.valid) begin
            return;
        end

		// Si no se tiene un resultado tirar error
        if (res_mem.size() == 0) begin
            `uvm_error(
                "SCOREBOARD ERROR",
                "No existe un resultado esperado para comparar"
            )
            return;
        end

		// Obtener los valores calculados por el modelo de referencia
        expected = res_mem.pop_front();


        // Si la instrucción no tiene modelo implementado, solo advertir
        if (!expected.valid) begin

            `uvm_warning(
                "SCOREBOARD",
                $sformatf(
                    "La instruccion %s todavía no tiene modelo de referencia implementado, por lo que se omite la comparacion",
                    expected.instr_name))

            return;

        end

               // Mostrar los valores experimentales obtenidos del DUT
        `uvm_info(
            get_type_name(),
            $sformatf(
                "Se solicita comparar el resultado experimental del DUT con el modelo de referencia. Instruccion: %s | PC experimental: %h | Registro experimental: x%0d | Dato experimental: %h",
                expected.instr_name,
                output_item_obj.output_data.pc,
                output_item_obj.output_data.rd_addr,
                output_item_obj.output_data.rd_data
            ),
            UVM_MEDIUM
        )


        // Mostrar los valores teóricos calculados por el modelo de referencia
        `uvm_info(
            get_type_name(),
            $sformatf(
              "Resultado teorico que sera comparado. Registro teorico: x%0d | Dato teorico: %h",
                expected.rd,
                expected.res_ref
            ),
            UVM_MEDIUM
        )

        // Verificación del resultado escrito en el banco de registros
        if (
            expected.writes_rd &&
            (expected.rd !== 5'd0) &&
            (expected.rd < NUM_REGS)
        ) begin

            // Verificar que el DUT haya realizado la escritura esperada
            if (!output_item_obj.output_data.writes_rd) begin

                `uvm_error(
                    "SCOREBOARD ERROR",
                    $sformatf(
                        "[%s] EL MODELO DE REFERENCIA ESPERABA UNA ESCRITURA EN x%0d, PERO EL DUT NO REALIZO NINGUNA ESCRITURA",
                        expected.instr_name,
                        expected.rd
                    )
                )

            end


            // Comparar el registro y el dato escrito por el DUT
            else if (
                (output_item_obj.output_data.rd_addr !== expected.rd) ||
                (output_item_obj.output_data.rd_data !== expected.res_ref)
            ) begin

                `uvm_error(
                    "SCOREBOARD ERROR",
                    $sformatf(
                      "[%s] EL RESULTADO EXPERIMENTAL DEL DUT NO COINCIDE CON EL RESULTADO TEORICO DEL MODELO DE REFERENCIA. Registro experimental: x%0d | Dato experimental: %h | Registro teorico: x%0d | Dato teorico: %h",
                        expected.instr_name,
                        output_item_obj.output_data.rd_addr,
                        output_item_obj.output_data.rd_data,
                        expected.rd,
                        expected.res_ref
                    )
                )

            end
            else begin

                `uvm_info(
                    get_type_name(),
                    $sformatf(
                        "[%s] Los resultados experimentales y teóricos coinciden. Registro: x%0d | Dato: %h",
                        expected.instr_name,
                        expected.rd,
                        expected.res_ref
                    ),
                    UVM_MEDIUM
                )

            end
        end

        // Verificar que el DUT no escriba cuando la instrucción no modifica rd
        else if (
            !expected.writes_rd &&
            output_item_obj.output_data.writes_rd
        ) begin

            `uvm_error(
                "SCOREBOARD ERROR",
                $sformatf(
                  "[%s] EL DUT REALIZO UNA ESCRITURA NO ESPERADA EN EL REGISTRO x%0d. Dato escrito: %h",
                    expected.instr_name,
                    output_item_obj.output_data.rd_addr,
                    output_item_obj.output_data.rd_data
                )
            )

        end

        // Verificación del PC siguiente para saltos y bifurcaciones
        if (expected.check_pc) begin

            // Mostrar el PC experimental y el PC teórico
            `uvm_info(
                get_type_name(),
                $sformatf(
                  "[%s] PC siguiente experimental del DUT: %h | PC siguiente teorico del modelo de referencia: %h",
                    expected.instr_name,
                    output_item_obj.output_data.pc_next,
                    expected.pc_ref_next
                ),
                UVM_MEDIUM
            )


            // Comparar el PC siguiente del DUT con el modelo de referencia
            if (
                output_item_obj.output_data.pc_next !==
                expected.pc_ref_next
            ) begin

                `uvm_error(
                    "SCOREBOARD ERROR",
                    $sformatf(
                        "[%s] EL PC SIGUIENTE EXPERIMENTAL DEL DUT NO COINCIDE CON EL PC SIGUIENTE TEORICO DEL MODELO DE REFERENCIA. PC experimental: %h | PC teorico: %h",
                        expected.instr_name,
                        output_item_obj.output_data.pc_next,
                        expected.pc_ref_next
                    )
                )

            end
            else begin

                `uvm_info(
                    get_type_name(),
                    $sformatf(
                      "[%s] Los valores experimentales y teoricos del PC siguiente coinciden. PC siguiente: %h",
                        expected.instr_name,
                        expected.pc_ref_next
                    ),
                    UVM_MEDIUM
                )
            end
        end
    endfunction
endclass