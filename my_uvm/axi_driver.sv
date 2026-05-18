import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_driver extends uvm_driver #(axi_trans);
    `uvm_component_utils(axi_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction


endclass