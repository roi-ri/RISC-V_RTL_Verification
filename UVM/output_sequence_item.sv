/*
* ======================================================================================
*
* - File        : output_sequence_item.sv
* - Autor       : Luis Diego Ramírez Leitón (C36421)
* - Curso       : IE0621 - Verificación Funcional del Diseño de Circuitos Integrados
*                 Universidad de Costa Rica.
* - Fecha       : 13-06-2026
*
* - Descripción : Este programa define la transacción utilizada para transportar
*                 los valores experimentales observados en el DUT hacia el scoreboard.
*
* ======================================================================================
*/

// Se crea la transacción que transporta las salidas experimentales:
class output_sequence_item extends uvm_sequence_item;

    // Se registra la clase en la fábrica:
    `uvm_object_utils(output_sequence_item)

    // Se agrupan todos los valores experimentales que puede requerir el scoreboard:
    typedef struct {

        // Estado general:
        logic        rst;
        logic        valid;

        // Instrucción y PC asociados con la salida:
        logic [31:0] instr;
        logic [31:0] pc;
        logic [31:0] pc_next;

        // Información de escritura en el banco de registros:
        logic        writes_rd;
        logic [4:0]  rd_addr;
        logic [31:0] rd_data;

        // Señales adicionales para depuración:
        logic [31:0] alu_result;
        logic [31:0] simm;

        // Copia completa del banco de registros:
        logic [31:0] regs [0:15];

    } output_result;

    // Se declara el struct que contiene los datos experimentales:
    output_result output_data;

    // Se crea el constructor:
    function new(string name = "output_sequence_item");
        super.new(name);
    endfunction

endclass