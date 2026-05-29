import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_assert_catcher extends uvm_report_catcher;
    `uvm_object_utils(axi_assert_catcher)

    int unsigned trigger_count;
    string target_id;


    function new(string name = "axi_assert_catcher");
        super.new(name);
        trigger_count = 0;
    endfunction

    function void set_target_id(string id);
        target_id = id;
        trigger_count = 0;
    endfunction

    virtual function action_e catch();
        if (get_severity() == UVM_ERROR && get_id() == target_id) begin
            trigger_count++;
            set_severity(UVM_INFO);
            set_message({"[EXPECTED_ASSERT_ERROR] ", get_message()});    
            return THROW;
        end
        return THROW;
    endfunction
endclass

class axi_base_err_inject_seq extends basic_sequence;
    `uvm_object_utils(axi_base_err_inject_seq)   

    axi_assert_catcher m_catcher;
    virtual axi_interface vif; 
    axi_write_seq w_seq;
    axi_read_seq  r_seq;
    int unsigned expect_error_num;
    string expect_error_id;

    function new(string name = "base_err_inject_seq");
        super.new(name);
    endfunction

    virtual task expect_assert_begin();
        if(!$value$plusargs("EXPECT_ERROR_ID=%s", expect_error_id))begin
            expect_error_id = "AXI_PROT_ERR_STABLE";
        end

        if (m_catcher == null) begin
            m_catcher = axi_assert_catcher::type_id::create("m_catcher");  
        end
        m_catcher.set_target_id(expect_error_id);
        uvm_report_cb::add(null, m_catcher);
    endtask

    virtual task expect_assert_end();  
        #1ns;

        uvm_report_cb::delete(null, m_catcher);

        if(!$value$plusargs("EXPECT_ERROR_NUM=%d", expect_error_num))begin
            expect_error_num = 0;
        end

        if (m_catcher.trigger_count != expect_error_num) begin
            `uvm_error("ERR_INJECT_FAIL", $sformatf("Error injection failed! Expected assertion '%s' did NOT fire!", m_catcher.target_id))
        end else begin
            `uvm_info("ERR_INJECT_PASS", $sformatf("Success! Assertion '%s' fired %0d times as expected.", m_catcher.target_id, m_catcher.trigger_count), UVM_LOW)
        end
    endtask


    virtual task body();
        bit [31:0] cfg_waddr;
        bit [7:0]  cfg_wlen;
        bit [2:0]  cfg_wsize;
        bit [1:0]  cfg_burst;

        if(!uvm_config_db#(virtual axi_interface)::get(null, "*", "vif", vif))
            `uvm_fatal("SEQ_VIOLATION", "Failed to get virtual interface 'vif'")

        if (!$value$plusargs("START_ADDR=%h", cfg_waddr)) begin
            cfg_waddr = 32'h0100; 
        end
        
        if (!$value$plusargs("BURST_LEN=%d", cfg_wlen)) begin
            cfg_wlen = 8'h03; 
        end

        if (!$value$plusargs("BURST_TYPE=%d", cfg_burst)) begin
            cfg_burst = axi_trans::BURST_INCR;
        end

        cfg_wsize = 3'b010;

        expect_assert_begin();

            begin
                w_seq = axi_write_seq::type_id::create("w_seq");
                // r_seq = axi_read_seq::type_id::create("r_seq");
                if(!w_seq.randomize() with {
                    waddr == cfg_waddr;
                    wlen == cfg_wlen;
                    wsize == cfg_wsize;
                    wburst == cfg_burst;
                }) begin
                `uvm_error("axi_violation_seq_randomize", "w_seq randomize failed!")
                end
                w_seq.start(get_sequencer(), this);
            end
            begin
                w_seq = axi_write_seq::type_id::create("w_seq");
                // r_seq = axi_read_seq::type_id::create("r_seq");
                if(!w_seq.randomize() with {
                    waddr == cfg_waddr;
                    wlen == cfg_wlen;
                    wsize == cfg_wsize;
                    wburst == cfg_burst;
                }) begin
                `uvm_error("axi_violation_seq_randomize", "w_seq randomize failed!")
                end
                w_seq.start(get_sequencer(), this);
            end
            begin
                w_seq = axi_write_seq::type_id::create("w_seq");
                // r_seq = axi_read_seq::type_id::create("r_seq");
                if(!w_seq.randomize() with {
                    waddr == cfg_waddr;
                    wlen == cfg_wlen;
                    wsize == cfg_wsize;
                    wburst == cfg_burst;
                }) begin
                `uvm_error("axi_violation_seq_randomize", "w_seq randomize failed!")
                end
                w_seq.start(get_sequencer(), this);
            end

        repeat (3) @(posedge vif.aclk iff (vif.bvalid == 1'b1 && vif.bready == 1'b1));

        expect_assert_end();  
    endtask

endclass