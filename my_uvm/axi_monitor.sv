import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_monitor)

    virtual axi_interface vif;
    uvm_analysis_port#(axi_trans) ap; 

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axi_interface)::get(this, "", "vif", vif))begin
            `uvm_fatal("MON", "can't get virtual interface!")
        end
        ap = new("ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        wait(vif.aresetn == 1'b1);

        fork
            //R
            forever begin
                axi_trans trans;
                logic [31:0]temp_addr;
                logic [31:0]temp_data;

                @(posedge vif.aclk iff (vif.arready && vif.arvalid));
                temp_addr = vif.araddr;
                @(posedge vif.aclk iff (vif.rready && vif.rvalid));
                temp_data = vif.rdata;

                trans = axi_trans::type_id::create("trans"); 
                trans.data = temp_data;
                trans.addr = temp_addr;
                trans.is_write = 0;
                ap.write(trans);
                `uvm_info("MON", $sformatf("Captured READ: Addr='h%0h, Data='h%0h", trans.addr, trans.data), UVM_LOW)
            end

            //W
            forever begin
                axi_trans trans;
                logic [31:0]temp_addr;
                logic [31:0]temp_data;
                logic [1:0] temp_resp;

                @(posedge vif.aclk iff (vif.awready && vif.awvalid));
                temp_addr = vif.awaddr;
                @(posedge vif.aclk iff (vif.wready && vif.wvalid));
                temp_data = vif.wdata;
                @(posedge vif.aclk iff (vif.bready && vif.bvalid));
                temp_resp = vif.bresp;

                trans = axi_trans::type_id::create("trans"); 
                trans.data = temp_data;
                trans.addr = temp_addr;
                trans.is_write = 1;
                trans.resp = temp_resp;
                ap.write(trans);
                `uvm_info("MON", $sformatf("Captured WRITE: Addr='h%0h, Data='h%0h", trans.addr, trans.data), UVM_LOW)
            end           

        join

    endtask


endclass