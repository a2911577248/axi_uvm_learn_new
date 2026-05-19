import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_agent extends uvm_agent;
    `uvm_component_utils(axi_agent)

    axi_sequencer        sqr;
    axi_driver    drv;
    axi_monitor          mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        sqr = axi_sequencer::type_id::create("sqr", this);
        drv = axi_driver::type_id::create("drv", this);
        mon = axi_monitor::type_id::create("mon", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass
