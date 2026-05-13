class env;

    riscv_driver driver_obj;
    monitor      monitor_obj;
    scoreboard   scoreboard_obj;

    virtual ifc_riscv ifc_riscv_obj;

    function new(virtual ifc_riscv ifc_riscv_obj);
        this.ifc_riscv_obj = ifc_riscv_obj;

        $display("Ambiente: Construyendo el ambiente y los componentes de verificación.");

        scoreboard_obj = new();

        driver_obj  = new(ifc_riscv_obj, scoreboard_obj);
        monitor_obj = new(ifc_riscv_obj, scoreboard_obj);
    endfunction


    task start_monitor();
        fork
            monitor_obj.check();
        join_none
    endtask

endclass
