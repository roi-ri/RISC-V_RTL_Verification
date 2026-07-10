/*
* ======================================================================================
*
* - File        : agent_instruction.sv (agente activo)
* - Autor       : Luis Diego Ramírez Leitón (C36421)
* - Curso       : IE0621 - Verificación Funcional del Diseño de Circuitos Integrados
*                 Universidad de Costa Rica.
* - Fecha       : 13-06-2026
*
* - Descripción : Este programa define el agente activo encargado de generar y
*                 cargar las instrucciones en la memoria del DUT. Además, contiene
*                 el monitor que observa las instrucciones realmente ejecutadas
*                 y las envía al scoreboard mediante un analysis port.
*
* ======================================================================================
*/

// Se crea la clase que extiende de la clase base uvm_agent:
class agent_instruction extends uvm_agent;

    // Se registra la clase en la fábrica:
    `uvm_component_utils(agent_instruction)

    // Se declaran las instancias de los componentes necesarios:
  	monitor_instruction monitor_instruction_obj;
    sequencer sequencer_obj;
    driver driver_obj;

    // Se crea el constructor:
    function new(string name = "Agent_instructionOBJ", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // En build phase se crean las instancias de los componentes:
    virtual function void build_phase(uvm_phase phase);
      	super.build_phase(phase);

      	// Se crea el monitor de instrucciones mediante la fábrica:
      	monitor_instruction_obj = monitor_instruction::type_id::create("monitor_instruction_obj", this);

        // Se crea el sequencer mediante la fábrica:
      	sequencer_obj = sequencer::type_id::create("sequencer_obj", this);

        // Se crea el driver mediante la fábrica:
        driver_obj = driver::type_id::create("driver_obj",this);
    endfunction

    // En connect phase se conecta el driver con el sequencer:
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
      	driver_obj.seq_item_port.connect( sequencer_obj.seq_item_export);
    endfunction

endclass
