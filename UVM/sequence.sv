/*
* =============================================================================
*
* - File        : sequence.sv
* - Autor       : Rodrigo Sanchez Araya (C37259)
* - Curso       : Verificación Funcional del Diseño de Circuitos Integrados
* - Fecha       : 5/12/2026
* - Descripción :Secuencia base UVM que genera instrucciones aleatorias para
*                 llenar la memoria interna del DUT. Calcula la cantidad de
*                 instrucciones a partir del tamaño de la memoria, crea elementos
*                 de secuencia, los randomiza y asigna una dirección incremental
*                 antes de enviarlos al driver.
*
* =============================================================================
*/
class base_sequence extends uvm_sequence #(my_sequence_item);

    `uvm_object_utils(base_sequence)

    int cantidad_instrucciones;
    int unsigned addr; 
    
    function new(string name = "Base_sequenceOBJ");
        super.new(name);
    endfunction

    task body();
        my_sequence_item my_sequence_item_obj;

        cantidad_instrucciones = $size($root.top.dut.MEM) / 4;

        for (int i = 0; i < cantidad_instrucciones; i++) begin
            my_sequence_item_obj = my_sequence_item::type_id::create("My Sequence Item Object");
            start_item(my_sequence_item_obj);
            assert(my_sequence_item_obj.randomize());
            my_sequence_item_obj.addr = i;
            finish_item(my_sequence_item_obj);
        end
    endtask

endclass
