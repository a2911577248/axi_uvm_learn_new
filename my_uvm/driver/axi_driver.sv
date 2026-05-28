import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_driver extends uvm_driver #(axi_trans);
    `uvm_component_utils(axi_driver)

    virtual axi_interface vif;
    axi_config axi_cfg;

    axi_trans aw_q[$];
    axi_trans w_q[$];
    axi_trans ar_q[$];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axi_interface)::get(this, "", "vif", vif))begin
            `uvm_fatal("drv", "Cannot get virtual interface from uvm_config_db!")
        end

        if(!uvm_config_db#(axi_config)::get(this,"","axi_cfg",axi_cfg))begin
            `uvm_info("DRV", "No config found, using default config", UVM_LOW)
            axi_cfg = axi_config::type_id::create("axi_cfg");
        end
    endfunction


    virtual task run_phase(uvm_phase phase);

        vif.awvalid <= 0;
        vif.wvalid <= 0;
        vif.bready <= 0;
        vif.arvalid <= 0;
        vif.rready  <= 0;

        wait(vif.aresetn == 1'b1);

        fork
            get_and_dispatch();
            drive_aw();
            drive_w();
            drive_b();
            drive_ar();
            drive_r();
        join

    endtask



    virtual task get_and_dispatch();
        forever begin
            seq_item_port.get_next_item(req);
            if(req.is_write)begin
                aw_q.push_back(req);
                w_q.push_back(req);
            end else begin
                ar_q.push_back(req);
            end
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_aw();
        forever begin
            axi_trans tr;
            wait(aw_q.size() > 0);
            tr = aw_q.pop_front();

            @(posedge vif.aclk);
            if(axi_cfg.aw_delay_en && ($urandom_range(0, 100) < 30)) begin 
                vif.awvalid <= 0;
                repeat($urandom_range(1, axi_cfg.max_delay)) @(posedge vif.aclk); 
            end

            vif.awvalid <= 1'b1;
            vif.awid <= tr.id;
            vif.awaddr <= tr.addr;
            vif.awburst <= tr.burst;
            vif.awlen <= tr.len;
            vif.awsize <= tr.size;
            @(posedge vif.aclk iff vif.awready == 1'b1);

            if (aw_q.size() == 0) begin
                vif.awvalid <= 0;
            end
        end
    endtask
    
    virtual task drive_w();
        forever begin
            axi_trans tr;
            wait(w_q.size() > 0);
            tr = w_q.pop_front();

            for(int i=0; i <= tr.len; i=i+1)begin
                if(axi_cfg.w_delay_en && ($urandom_range(0, 100) < 30)) begin 
                    vif.wvalid <= 0;
                    repeat($urandom_range(1, axi_cfg.max_delay)) @(posedge vif.aclk); 
                end
                vif.wvalid <= 1'b1;
                vif.wdata <= tr.data[i];
                vif.wstrb <= tr.wstrb[i];
                vif.wlast <= (i == tr.len);
                @(posedge vif.aclk iff vif.wready == 1'b1);
            end

            if (w_q.size() == 0) begin
                vif.wvalid <= 0;
                vif.wlast <= 0;
                vif.wstrb <= 0;
            end
        end
    endtask

    virtual task drive_b();
        vif.bready <= 0;
        forever begin
            if (axi_cfg.b_delay_en && ($urandom_range(0, 100) < 30)) begin 
                vif.bready <= 0;
                repeat($urandom_range(1, axi_cfg.max_delay)) @(posedge vif.aclk);
            end
            vif.bready <= 1;
            @(posedge vif.aclk iff vif.bvalid == 1'b1);
            `uvm_info("DRV", $sformatf("Write Transaction Finished! BID=%0h", vif.bid), UVM_HIGH)
        end 
    endtask

    virtual task drive_ar();
        forever begin
            axi_trans tr;
            wait(ar_q.size() > 0);
            tr = ar_q.pop_front();

            if(axi_cfg.ar_delay_en && ($urandom_range(0, 100) < 30)) begin 
                vif.arvalid <= 0;
                repeat($urandom_range(1, axi_cfg.max_delay)) @(posedge vif.aclk); 
            end

            vif.arvalid <= 1;
            vif.arid <= tr.id;
            vif.araddr <= tr.addr;
            vif.arlen <= tr.len;
            vif.arsize <= tr.size;
            vif.arburst <= tr.burst;
            @(posedge vif.aclk iff vif.arready == 1'b1);

            if (ar_q.size() == 0) begin
                vif.arvalid <= 0;
            end
        end 
    endtask

    virtual task drive_r();
        vif.rready <= 0;
        forever begin
            if(axi_cfg.r_delay_en && ($urandom_range(0, 100) < 30))begin
                vif.rready <= 0;
                repeat($urandom_range(1, axi_cfg.max_delay)) @(posedge vif.aclk);
            end

            vif.rready <= 1'b1;
            @(posedge vif.aclk iff vif.rvalid == 1'b1);

            if (vif.rlast) begin
                `uvm_info("DRV", $sformatf("Read Transaction Finished! RID=%0h", vif.rid), UVM_HIGH)
            end
        end
    endtask



endclass