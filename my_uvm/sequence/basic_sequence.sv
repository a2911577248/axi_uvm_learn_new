import uvm_pkg::*;
`include "uvm_macros.svh"

// --- 写 Sequence ---
class axi_write_seq extends uvm_sequence #(axi_trans);
    `uvm_object_utils(axi_write_seq)
    
    rand bit [31:0] waddr;
    rand bit [7:0]  wlen;
    rand bit [2:0]  wsize;

    function new(string name = "axi_write_seq");
        super.new(name);
    endfunction

    virtual task body();
        axi_trans trans = axi_trans::type_id::create("trans");
        start_item(trans);
        assert(trans.randomize() with {
            is_write == 1; 
            addr == local::waddr; 
            len == local::wlen;
            size == local::wsize;
        });
        finish_item(trans);
    endtask
endclass

// --- 读 Sequence ---
class axi_read_seq extends uvm_sequence #(axi_trans);
    `uvm_object_utils(axi_read_seq)
    
    rand bit [31:0] raddr;
    rand bit [7:0]  rlen;
    rand bit [2:0] rsize;

    function new(string name = "axi_read_seq");
        super.new(name);
    endfunction

    virtual task body();
        axi_trans trans = axi_trans::type_id::create("trans");
        start_item(trans);
        assert(trans.randomize() with {
            is_write == 0; 
            addr == local::raddr; 
            len == local::rlen;
            size == local::rsize;
        });
        finish_item(trans);
    endtask
endclass


class basic_sequence extends uvm_sequence #(axi_trans);
    `uvm_object_utils(basic_sequence)
    function new(string name = "basic_sequence");
        super.new(name);
    endfunction

    virtual task body();
        axi_write_seq w_seq;
        axi_read_seq  r_seq;
        
        bit [31:0] cfg_waddr;
        bit [7:0]  cfg_wlen;

        if (!$value$plusargs("START_ADDR=%h", cfg_waddr)) begin
            cfg_waddr = 32'h0100; 
        end
        
        if (!$value$plusargs("BURST_LEN=%d", cfg_wlen)) begin
            cfg_wlen = 8'h03; 
        end

        `uvm_info("SEQ", $sformatf("Starting basic sequence with ADDR=0x%0x, LEN=%0d", cfg_waddr, cfg_wlen), UVM_LOW)

        `uvm_do_with(w_seq, { waddr == cfg_waddr; wlen == cfg_wlen; })
        
        `uvm_do_with(r_seq, { raddr == cfg_waddr; rlen == cfg_wlen; })

        `uvm_do_with(w_seq, { waddr == cfg_waddr; wlen == cfg_wlen; })
        
    endtask
endclass