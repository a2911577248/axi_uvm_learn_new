import uvm_pkg::*;
`include "uvm_macros.svh"

class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    axi_env env;
    virtual axi_interface vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi_env::type_id::create("env", this);
        if (!uvm_config_db#(virtual axi_interface)::get(this, "", "vif", vif)) begin
            `uvm_fatal("BASE_TEST", "can not get axi_interface")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        basic_sequence seq;
        seq = basic_sequence::type_id::create("seq", this);

        phase.raise_objection(this);
        `uvm_info("TEST", $sformatf("Running sequence: %s", seq.get_type_name()), UVM_LOW)
        seq.start(env.master_agent.sqr);
        phase.drop_objection(this);

    endtask

    virtual function void report_phase(uvm_phase phase);
        uvm_report_server server = uvm_report_server::get_server();
        int err_num = server.get_severity_count(UVM_ERROR);
        int fatal_num = server.get_severity_count(UVM_FATAL);

        string green = "\033[32m";
        string red = "\033[31m";
        string reset = "\033[0m";

        if (err_num == 0 && fatal_num == 0) begin
            `uvm_info("TEST_STATUS", $sformatf("\n---------------------------------------\n              %sTEST PASSED%s              \n---------------------------------------", green, reset), UVM_NONE)
        end else begin
            `uvm_error("TEST_STATUS", $sformatf("\n---------------------------------------\n              %sTEST FAILED%s              \n              ERRORS: %0d            \n---------------------------------------", red, reset, err_num))
        end
    endfunction

endclass