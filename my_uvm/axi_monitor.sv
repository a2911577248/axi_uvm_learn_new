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
                logic [7:0] temp_len;
                logic [1:0] temp_resp;

                @(posedge vif.aclk iff (vif.arready && vif.arvalid));
                temp_addr = vif.araddr;
                temp_len  = vif.arlen;

                trans = axi_trans::type_id::create("trans"); 
                trans.data = new[temp_len + 1];
                
                for(int i = 0; i <= temp_len; i++) begin
                    @(posedge vif.aclk iff (vif.rready && vif.rvalid));
                    trans.data[i] = vif.rdata;
                    if (i == temp_len) temp_resp = vif.rresp;
                end

                trans.addr = temp_addr;
                trans.len  = temp_len;
                trans.is_write = 0;
                trans.resp = temp_resp;
                ap.write(trans);
                `uvm_info("MON", $sformatf("Captured READ: Addr='h%0h, Data size=%0d, Data[0]='h%0h", trans.addr, trans.data.size(), trans.data[0]), UVM_LOW)
            end

            //W
            forever begin
                axi_trans trans;
                logic [31:0]temp_addr;
                logic [7:0] temp_len;
                logic [1:0] temp_resp; 

                //AW
                @(posedge vif.aclk iff (vif.awready && vif.awvalid));
                temp_addr = vif.awaddr;
                temp_len = vif.awlen;

                trans = axi_trans::type_id::create("trans");
                trans.data = new[temp_len + 1];

                for(int i=0; i <= temp_len; i = i+1)begin
                    @(posedge vif.aclk iff (vif.wready && vif.wvalid));
                    trans.data[i] = vif.wdata;                    
                end

                //B
                @(posedge vif.aclk iff (vif.bready && vif.bvalid));
                temp_resp = vif.bresp;

                trans.addr = temp_addr;
                trans.len = temp_len;
                trans.is_write = 1;
                trans.resp = temp_resp;
                ap.write(trans);
               // `uvm_info("MON", $sformatf("Captured WRITE: Addr='h%0h, Data='h%0h", trans.addr, trans.data), UVM_LOW)
            end           

        join

    endtask


endclass