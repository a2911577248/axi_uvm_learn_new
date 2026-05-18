import uvm_pkg::*;
`include "uvm_macros.svh"

class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    axi_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);



        env = axi_env::type_id::create("env", this);

    endfunction
    
    virtual task run_phase(uvm_phase phase);
        basic_seq seq;

        seq = basic_seq::type_id::create("seq", this);

        phase.raise_objection(this);

        seq.start(env.master_agent.sqr);

        phase.drop_objection(this);

    endtask

endclass