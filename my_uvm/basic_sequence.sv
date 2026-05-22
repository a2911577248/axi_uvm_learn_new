import uvm_pkg::*;
`include "uvm_macros.svh"

class basic_sequence extends uvm_sequence #(axi_trans);
    `uvm_object_utils(basic_sequence)

    function new(string name = "basic_sequence");
        super.new(name);
    endfunction

    virtual task body();
        axi_trans trans;

        // trans = axi_trans::type_id::create("trans");
        // start_item(trans);
        // assert(trans.randomize() with {is_write == 1; addr == 'h100; data == 'h8899AABB;});
        // `uvm_info("SEQ", "sent one write transaction", UVM_LOW)
        // finish_item(trans);

        // trans = axi_trans::type_id::create("trans");
        // start_item(trans);
        // assert(trans.randomize() with {is_write == 0; addr == 'h100; data == '0;});
        // `uvm_info("SEQ", "sent one read transaction", UVM_LOW)
        // finish_item(trans);


        // trans = axi_trans::type_id::create("trans");
        // start_item(trans);
        // assert(trans.randomize() with {is_write == 1; addr == 'h101; data == 'h2222_2222;});
        // `uvm_info("SEQ", "sencond sent one write transaction", UVM_LOW)
        // finish_item(trans);


        trans = axi_trans::type_id::create("trans");
        start_item(trans);
        assert(trans.randomize() with {
            is_write == 1; 
            addr == 'h100; 
            len == 3;
            foreach(data[i]) data[i] == 'hA0A0_0000 + i;
        });
        `uvm_info("SEQ", "Sent one WRITE BURST transaction", UVM_LOW)
        finish_item(trans);

        start_item(trans);
        assert(trans.randomize() with {
            is_write == 0; 
            addr == 'h100; 
            len == 3;
            foreach(data[i]) data[i] == 'hA0A0_0000 + i;
        });
        `uvm_info("SEQ", "Sent one READ BURST transaction", UVM_LOW)
        finish_item(trans);
    endtask

endclass