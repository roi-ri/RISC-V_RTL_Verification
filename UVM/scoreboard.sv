/*
* =============================================================================
*
* - File        : scoreboard.sv
* - Autor       : Brandon Jiménez Campos (C33972)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 06-5-2026
* - Descripción : Scoreboard encargado de generar los valores de referencia
*                 para que el checker pueda comparar los valores esperados del
*                 RISC-V para verificar su correcto funcionamiento. Además,
*                 incluye contadores de instrucciones comparadas, correctas,
*                 omitidas e impresas, con un límite de impresión para evitar
*                 saturar la consola durante simulaciones largas.
*
* =============================================================================
*/

import instr_pkg::*;
import decode_pkg::*;
import r_type_model::*;
import i_type_model::*;
import s_type_model::*;
import b_type_model::*;
import j_type_model::*;
import u_type_model::*;
import model_values::*;

// Se declaran implementaciones de análisis diferenciadas para los monitores:
`uvm_analysis_imp_decl(_rdifc)
`uvm_analysis_imp_decl(_wrifc)

// Se crea la clase scoreboard parametrizable:
class scoreboard #(
        parameter NUM_REGS   = 16,
        parameter REGS_ADDR  = $clog2(NUM_REGS),
        parameter DATA_WIDTH = 32,
        parameter MEM_BYTES  = 4096
    )
    extends uvm_scoreboard;

    // Se registra la clase parametrizada en la fábrica:
    `uvm_component_param_utils(scoreboard)

    // Se declara el puerto de análisis que recibe los resultados experimentales del DUT:
    uvm_analysis_imp_rdifc #(output_sequence_item, scoreboard)
        uvm_analysis_imp_rdifc_obj;

    // Se declara el puerto de análisis que recibe las instrucciones ejecutadas:
    uvm_analysis_imp_wrifc #(my_sequence_item, scoreboard)
        uvm_analysis_imp_wrifc_obj;

    // Se declara el banco de registros utilizado por el modelo de referencia:
    logic [DATA_WIDTH-1:0] reg_mem [NUM_REGS-1:0];

    // Se declara el banco de memoria utilizado por el modelo de referencia:
    logic [7:0] data_mem [0 : MEM_BYTES - 1];

    // Se declara la estructura principal donde se almacena la referencia calculada:
    result reference = '{
        default:    '0,
        instr_name: "",
        instr_type: R_TYPE,
        valid:      1'b1,
        writes_rd:  1'b0,
        check_pc:   1'b0
    };

    // Se declara la cola de resultados esperados:
    result res_mem[$];

    // Se declara la cola de resultados experimentales que llegaron antes que
    // su referencia. Esto evita carreras entre los dos analysis ports.
    output_sequence_item actual_mem[$];

    // Se declara el contador de instrucciones comparadas:
    int unsigned instrucciones_comparadas;

    // Se declara el contador de instrucciones correctas:
    int unsigned instrucciones_correctas;

    // Se declara el contador de instrucciones omitidas:
    int unsigned instrucciones_omitidas;

    // Se declara el límite máximo de instrucciones que se imprimirán en consola:
    int unsigned max_instrucciones_impresas = 1000;

    // Se declara el contador de instrucciones impresas en consola:
    int unsigned instrucciones_impresas;

    // Se crea el constructor:
    function new(
        string name = "ScoreboardOBJ",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction

    // En build phase se crean los puertos de análisis del scoreboard:
    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        // Se crea el puerto que recibe los resultados experimentales del DUT:
        uvm_analysis_imp_rdifc_obj =
            new(
                "uvm_analysis_imp_rdifc_obj",
                this
            );

        // Se crea el puerto que recibe las instrucciones ejecutadas:
        uvm_analysis_imp_wrifc_obj =
            new(
                "uvm_analysis_imp_wrifc_obj",
                this
            );

        // Se inicializa el contador de instrucciones comparadas:
        instrucciones_comparadas = 0;

        // Se inicializa el contador de instrucciones correctas:
        instrucciones_correctas = 0;

        // Se inicializa el contador de instrucciones omitidas:
        instrucciones_omitidas = 0;

        // Se inicializa el contador de instrucciones impresas:
        instrucciones_impresas = 0;

    endfunction

    // Función para leer un registro del banco del modelo de referencia:
    function automatic logic [31:0] read_reg(
        input logic [4:0] addr,
        input string      reg_name
    );

        // Se retorna el valor almacenado si la dirección pertenece al banco RV32E:
        if (addr < NUM_REGS) begin

            return reg_mem[addr];

        end

        // Se genera una advertencia si se intenta leer un registro fuera del banco modelado:
        `uvm_warning(
            "SCOREBOARD",
            $sformatf(
                "%s=x%0d fuera del banco de %0d registros",
                reg_name,
                addr,
                NUM_REGS
            )
        )

        // Se retorna cero para registros fuera del banco modelado:
        return 32'd0;

    endfunction

    // Función para leer memoria y obtener el valor según el tipo de LOAD:
    function automatic logic [31:0] read_load(
        input  logic [31:0] addr,
        input  logic [2:0]  funct3,
        output logic        access_ok
    );

        // Se declara la dirección de memoria como entero sin signo:
        int unsigned mem_addr;

        // Se inicializa la dirección efectiva de memoria:
        mem_addr = addr;

        // Se asume inicialmente que el acceso es válido:
        access_ok = 1'b1;

        // Se seleccióna el tipo de lectura según funct3:
        case (funct3)

            // LB: lectura de un byte con extensión de signo:
            3'b000: begin

                if (mem_addr < MEM_BYTES) begin

                    return {
                        {24{data_mem[mem_addr][7]}},
                        data_mem[mem_addr]
                    };

                end

            end

            // LH: lectura de 16 bits con extensión de signo:
            3'b001: begin

                if ((mem_addr + 1) < MEM_BYTES) begin

                    return {
                        {16{data_mem[mem_addr + 1][7]}},
                        data_mem[mem_addr + 1],
                        data_mem[mem_addr]
                    };

                end

            end

            // LW: lectura de una palabra de 32 bits:
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

            // LBU: lectura de un byte con extensión de ceros:
            3'b100: begin

                if (mem_addr < MEM_BYTES) begin

                    return {
                        24'd0,
                        data_mem[mem_addr]
                    };

                end

            end

            // LHU: lectura de 16 bits con extensión de ceros:
            3'b101: begin

                if ((mem_addr + 1) < MEM_BYTES) begin

                    return {
                        16'd0,
                        data_mem[mem_addr + 1],
                        data_mem[mem_addr]
                    };

                end

            end

            default: begin

                // Se inválida el acceso si funct3 no corresponde a una instrucción LOAD:
                access_ok = 1'b0;

                `uvm_warning(
                    "SCOREBOARD",
                    $sformatf(
                        "funct3 inválido para LOAD: %03b",
                        funct3
                    )
                )

                return 32'd0;

            end

        endcase

        // Se inválida el acceso si la dirección queda fuera de la memoria modelada:
        access_ok = 1'b0;

        `uvm_warning(
            "SCOREBOARD",
            $sformatf(
                "Lectura fuera del banco de memoria en la dirección %h",
                addr
            )
        )

        return 32'd0;

    endfunction

    // ref_model: calcula el resultado esperado para una instrucción dada:
    function void ref_model(
        logic [31:0] instr,
        logic        rst
    );

        // Se declaran los valores de los registros fuente:
        logic [31:0] rs1_data;
        logic [31:0] rs2_data;

        // Se declara la dirección efectiva para instrucciones LOAD:
        logic [31:0] load_addr;

        // Se declara la bandera de acceso válido para instrucciones LOAD:
        logic load_ok;

        // Se declara la bandera de acceso válido para instrucciones STORE:
        logic store_ok;

        // PC de la instrucción que se está modelando:
        reference.pc_ref =
            reference.pc_ref_next;

        // Se inicializa el PC siguiente con el PC actual:
        reference.pc_ref_next =
            reference.pc_ref;

        // Se limpian los campos principales del resultado esperado:
        reference.res_ref = '0;
        reference.rd      = '0;

        // Se inicializan los campos de control del PC:
        reference.branch = 1'b0;
        reference.pc_4   = 1'b1;

        // Se limpian los campos auxiliares de decodificación:
        reference.rs1     = '0;
        reference.rs2     = '0;
        reference.rs1_val = '0;
        reference.rs2_val = '0;
        reference.imm     = '0;
        reference.shamt   = '0;

        // Se inicializan el nombre y tipo de instrucción:
        reference.instr_name = "";
        reference.instr_type = R_TYPE;

        // Se inicializan las banderas de validez y comparación:
        reference.valid     = 1'b1;
        reference.writes_rd = 1'b0;
        reference.check_pc  = 1'b0;

        // Se atiende la condición de reset:
        if (rst) begin

            // Se reinicia el PC del modelo de referencia:
            reference.pc_ref      = '0;
            reference.pc_ref_next = '0;
            reference.pc_4        = 1'b0;
            reference.valid       = 1'b0;

            // Se limpian las variables temporales:
            rs1_data = 32'd0;
            rs2_data = 32'd0;

            // Se limpia la cola de resultados esperados:
            res_mem.delete();

            // Se limpia también cualquier resultado experimental pendiente:
            actual_mem.delete();

            // IMPORTANTE:
            // No se limpia reg_mem durante reset.
            // Los registros iniciales se cargan desde test.sv antes de liberar
            // el reset externo. Si se limpian aquí, se pierden los valores:
            // x1 = 1, x2 = 2, ..., x15 = 15.
            // Para I_LOAD_TYPE también se perdería x15 = 32'h00000800.

            // Se termina el cálculo del modelo durante reset:
            return;

        end

        // Se decodifica el tipo de instrucción:
        reference.instr_type =
            get_instr_type(instr);

        // Se obtiene el nombre de la instrucción:
        reference.instr_name =
            get_instr_name(instr);

        // Se seleccióna el modelo de referencia según el tipo de instrucción:
        case (reference.instr_type)

            R_TYPE: begin

                // Se lee el valor del registro rs1:
                rs1_data =
                    read_reg(
                        instr[19:15],
                        "rs1"
                    );

                // Se lee el valor del registro rs2:
                rs2_data =
                    read_reg(
                        instr[24:20],
                        "rs2"
                    );

                // Se calcula el resultado esperado para instrucciones tipo R:
                reference =
                    r_type_model_reference(
                        reference,
                        instr,
                        rs1_data,
                        rs2_data
                    );

                // La instrucción R válida escribe en el registro destino:
                reference.valid     = 1'b1;
                reference.writes_rd = 1'b1;
                reference.check_pc  = 1'b0;

            end

            I_TYPE_ARITHMETIC,
            I_TYPE_SHIFT,
            I_TYPE_LOAD,
            I_TYPE_JUMP: begin

                // Se lee el valor del registro rs1:
                rs1_data =
                    read_reg(
                        instr[19:15],
                        "rs1"
                    );

                // Se calcula la referencia general para instrucciones tipo I:
                reference =
                    i_type_model_reference(
                        reference,
                        instr,
                        rs1_data
                    );

                // Se ajustan las banderas según el subtipo de instrucción I:
                case (reference.instr_type)

                    I_TYPE_ARITHMETIC,
                    I_TYPE_SHIFT: begin

                        reference.valid     = 1'b1;
                        reference.writes_rd = 1'b1;
                        reference.check_pc  = 1'b0;

                    end

                    I_TYPE_LOAD: begin

                        // Se calcula el inmediato de 12 bits con extensión de signo:
                        reference.imm = {
                            {20{instr[31]}},
                            instr[31:20]
                        };

                        // Se calcula la dirección efectiva:
                        load_addr =
                            reference.rs1_val +
                            reference.imm;

                        // Se lee la memoria según el tipo de LOAD:
                        reference.res_ref =
                            read_load(
                                load_addr,
                                instr[14:12],
                                load_ok
                            );

                        // Se habilita la comparación únicamente si el acceso fue válido:
                        reference.valid     = load_ok;
                        reference.writes_rd = load_ok;
                        reference.check_pc  = 1'b0;

                    end

                    I_TYPE_JUMP: begin

                        reference.valid     = 1'b1;
                        reference.writes_rd = 1'b1;
                        reference.check_pc  = 1'b1;

                    end

                    default: begin

                        reference.valid     = 1'b0;
                        reference.writes_rd = 1'b0;
                        reference.check_pc  = 1'b0;

                    end

                endcase

            end

            B_TYPE: begin

                // Se lee el valor del registro rs1:
                rs1_data =
                    read_reg(
                        instr[19:15],
                        "rs1"
                    );

                // Se lee el valor del registro rs2:
                rs2_data =
                    read_reg(
                        instr[24:20],
                        "rs2"
                    );

                // Se calcula la referencia para instrucciones tipo B:
                reference =
                    b_type_model_reference(
                        reference,
                        instr,
                        rs1_data,
                        rs2_data
                    );

                // Los branch no escriben rd.
                // En este core, NXPC2 es confiable como destino visible cuando
                // el branch se toma; para no tomados se compara por la secuencia
                // de PCs ejecutados, no por NXPC2 adelantado del pipeline.
                reference.valid     = 1'b1;
                reference.writes_rd = 1'b0;
                reference.check_pc  = reference.branch;

            end

            S_TYPE: begin

                // Se lee el valor del registro rs1:
                rs1_data =
                    read_reg(
                        instr[19:15],
                        "rs1"
                    );

                // Se lee el valor del registro rs2:
                rs2_data =
                    read_reg(
                        instr[24:20],
                        "rs2"
                    );

                // Se calcula la referencia para instrucciones tipo S:
                reference =
                    s_type_model_reference(
                        reference,
                        instr,
                        rs1_data,
                        rs2_data
                    );

                // Se modela la escritura en memoria para SB, SH y SW:
                store_ok = 1'b0;

                case (reference.instr_name)

                    "SB": begin

                        if (reference.res_ref < MEM_BYTES) begin

                            data_mem[reference.res_ref] =
                                reference.rs2_val[7:0];

                            store_ok = 1'b1;

                        end

                    end

                    "SH": begin

                        if ((reference.res_ref + 1) < MEM_BYTES) begin

                            data_mem[reference.res_ref] =
                                reference.rs2_val[7:0];

                            data_mem[reference.res_ref + 1] =
                                reference.rs2_val[15:8];

                            store_ok = 1'b1;

                        end

                    end

                    "SW": begin

                        if ((reference.res_ref + 3) < MEM_BYTES) begin

                            data_mem[reference.res_ref] =
                                reference.rs2_val[7:0];

                            data_mem[reference.res_ref + 1] =
                                reference.rs2_val[15:8];

                            data_mem[reference.res_ref + 2] =
                                reference.rs2_val[23:16];

                            data_mem[reference.res_ref + 3] =
                                reference.rs2_val[31:24];

                            store_ok = 1'b1;

                        end

                    end

                    default: begin

                        store_ok = 1'b0;

                    end

                endcase

                reference.valid     = store_ok;
                reference.writes_rd = 1'b0;
                reference.check_pc  = 1'b0;

            end

            U_TYPE: begin

                // Se calcula la referencia para instrucciones tipo U:
                reference =
                    u_type_model_reference(
                        reference,
                        instr
                    );

                // Se habilita la comparación para instrucciones U soportadas:
                if (
                    ((reference.instr_name == "LUI") ||
                     (reference.instr_name == "AUIPC")) &&
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

                // Se calcula la referencia para instrucciones tipo J:
                reference =
                    j_type_model_reference(
                        reference,
                        instr
                    );

                // Se verifica que rd pertenezca al banco de registros modelado:
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

                // Se inválida cualquier instrucción no soportada por el modelo:
                reference.res_ref   = '0;
                reference.rd        = '0;
                reference.pc_4      = 1'b1;
                reference.branch    = 1'b0;
                reference.valid     = 1'b0;
                reference.writes_rd = 1'b0;
                reference.check_pc  = 1'b0;

            end

        endcase

        // Se calcula el PC siguiente cuando corresponde avanzar secuencialmente:
        if (reference.pc_4) begin

            reference.pc_ref_next =
                reference.pc_ref + 4;

        end

        // Se actualiza el banco de registros del modelo cuando la instrucción escribe en rd:
        if (
            reference.valid &&
            reference.writes_rd
        ) begin

            if (
                (reference.rd !== 5'd0) &&
                (reference.rd < NUM_REGS)
            ) begin

                reg_mem[reference.rd] =
                    reference.res_ref;

            end

        end

        // x0 siempre permanece en cero:
        reg_mem[0] = '0;

        // Se guarda el resultado esperado en la cola para su comparación posterior:
        res_mem.push_back(reference);

    endfunction

    // write_wrifc: recibe instrucción y reset desde el monitor de entrada:
    virtual function void write_wrifc(my_sequence_item my_sequence_item_obj);

        // Se declara un resultado experimental pendiente, si llego antes:
        output_sequence_item pending_output_item;

        // Se calcula el resultado esperado:
        ref_model(
            my_sequence_item_obj.instr,
            my_sequence_item_obj.rst
        );

        // Si el monitor de salida escribio primero en este mismo ciclo, se
        // compara ahora que la referencia ya existe.
        if (actual_mem.size() != 0) begin

            pending_output_item =
                actual_mem.pop_front();

            write_rdifc(
                pending_output_item
            );

        end

    endfunction

    // write_rdifc: recibe resultado del DUT y lo compara con la referencia:
    virtual function void write_rdifc(output_sequence_item output_item_obj);

        // Se declara la estructura donde se almacena el resultado esperado:
        result expected;

        // Se declara la bandera general de comparación:
        bit comparison_ok;

        // Se declara el mensaje asociado con la comparación de registro y dato:
        string comparison_msg;

        // Se declara el mensaje asociado con la comparación del PC siguiente:
        string pc_msg;

        // Se declara una bandera para controlar si la instrucción actual se imprime:
        bit imprimir_instruccion;

        // Se ignoran resultados inválidos o asociados con reset:
        if (
            output_item_obj.output_data.rst ||
            !output_item_obj.output_data.valid
        ) begin

            return;

        end

        // Se verifica que exista un resultado esperado para comparar. Si aun
        // no existe, se guarda el resultado experimental para evitar una
        // carrera entre analysis ports.
        if (res_mem.size() == 0) begin

            actual_mem.push_back(
                output_item_obj
            );

            return;

        end

        // Se obtiene el resultado esperado calculado por el modelo de referencia:
        expected =
            res_mem.pop_front();

        // Se determina si la instrucción actual debe imprimirse en consola:
        imprimir_instruccion =
            instrucciones_impresas < max_instrucciones_impresas;

        // Se incrementa el contador de instrucciones impresas únicamente si se imprimirá:
        if (imprimir_instruccion) begin

            instrucciones_impresas++;

        end

        // Se inicializan las variables de comparación:
        comparison_ok  = 1'b1;
        comparison_msg = "";
        pc_msg         = "";

        // Se imprime la instrucción ejecutada únicamente si no se superó el límite:
        if (imprimir_instruccion) begin

            `uvm_info(
                get_type_name(),
                $sformatf(
                    "INSTRUCCION EJECUTADA | %s | PC = %08h | instr = %08h",
                    expected.instr_name,
                    output_item_obj.output_data.pc,
                    output_item_obj.output_data.instr
                ),
                UVM_MEDIUM
            )

            if ((expected.instr_type == B_TYPE) && !expected.writes_rd) begin

                `uvm_info(
                    get_type_name(),
                    $sformatf(
                        "VALOR TEORICO         | BRANCH rs1 = x%0d (%08h) | rs2 = x%0d (%08h) | tomado = %0b | PC_esp = %08h",
                        expected.rs1,
                        expected.rs1_val,
                        expected.rs2,
                        expected.rs2_val,
                        expected.branch,
                        expected.pc_ref_next
                    ),
                    UVM_MEDIUM
                )

            end

            else if ((expected.instr_type == S_TYPE) && !expected.writes_rd) begin

                `uvm_info(
                    get_type_name(),
                    $sformatf(
                        "VALOR TEORICO         | STORE addr = %08h | rs1 = x%0d (%08h) | rs2 = x%0d (%08h) | escribe_rd = %0b",
                        expected.res_ref,
                        expected.rs1,
                        expected.rs1_val,
                        expected.rs2,
                        expected.rs2_val,
                        expected.writes_rd
                    ),
                    UVM_MEDIUM
                )

            end

            else begin

                `uvm_info(
                    get_type_name(),
                    $sformatf(
                        "VALOR TEORICO         | Registro = x%0d | Dato = %08h | escribe_rd = %0b",
                        expected.rd,
                        expected.res_ref,
                        expected.writes_rd
                    ),
                    UVM_MEDIUM
                )

            end

            if ((expected.instr_type == B_TYPE) && !expected.writes_rd) begin

                `uvm_info(
                    get_type_name(),
                    $sformatf(
                        "VALOR EXPERIMENTAL    | BRANCH observado sin escritura rd | PC_next = %08h | escribe_rd = %0b",
                        output_item_obj.output_data.pc_next,
                        output_item_obj.output_data.writes_rd
                    ),
                    UVM_MEDIUM
                )

            end

            else if ((expected.instr_type == S_TYPE) && !expected.writes_rd) begin

                `uvm_info(
                    get_type_name(),
                    $sformatf(
                        "VALOR EXPERIMENTAL    | STORE observado sin escritura rd | escribe_rd = %0b",
                        output_item_obj.output_data.writes_rd
                    ),
                    UVM_MEDIUM
                )

            end

            else begin

                `uvm_info(
                    get_type_name(),
                    $sformatf(
                        "VALOR EXPERIMENTAL    | Registro = x%0d | Dato = %08h | escribe_rd = %0b",
                        output_item_obj.output_data.rd_addr,
                        output_item_obj.output_data.rd_data,
                        output_item_obj.output_data.writes_rd
                    ),
                    UVM_MEDIUM
                )

            end

        end

        // Se revisa si la instrucción tiene modelo de referencia implementado:
        if (!expected.valid) begin

            // Se contabiliza la instrucción omitida:
            instrucciones_omitidas++;

            // Se imprime la comparación omitida únicamente si no se superó el límite:
            if (imprimir_instruccion) begin

                `uvm_warning(
                    "SCOREBOARD",
                    $sformatf(
                        "COMPARACION          | %s | OMITIDA: no tiene modelo de referencia implementado o el acceso no es válido",
                        expected.instr_name
                    )
                )

            end

            return;

        end

        // Se verifica el caso donde se espera una escritura efectiva en rd:
        if (
            expected.writes_rd &&
            (expected.rd !== 5'd0) &&
            (expected.rd < NUM_REGS)
        ) begin

            // Se verifica que el DUT haya realizado la escritura esperada:
            if (!output_item_obj.output_data.writes_rd) begin

                comparison_ok = 1'b0;

                comparison_msg =
                    $sformatf(
                        "NO COINCIDE: el modelo esperaba escritura en x%0d, pero el DUT no realizo escritura",
                        expected.rd
                    );

            end

            // Se compara el registro destino y el dato escrito:
            else if (
                (output_item_obj.output_data.rd_addr !== expected.rd) ||
                (output_item_obj.output_data.rd_data !== expected.res_ref)
            ) begin

                comparison_ok = 1'b0;

                comparison_msg =
                    "NO COINCIDE: el registro o el dato escrito son diferentes";

            end

            // Se confirma que el registro y el dato coinciden:
            else begin

                comparison_msg =
                    "COINCIDE: registro y dato correctos";

            end

        end

        // Se verifica el caso donde no se espera una escritura efectiva en rd:
        else begin

            // Se detecta una escritura inesperada en un registro distinto de x0:
            if (
                output_item_obj.output_data.writes_rd &&
                (output_item_obj.output_data.rd_addr !== 5'd0)
            ) begin

                comparison_ok = 1'b0;

                comparison_msg =
                    $sformatf(
                        "NO COINCIDE: el DUT escribio x%0d cuando no se esperaba escritura efectiva",
                        output_item_obj.output_data.rd_addr
                    );

            end

            // Se confirma que no hubo escritura efectiva inesperada:
            else begin

                comparison_msg =
                    "COINCIDE: no hubo escritura efectiva inesperada";

            end

        end

        // Se verifica el PC siguiente cuando la instrucción lo requiere:
        if (expected.check_pc) begin

            // Se compara el PC siguiente experimental contra el PC siguiente teórico:
            if (
                output_item_obj.output_data.pc_next !==
                expected.pc_ref_next
            ) begin

                comparison_ok = 1'b0;

                pc_msg =
                    $sformatf(
                        " | PC_next NO COINCIDE: experimental = %08h, teórico = %08h",
                        output_item_obj.output_data.pc_next,
                        expected.pc_ref_next
                    );

            end

            // Se confirma que el PC siguiente coincide:
            else begin

                pc_msg =
                    $sformatf(
                        " | PC_next coincide: %08h",
                        expected.pc_ref_next
                    );

            end

        end

        // Se incrementa el contador de instrucciones comparadas:
        instrucciones_comparadas++;

        // Se incrementa el contador de instrucciones correctas cuando la comparación coincide:
        if (comparison_ok) begin

            instrucciones_correctas++;

        end

        // Se imprime la comparación únicamente si no se superó el límite:
        if (imprimir_instruccion) begin

            // Se imprime la comparación como error cuando existe una diferencia:
            if (!comparison_ok) begin

                `uvm_error(
                    "SCOREBOARD ERROR",
                    $sformatf(
                        "COMPARACION          | %s | %s%s",
                        expected.instr_name,
                        comparison_msg,
                        pc_msg
                    )
                )

            end

            // Se imprime la comparación como información cuando todo coincide:
            else begin

                `uvm_info(
                    get_type_name(),
                    $sformatf(
                        "COMPARACION          | %s | %s%s",
                        expected.instr_name,
                        comparison_msg,
                        pc_msg
                    ),
                    UVM_MEDIUM
                )

            end

        end

    endfunction

    // En report phase se imprime el resumen final de instrucciones:
    virtual function void report_phase(uvm_phase phase);

        super.report_phase(phase);

        $display("");
        $display("=====================================================");
        $display("Resumen final del scoreboard");
        $display("=====================================================");
        $display(
            "Instrucciones correctas : %0d/%0d",
            instrucciones_correctas,
            instrucciones_comparadas
        );
        $display(
            "Instrucciones con error : %0d",
            instrucciones_comparadas - instrucciones_correctas
        );
        $display(
            "Instrucciones omitidas  : %0d",
            instrucciones_omitidas
        );
        $display(
            "Instrucciones impresas  : %0d/%0d",
            instrucciones_impresas,
            max_instrucciones_impresas
        );
        $display(
            "Referencias pendientes  : %0d",
            res_mem.size()
        );
        $display(
            "Resultados pendientes   : %0d",
            actual_mem.size()
        );
        $display("=====================================================");
        $display("");

        if (
            (res_mem.size() != 0) ||
            (actual_mem.size() != 0)
        ) begin

            `uvm_warning(
                "SCOREBOARD",
                $sformatf(
                    "Quedaron transacciones sin pareja: referencias=%0d, resultados=%0d",
                    res_mem.size(),
                    actual_mem.size()
                )
            )

        end

    endfunction

endclass
