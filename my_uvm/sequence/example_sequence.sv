class my_4kb_cross_scenario_seq extends basic_sequence; 
    `uvm_object_utils(my_4kb_cross_scenario_seq)
    
    function new(string name="my_4kb_cross_scenario_seq"); ... endfunction

    virtual task body();
        axi_write_seq w_seq;
        
        `uvm_info("SEQ_4KB", "Injecting 4KB cross boundary write...", UVM_LOW)
        

        `uvm_do_with(w_seq, { waddr == 32'h0FFC; wlen == 8'h03; })
        
    endtask
endclass