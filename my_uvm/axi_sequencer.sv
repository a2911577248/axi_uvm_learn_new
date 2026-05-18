import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_sequencer extends uvm_sequencer #(axi_trans);
    `uvm_component_utils(axi_sequencer);

    function new(string name, uvm_component parent);
        super.new(name, parent); // uvm_sequencer #(axi_trans)  name  parent 
    endfunction

endclass