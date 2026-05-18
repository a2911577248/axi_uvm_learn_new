import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_sequencer extends uvm_sequencer #(axi_trans);
    `uvm_component_utils(axi_sequencer);

    function new(string name, uvm_component parent);
        super.new(name, parent); //它是在调用父类 uvm_sequencer #(axi_trans) 的构造函数，并把当前构造函数接收的 name 和 parent 原封不动地传上去。
    endfunction

endclass