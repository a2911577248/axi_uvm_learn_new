import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_driver extends uvm_driver #(axi_trans);
    `uvm_component_utils(axi_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);

            `uvm_info("drv", $sformatf("got transaction: is_write=%0b, addr='h%0h", req.is_write, req.addr), UVM_LOW)

            seq_item_port.item_done();
        end
    endtask

endclass