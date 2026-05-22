import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_scoreboard)

    uvm_analysis_imp#(axi_trans, axi_scoreboard) imp;
    logic [7:0]ref_mem[int unsigned];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        imp = new("imp", this);
    endfunction

    virtual function void write(axi_trans tr);
        //W
        if(tr.is_write)begin
            int byte_idx;
            int current_addr;

            byte_idx = 1 << tr.size;
            current_addr = 0;

            foreach(tr.data[i]) begin
                current_addr = tr.addr + i*byte_idx;
                for(int j = 0; j < byte_idx; j = j + 1)begin
                    if(tr.wstrb[j])begin
                        ref_mem[current_addr + j] = tr.data[i][j*8 +: 8];  
                    end
                end   
            end
            //`uvm_info("SCB",$sformatf("Record WRITE:addr='h%0h data='h%0h", tr.addr, tr.data), UVM_LOW)
        end 
        //R
        if(!tr.is_write)begin
            int current_addr;
            int byte_idx;
            logic [31:0] expect_data;

            byte_idx = 1 << tr.size;
            expect_data = '0;
            current_addr = 0;

            foreach(tr.data[i])begin
                current_addr = tr.addr + i*byte_idx;
                expect_data = '0;
                for(int j=0; j < byte_idx; j = j+1)begin
                    if(ref_mem.exists(current_addr + j))begin
                        expect_data[j*8 +: 8] = ref_mem[current_addr + j];   
                    end
                end
            
                if(expect_data == tr.data[i])begin
                    `uvm_info("SCB", "READ MATCH", UVM_LOW)
                end else begin
                    `uvm_error("SCB", $sformatf("READ MISMATCH! Addr='h%0h, Expect='h%0h, Actual='h%0h", 
                                                 current_addr, expect_data, tr.data[i]))
                end
            end


        end


    endfunction

endclass