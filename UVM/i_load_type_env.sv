/*
* =============================================================================
*
* - File        : i_load_type_env.sv
* - Autor       : Luis Diego Ramírez Leitón (C36421)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción :Ambiente UVM especializado para ejecutar únicamente
*                 instrucciones tipo I load. Este ambiente deriva del
*                 environment general y redefine la creación de la secuencia
*                 para utilizar i_load_type_sequence, permitiendo verificar de
*                 forma separada las instrucciones LB, LH, LW, LBU y LHU.
*
* =============================================================================
*/

// Se define el ambiente especializado para instrucciones tipo I load:
class I_load_Type_env extends env;

    // Se registra el ambiente en la fábrica:
    `uvm_component_utils(I_load_Type_env)

    // Se crea el constructor del ambiente:
    function new(
        string name = "I_load_Type_env",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction

    // Se redefine la creación de la secuencia para usar instrucciones tipo I load:
    virtual function base_sequence create_sequence();

        // Se declara la secuencia específica de instrucciones tipo I load:
        i_load_type_sequence sequence_obj;

        // Se crea la secuencia mediante la fábrica:
        sequence_obj =
            i_load_type_sequence::type_id::create(
                "i_load_type_sequence_obj"
            );

        // Se retorna la secuencia al test:
        return sequence_obj;

    endfunction

endclass
