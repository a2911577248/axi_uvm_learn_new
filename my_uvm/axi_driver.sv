import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_driver extends uvm_driver #(axi_trans);
    `uvm_component_utils(axi_driver)

    virtual axi_interface vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if(!uvm_config_db#(virtual axi_interface)::get(this, "", "vif", vif))begin
            `uvm_fatal("drv", "Cannot get virtual interface from uvm_config_db!")
        end
    endfunction


    virtual task run_phase(uvm_phase phase);
        // forever begin
        //     seq_item_port.get_next_item(req);  // 从 sequencer 获取一个包，存在 req 里

        //     `uvm_info("drv", $sformatf("got transaction: is_write=%0b, addr='h%0h", req.is_write, req.addr), UVM_LOW)

        //     seq_item_port.item_done();
        // end

        vif.awvalid <= 0;
        vif.wvalid <= 0;
        vif.bready <= 0;

        wait(vif.aresetn == 1'b1);

        forever begin
            seq_item_port.get_next_item(req);
            if(req.is_write)begin
                `uvm_info("DRV", $sformatf("got transaction: is_write=%0b, addr='h%0h, data=%0h", req.is_write, req.addr, req.data), UVM_LOW)
                fork
                    //AW
                    begin
                        @(posedge vif.aclk);
                        vif.awvalid <= 1;
                        vif.awaddr <= req.addr;

                        @(posedge vif.aclk iff vif.awready == 1'b1);
                        vif.awvalid <= 0;
                    end
                    //W
                    begin
                        @(posedge vif.aclk);
                        vif.wvalid <= 1;
                        vif.wdata <= req.data;

                        @(posedge vif.aclk iff vif.wready == 1'b1);
                        vif.wvalid <= 0;
                    end

                    //B
                    begin
                        @(posedge vif.aclk);
                        vif.bready <= 1;

                        @(posedge vif.aclk iff vif.bvalid == 1'b1);
                        vif.bready <= 0;
                        `uvm_info("DRV", $sformatf("driver get write resp='%0b'", vif.bresp), UVM_LOW)
                    end                    
                join
                `uvm_info("DRV", "Write Transaction Finished!", UVM_LOW)
            end

            if(req.is_write == 1'b0)begin
                
                fork
                    //AR
                    begin
                        @(posedge vif.aclk);
                        vif.arvalid <= 1;
                        vif.araddr <= req.addr;

                        @(posedge vif.aclk iff vif.arready == 1'b1);
                        vif.arvalid <= 0;
                    end
                    //R
                    begin
                        @(posedge vif.aclk);
                        vif.rready <= 1;
                        @(posedge vif.aclk iff vif.rvalid)
                        `uvm_info("DRV", $sformatf("transaction read: data=%0h",vif.rdata), UVM_LOW)
                        req.data <= vif.rdata;
                        vif.rready <= 0;
                    end
                    
                join
                `uvm_info("DRV", "Read Transaction Finished!", UVM_LOW)
            end
            seq_item_port.item_done();
        end



    endtask

endclass