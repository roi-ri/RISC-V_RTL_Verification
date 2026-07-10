/*
* =============================================================================
*
* - File        : s_type_env.sv
* - Autor       : Luis Diego Ramírez Leitón (C36421)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción :Ambiente UVM especializado para ejecutar únicamente
*                 instrucciones tipo S. Este ambiente deriva del environment
*                 general y redefine la creación de la secuencia para utilizar
*                 s_type_sequence, permitiendo verificar de forma separada las
*                 instrucciones de almacenamiento SB, SH y SW.
*
* =============================================================================
*/

// Se define el ambiente especializado para instrucciones tipo S:
class S_Type_env extends env;

    // Se registra el ambiente en la fábrica:
    `uvm_component_utils(S_Type_env)

    // Se crea el constructor del ambiente:
    function new(
        string name = "S_Type_env",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction

    // Se redefine la creación de la secuencia para usar instrucciones tipo S:
    virtual function base_sequence create_sequence();

        // Se declara la secuencia específica de instrucciones tipo S:
        s_type_sequence sequence_obj;

        // Se crea la secuencia mediante la fábrica:
        sequence_obj =
            s_type_sequence::type_id::create(
                "s_type_sequence_obj"
            );

        // Se retorna la secuencia al test:
        return sequence_obj;

    endfunction

endclass
