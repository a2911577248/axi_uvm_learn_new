import uvm_pkg::*;   //Package classfunctiontypedef
`include "uvm_macros.svh"   //macro

class axi_trans extends uvm_sequence_item;
    rand bit        is_write;
    rand bit[31:0]  addr;
    rand bit[31:0]  data[];

    //brust
    rand bit[7:0]len;
    rand bit[2:0]size;
    rand bit[1:0]burst;

    rand bit[1:0] resp;
    rand bit[3:0] wstrb;



    constraint c_brust{
        burst == 2'b01;
        data.size() == len + 1;
        size == 3'b010;
        wstrb == 4'b1111;
    }

    `uvm_object_utils_begin(axi_trans)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(addr,     UVM_ALL_ON)
        `uvm_field_array_int(data, UVM_ALL_ON)
        `uvm_field_int(len,      UVM_ALL_ON)
        `uvm_field_int(size,     UVM_ALL_ON)
        `uvm_field_int(burst,    UVM_ALL_ON)
        `uvm_field_int(resp,     UVM_ALL_ON)
        `uvm_field_int(wstrb,    UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi_trans");
        super.new(name);
    endfunction

endclass