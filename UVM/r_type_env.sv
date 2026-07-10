/*
* =============================================================================
*
* - File        : r_type_env.sv
* - Autor       : Luis Diego Ramírez Leitón (C36421)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción :Ambiente UVM especializado para ejecutar únicamente
*                 instrucciones tipo R. Este ambiente deriva del environment
*                 general y redefine la creación de la secuencia para utilizar
*                 r_type_sequence, permitiendo verificar de forma separada las
*                 instrucciones ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR
*                 y AND.
*
* =============================================================================
*/

// Se define el ambiente especializado para instrucciones tipo R:
class R_Type_env extends env;

    // Se registra el ambiente en la fábrica:
    `uvm_component_utils(R_Type_env)

    // Se crea el constructor del ambiente:
    function new(
        string name = "R_Type_env",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction

    // Se redefine la creación de la secuencia para usar instrucciones tipo R:
    virtual function base_sequence create_sequence();

        // Se declara la secuencia específica de instrucciones tipo R:
        r_type_sequence sequence_obj;

        // Se crea la secuencia mediante la fábrica:
        sequence_obj =
            r_type_sequence::type_id::create(
                "r_type_sequence_obj"
            );

        // Se retorna la secuencia al test:
        return sequence_obj;

    endfunction

endclass
