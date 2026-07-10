/*
* =============================================================================
*
* - File        : mixed_type_env.sv
* - Autor       : Luis Diego Ramírez Leitón (C36421), Rodrigo Sánchez Araya (C37259), Brandon Jiménez Campos (C33972)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 10-07-2026
* - Descripción :Ambiente UVM especializado para ejecutar la secuencia mixta
*                 de instrucciones soportadas por el testbench.
*
* =============================================================================
*/

class Mixed_Type_env extends env;

    `uvm_component_utils(Mixed_Type_env)

    function new(string name = "Mixed_Type_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function base_sequence create_sequence();

        mixed_type_sequence sequence_obj;
        sequence_obj = mixed_type_sequence::type_id::create("mixed_type_sequence_obj");
        return sequence_obj;

    endfunction

endclass
