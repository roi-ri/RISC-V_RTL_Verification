class env extends uvm_env;

    // Se registra la clase en la fábrica:
    `uvm_component_utils(env)

    // Se crea el tipo del scoreboard parametrizado:
    typedef scoreboard #() scoreboard_t;

    // Se declaran las instancias de los componentes necesarios:
    agent_instruction agent_instruction_obj;
    agent_read agent_read_obj;
    scoreboard_t scoreboard_obj;
    subscriber subscriber_obj;

    // Se crea el constructor:
  	function new(string name = "EnvOBJ", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // En build phase se crean las instancias de los componentes:
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
		
       	// Se crea el agente activo mediante la fábrica:
      	agent_instruction_obj = agent_instruction::type_id::create("agent_instruction_obj", this);

      	// Se crea el agente pasivo mediante la fábrica:
      	agent_read_obj = agent_read::type_id::create("agent_read_obj", this);

		// Se crea el scoreboard mediante la fábrica:
      	scoreboard_obj = scoreboard_t::type_id::create("scoreboard_obj", this);

        // Se crea el subscriber de cobertura mediante la fábrica:
        subscriber_obj = subscriber::type_id::create("subscriber_obj", this);
    endfunction

    // En connect phase se conectan los analysis ports:
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Se conecta el monitor de instrucciones con la entrada del scoreboard:
        agent_instruction_obj.monitor_instruction_obj.uvm_analysis_port_mon_inst_obj
            .connect(scoreboard_obj.uvm_analysis_imp_wrifc_obj);

        // Se conecta el monitor de instrucciones con el subscriber de cobertura:
        agent_instruction_obj.monitor_instruction_obj.uvm_analysis_port_mon_inst_obj
            .connect(subscriber_obj.analysis_export);

        // Se conecta el monitor de salida con la entrada del scoreboard:
        agent_read_obj.monitor_obj.uvm_analysis_port_mon_out_obj
            .connect(scoreboard_obj.uvm_analysis_imp_rdifc_obj);
    endfunction

endclass