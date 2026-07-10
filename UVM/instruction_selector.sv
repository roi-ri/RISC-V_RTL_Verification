/*
* =============================================================================
*
* - File        : instruction_selector.sv
* - Autor       : Luis Diego Ramírez Leitón (C36421)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 08-7-2026
* - Descripción :Archivo selector encargado de indicar qué grupo de
*                 instrucciones será generado durante la simulación. Cada grupo
*                 se representa mediante una etiqueta asociada a una señal de
*                 4 bits. Para seleccionar un ambiente específico, únicamente
*                 se debe comentar o descomentar una de las opciones definidas
*                 en la sección de selección.
*
* =============================================================================
*/

`ifndef INSTRUCTION_SELECTOR_SV
`define INSTRUCTION_SELECTOR_SV

// ============================================================================
// SELECCIÓN DEL TIPO DE INSTRUCCIÓN: Para cambiar el grupo de instrucciones,
// deje descomentada una única opción.
// ============================================================================

`define SELECT_R_TYPE
//`define SELECT_I_ARIT_TYPE
//`define SELECT_I_SHIFT_TYPE
//`define SELECT_I_LOAD_TYPE
//`define SELECT_I_JUMP_TYPE
//`define SELECT_S_TYPE
//`define SELECT_B_TYPE
//`define SELECT_U_TYPE
//`define SELECT_J_TYPE
//`define SELECT_MIXED_TYPE
//`define SELECT_RESET_LOGIC_TEST
//`define SELECT_CLOCK_VARIATION_TEST

// Se crea el paquete del selector de instrucciones:
package instruction_selector_pkg;

    // Se declaran las etiquetas del selector de instrucciones:
    typedef enum logic [3:0] {

        R_TYPE_SELECTED       = 4'b0000,
        I_ARIT_TYPE_SELECTED  = 4'b0001,
        I_SHIFT_TYPE_SELECTED = 4'b0010,
        I_LOAD_TYPE_SELECTED  = 4'b0011,
        I_JUMP_TYPE_SELECTED  = 4'b0100,
        S_TYPE_SELECTED       = 4'b0101,
        B_TYPE_SELECTED       = 4'b0110,
        U_TYPE_SELECTED       = 4'b0111,
        J_TYPE_SELECTED              = 4'b1000,
        MIXED_TYPE_SELECTED          = 4'b1001,
        RESET_LOGIC_TEST_SELECTED    = 4'b1010,
        CLOCK_VARIATION_TEST_SELECTED = 4'b1011

    } instruction_selector_e;

    // Se asigna el selector final según la opción comentada o descomentada:
    `ifdef SELECT_R_TYPE

        localparam instruction_selector_e INSTRUCTION_SELECTED =
            R_TYPE_SELECTED;

    `elsif SELECT_I_ARIT_TYPE

        localparam instruction_selector_e INSTRUCTION_SELECTED =
            I_ARIT_TYPE_SELECTED;

    `elsif SELECT_I_SHIFT_TYPE

        localparam instruction_selector_e INSTRUCTION_SELECTED =
            I_SHIFT_TYPE_SELECTED;

    `elsif SELECT_I_LOAD_TYPE

        localparam instruction_selector_e INSTRUCTION_SELECTED =
            I_LOAD_TYPE_SELECTED;

    `elsif SELECT_I_JUMP_TYPE

        localparam instruction_selector_e INSTRUCTION_SELECTED =
            I_JUMP_TYPE_SELECTED;

    `elsif SELECT_S_TYPE

        localparam instruction_selector_e INSTRUCTION_SELECTED =
            S_TYPE_SELECTED;

    `elsif SELECT_B_TYPE

        localparam instruction_selector_e INSTRUCTION_SELECTED =
            B_TYPE_SELECTED;

    `elsif SELECT_U_TYPE

        localparam instruction_selector_e INSTRUCTION_SELECTED =
            U_TYPE_SELECTED;

    `elsif SELECT_J_TYPE

        localparam instruction_selector_e INSTRUCTION_SELECTED =
            J_TYPE_SELECTED;

    `elsif SELECT_MIXED_TYPE

        localparam instruction_selector_e INSTRUCTION_SELECTED =
            MIXED_TYPE_SELECTED;

    `elsif SELECT_RESET_LOGIC_TEST

        localparam instruction_selector_e INSTRUCTION_SELECTED =
            RESET_LOGIC_TEST_SELECTED;

    `elsif SELECT_CLOCK_VARIATION_TEST

        localparam instruction_selector_e INSTRUCTION_SELECTED =
            CLOCK_VARIATION_TEST_SELECTED;

    `else

        localparam instruction_selector_e INSTRUCTION_SELECTED =
            R_TYPE_SELECTED;

    `endif

    // Se declara una señal equivalente de 4 bits para visualizar el selector:
    localparam logic [3:0] INSTRUCTION_SELECTED_BITS = INSTRUCTION_SELECTED;

    // Se convierte el selector a texto para imprimir mensajes más claros:
    function automatic string instruction_selector_name(input instruction_selector_e selector);

        case (selector)

            R_TYPE_SELECTED: begin

                return "R_TYPE";

            end

            I_ARIT_TYPE_SELECTED: begin

                return "I_ARIT_TYPE";

            end

            I_SHIFT_TYPE_SELECTED: begin

                return "I_SHIFT_TYPE";

            end

            I_LOAD_TYPE_SELECTED: begin

                return "I_LOAD_TYPE";

            end

            I_JUMP_TYPE_SELECTED: begin

                return "I_JUMP_TYPE";

            end

            S_TYPE_SELECTED: begin

                return "S_TYPE";

            end

            B_TYPE_SELECTED: begin

                return "B_TYPE";

            end

            U_TYPE_SELECTED: begin

                return "U_TYPE";

            end

            J_TYPE_SELECTED: begin

                return "J_TYPE";

            end

            MIXED_TYPE_SELECTED: begin

                return "MIXED_TYPE";

            end

            RESET_LOGIC_TEST_SELECTED: begin

                return "RESET_LOGIC_TEST";

            end

            CLOCK_VARIATION_TEST_SELECTED: begin

                return "CLOCK_VARIATION_TEST";

            end

            default: begin

                return "UNKNOWN_TYPE";

            end

        endcase

    endfunction

endpackage

`endif
