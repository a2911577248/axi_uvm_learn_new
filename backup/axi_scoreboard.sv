import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_scoreboard)

    uvm_analysis_imp#(axi_trans, axi_scoreboard) imp;
    logic [7:0]ref_mem[int unsigned];
    logic [32:0] max_illegal_addr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        imp = new("imp", this);
        if (!uvm_config_db#(logic [31:0])::get(this, "", "max_illegal_addr", max_illegal_addr))
            max_illegal_addr = 'hFFFF_FFFF;
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
            logic [1:0] expected_resp;
            logic is_illegal;
            logic [31:0] expect_data;

            byte_idx = 1 << tr.size;
            expect_data = '0;
            current_addr = 0;
            expected_resp = 2'b00;
            is_illegal = 0;

            foreach(tr.data[i])begin
                current_addr = tr.addr + i*byte_idx;
                expect_data = '0;
                is_illegal = 0; 

                for(int j=0; j < byte_idx; j = j+1)begin
                    if(current_addr + j > max_illegal_addr) begin
                        is_illegal = 1;
                    end
                end

                if(is_illegal)begin
                    expected_resp = 2'b10;
                end else begin
                    expected_resp = 2'b00;
                end
                

                if (tr.resp !== expected_resp) begin
                    `uvm_error("SCB_RESP_ERR", $sformatf("Response Mismatch! Addr='h%0h, Expected=%0b, Actual=%0b", 
                                                        current_addr, expected_resp, tr.resp))
                end

                if (tr.resp !== 2'b00) begin
                    `uvm_info("SCB_RESP_MATCH", $sformatf("Skipping data check for Error resp %0b at Addr 'h%0h.", 
                                                        tr.resp, current_addr), UVM_LOW)
                    continue; 
                end


                for(int j=0; j < byte_idx; j = j+1)begin
                    if(ref_mem.exists(current_addr + j))begin
                        expect_data[j*8 +: 8] = ref_mem[current_addr + j];   
                    end else begin
                        expect_data[j*8 +: 8] = 8'hAB; 
                    end
                end

                if(expect_data == tr.data[i])begin
                    `uvm_info("SCB", $sformatf("READ MATCH at addr 'h%0h", current_addr), UVM_LOW)
                end else begin
                    `uvm_error("SCB", $sformatf("READ MISMATCH! Addr='h%0h, Expect='h%0h, Actual='h%0h", 
                                                 current_addr, expect_data, tr.data[i]))
                end

            end


        end


    endfunction

endclass