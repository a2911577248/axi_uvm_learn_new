import uvm_pkg::*;
`include "uvm_macros.svh"

class basic_seq extends uvm_sequence #(axi_trans);
    `uvm_object_utils(basic_seq)

    function new(string name = "basic_seq");
        super.new(name);
    endfunction

    virtual task body();
        axi_trans trans;

        trans = axi_trans::type_id::create("trans");

        start_item(trans);

        assert(trans.randomize());

        finish_item(trans);

        `uvm_info("seq", "sent one transaction", UVM_LOW)

    endtask

endclass