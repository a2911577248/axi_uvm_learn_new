import uvm_pkg::*;   //Package classfunctiontypedef
`include "uvm_macros.svh"   //macro

class axi_trans extends uvm_sequence_item;
    rand bit        is_write;
    rand bit[31:0]  addr;
    rand bit[31:0]  data;
    rand bit[1:0]   resp;

    `uvm_object_utils_begin(axi_trans)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(addr,     UVM_ALL_ON)
        `uvm_field_int(data,     UVM_ALL_ON)
        `uvm_field_int(resp,     UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi_trans");
        super.new(name);
    endfunction

endclass