/*
* ======================================================================================
*
* - File        : agent_read.sv (agente pasívo)
* - Autor       : Luis Diego Ramírez Leitón (C36421)
* - Curso       : IE0621 - Verificación Funcional del Diseño de Circuitos Integrados
*                 Universidad de Costa Rica.
* - Fecha       : 13-06-2026
*
* - Descripción : Este programa define el agente pasívo del ambiente de verificación.
*                 El agente contiene el monitor encargado de observar las salidas
*                 experimentales producidas por el DUT y enviarlas al scoreboard
*                 mediante un analysis port.
*
* ======================================================================================
*/

// Se crea la clase que extiende de la clase base uvm_agent:
class agent_read extends uvm_agent;

    // Se registra la clase en la fábrica:
    `uvm_component_utils(agent_read)

    monitor monitor_obj;

    // Se crea el constructor:
 	function new(string name = "Agent_readOBJ", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // En build phase se crean las instancias de los componentes:
    virtual function void build_phase(uvm_phase phase);
    	super.build_phase(phase);
      	monitor_obj = monitor::type_id::create("monitor_obj", this);
    endfunction

endclass
