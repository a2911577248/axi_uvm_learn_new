import uvm_pkg::*;   //Package classfunctiontypedef
`include "uvm_macros.svh"   //macro

class axi_trans extends uvm_sequence_item;
    localparam bit [1:0] BURST_FIXED = 2'b00;
    localparam bit [1:0] BURST_INCR  = 2'b01;
    localparam bit [1:0] BURST_WRAP   = 2'b10;

    rand bit        is_write;
    rand bit[31:0]  addr;
    rand bit[31:0]  data[];

    //brust
    rand bit[7:0]len;
    rand bit[2:0]size;
    rand bit[1:0]burst;

    rand bit[1:0] resp;
    rand bit[3:0] wstrb[];

    rand bit[3:0] id;



    constraint c_brust{
        burst inside {BURST_FIXED, BURST_INCR, BURST_WRAP};
        data.size() == len + 1;
        wstrb.size() == len + 1;
        foreach(wstrb[i]) wstrb[i] == 4'b1111;
        if (burst == BURST_WRAP) len inside {8'h01, 8'h03, 8'h07, 8'h0f};
    }



    function automatic bit [31:0] beat_addr(int unsigned beat_idx);
        int unsigned beat_byte_count;
        int unsigned burst_byte_count;
        bit [31:0] wrap_base;

        beat_byte_count = (1 << size);

        case (burst)
            BURST_FIXED: begin
                return addr;
            end

            BURST_WRAP: begin
                burst_byte_count = (len + 1) * beat_byte_count;
                wrap_base = addr & ~(burst_byte_count - 1);
                return wrap_base | ((addr + (beat_idx * beat_byte_count)) & (burst_byte_count - 1));
            end

            default: begin
                return addr + (beat_idx * beat_byte_count);
            end
        endcase
    endfunction

    `uvm_object_utils_begin(axi_trans)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(id, UVM_ALL_ON)
        `uvm_field_int(addr,     UVM_ALL_ON)
        `uvm_field_array_int(data, UVM_ALL_ON)
        `uvm_field_int(len,      UVM_ALL_ON)
        `uvm_field_int(size,     UVM_ALL_ON)
        `uvm_field_int(burst,    UVM_ALL_ON)
        `uvm_field_int(resp,     UVM_ALL_ON)
        `uvm_field_array_int(wstrb,    UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi_trans");
        super.new(name);
    endfunction

endclass