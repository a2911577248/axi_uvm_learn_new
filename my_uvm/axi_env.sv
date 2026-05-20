import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_env extends uvm_env;
    `uvm_component_utils(axi_env)
    
    axi_agent master_agent;
    axi_slave_driver slave_drv;
    axi_scoreboard scb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction


    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        master_agent = axi_agent::type_id::create("master_agent", this);
        slave_drv = axi_slave_driver::type_id::create("slave_drv", this);
        scb =axi_scoreboard::type_id::create("scb", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        master_agent.mon.ap.connect(scb.imp);

    endfunction
endclass