import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_violation_seq extends basic_sequence;
    `uvm_object_utils(axi_violation_seq)


    virtual axi_interface vif; 

    function new(string name = "axi_violation_seq");
        super.new(name);
    endfunction


    virtual task body();
        if(!uvm_config_db#(virtual axi_interface)::get(m_sequencer, "", "vif", vif)) begin
            if(!uvm_config_db#(virtual axi_interface)::get(null, "*", "vif", vif))
                `uvm_fatal("SEQ_VIOLATION", "Failed to get virtual interface 'vif'")
        end

        fork
            begin
                super.body(); 
            end

            // 线程2
            begin
                `uvm_info("SEQ_VIOLATION", "first normal transation", UVM_LOW)
                @(posedge vif.aclk iff (vif.awready && vif.awvalid));

                `uvm_info("SEQ_VIOLATION", "First transaction finished safely. Now preparing fraud environment...", UVM_LOW)

                void'(uvm_hdl_force("tb_top.vif.awready", 1'b0));

                `uvm_info("SEQ_VIOLATION", "Waiting for Master to launch the second transaction (awvalid=1)", UVM_LOW)  

                @(posedge vif.aclk iff (vif.awvalid));

                `uvm_info("SEQ_VIOLATION", "(awvalid=1 && awready=0). Now modifying awaddr illegally!", UVM_LOW)

                // 强制修改地址
                void'(uvm_hdl_force("tb_top.vif.awaddr", 32'h1122_3344));

                @(posedge vif.aclk);

                `uvm_info("SEQ_VIOLATION", "Releasing all forces. Restoring environment...", UVM_LOW)

                void'(uvm_hdl_release("tb_top.vif.awaddr"));
                void'(uvm_hdl_release("tb_top.vif.awready"));
                
                @(posedge vif.aclk iff (vif.bvalid === 1'b1 && vif.bready === 1'b1));
                #50ns; 
                `uvm_info("SEQ_VIOLATION","run_finish---------------------", UVM_LOW)
            end
        join
    endtask

endclass