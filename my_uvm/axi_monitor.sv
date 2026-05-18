import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass