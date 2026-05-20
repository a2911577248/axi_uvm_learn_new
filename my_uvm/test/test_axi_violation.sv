import uvm_pkg::*;
`include "uvm_macros.svh"

class test_axi_violation extends base_test;
    `uvm_component_utils(test_axi_violation)

    virtual axi_interface vif;

    function new(string name, uvm_component parent);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axi_interface)::get(this,"","vif",vif))begin
            `uvm_fatal("TEST_VIOLATION", "can not get axi_interface")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        `uvm_info("TEST_VIOLATION", "first normal transation", UVM_LOW)
        @(posedge vif.aclk iff (vif.awready && vif.awvalid));

        `uvm_info("TEST_VIOLATION", "First transaction finished safely. Now preparing fraud environment...", UVM_LOW)

        void'(uvm_hdl_force("tb_top.vif.awready", 1'b0));

        `uvm_info("TEST_VIOLATION", "Waiting for Master to launch the second transaction (awvalid=1)", UVM_LOW)  

        @(posedge vif.aclk iff (vif.awvalid));

        `uvm_info("TEST_VIOLATION", "(awvalid=1 && awready=0). Now modifying awaddr illegally!", UVM_LOW)

        void'(uvm_hdl_force("tb_top.vif.awaddr", 32'h1122_3344));

        @(posedge vif.aclk);
        @(posedge vif.aclk);
        @(posedge vif.aclk);

        `uvm_info("TEST", "Releasing all forces. Restoring environment...", UVM_LOW)

        void'(uvm_hdl_release("tb_top.vif.awaddr"));
        void'(uvm_hdl_release("tb_top.vif.awready"));
        
        @(posedge vif.aclk iff (vif.bvalid === 1'b1 && vif.bready === 1'b1));
        #50ns; 
        
        phase.drop_objection(this);
    endtask

endclass