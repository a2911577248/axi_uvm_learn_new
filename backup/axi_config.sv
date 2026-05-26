import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_config extends uvm_object;
    `uvm_object_utils(axi_config)

    bit delay_en = 1;
    int max_delay =6;

    function new(string name = "axi_cfg");
        super.new(name);
    endfunction

endclass