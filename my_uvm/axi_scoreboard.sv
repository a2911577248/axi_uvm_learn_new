import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_scoreboard)

    uvm_analysis_imp#(axi_trans, axi_scoreboard) imp;
    logic [31:0]ref_mem[int unsigned];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        imp = new("imp", this);
    endfunction

    virtual function void write(axi_trans tr);
        if(tr.is_write)begin
            ref_mem[tr.addr] = tr.data;
            `uvm_info("SCB",$sformatf("Record WRITE:addr='h%0h data='h%0h", tr.addr, tr.data), UVM_LOW)
        end else begin
            if(ref_mem.exists(tr.addr))begin
                if(ref_mem[tr.addr] == tr.data)begin
                    `uvm_info("SCB", "READ MATCH", UVM_LOW)
                end else begin
                    `uvm_error("SCB", $sformatf("READ MISMATCH ! ref_data='h%0h actual_data='h%0h",ref_mem[tr.addr], tr.data))
                end
            end else begin
                `uvm_warning("SCB", $sformatf("READ for uninitialized address 'h%0h", tr.addr))
            end
        end
    endfunction

endclass