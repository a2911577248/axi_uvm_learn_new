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
        assert(trans.randomize() with {is_write == 1; addr == 'h100; data == 'h8899AABB;});
        `uvm_info("SEQ", "sent one write transaction", UVM_LOW)
        finish_item(trans);

        trans = axi_trans::type_id::create("trans");
        start_item(trans);
        assert(trans.randomize() with {is_write == 0; addr == 'h100; data == '0;});
        `uvm_info("SEQ", "sent one read transaction", UVM_LOW)
        finish_item(trans);


    endtask

endclass