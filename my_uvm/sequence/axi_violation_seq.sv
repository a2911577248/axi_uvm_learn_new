import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_violation_seq extends axi_base_err_inject_seq;
    `uvm_object_utils(axi_violation_seq)


    virtual axi_interface vif; 
    axi_write_seq w_seq;
    axi_read_seq  r_seq;


    function new(string name = "axi_violation_seq");
        super.new(name);
    endfunction


    virtual task body();
        

        if(!uvm_config_db#(virtual axi_interface)::get(null, "*", "vif", vif))
            `uvm_fatal("SEQ_VIOLATION", "Failed to get virtual interface 'vif'")
        fork
            begin
                w_seq = axi_write_seq::type_id::create("w_seq");
                // r_seq = axi_read_seq::type_id::create("r_seq");
                if(!w_seq.randomize() with {
                    waddr == 32'h0F00;
                    wlen == 8'h03;
                    wburst == axi_trans::BURST_INCR;
                }) begin
                `uvm_error("axi_violation_seq_randomize", "w_seq randomize failed!")
                end
                w_seq.start(get_sequencer(), this);
            end

            // 线程2
            begin

                expect_assert_begin();
                wait (vif.aresetn);
                @(posedge vif.aclk);

                // Force awready low briefly so awvalid stays high without timeout.
                void'(uvm_hdl_force("tb_top.vif.awready", 1'b0));
                @(posedge vif.aclk iff (vif.awvalid == 1'b1));

                // Change awaddr while awvalid && !awready to violate stability.
                #1;
                void'(uvm_hdl_force("tb_top.vif.awaddr", 32'h0000_0023));
                @(posedge vif.aclk);
                void'(uvm_hdl_force("tb_top.vif.awready", 1'b1));
                @(posedge vif.aclk);
                void'(uvm_hdl_release("tb_top.vif.awaddr"));
                void'(uvm_hdl_release("tb_top.vif.awready"));

                @(posedge vif.aclk iff (vif.bvalid == 1'b1 && vif.bready == 1'b1));
                #50ns;

                expect_assert_end();

                `uvm_info("SEQ_VIOLATION","run_finish---------------------", UVM_LOW)
            end
        join
    endtask

endclass