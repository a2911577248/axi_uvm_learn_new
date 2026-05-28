import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_config extends uvm_object;
    `uvm_object_utils(axi_config)

    bit aw_delay_en = 0;
    bit w_delay_en = 0;
    bit b_delay_en = 0;
    bit ar_delay_en = 0;
    bit r_delay_en = 0;
    int max_delay =6;

    function new(string name = "axi_cfg");
        super.new(name);
    endfunction

endclass