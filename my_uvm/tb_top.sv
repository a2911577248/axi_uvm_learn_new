module tb_top;
  //  UVM 
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  logic aclk,aresetn;

  initial begin
    $fsdbDumpfile("tb.fsdb");
    $fsdbDumpvars(0, tb_top);
  end

  initial begin
    aclk = 0;
    forever #5 aclk = ~aclk; 
  end

  initial begin
    aresetn = 0;
    #20 aresetn = 1;
  end

  axi_interface vif(aclk, aresetn);


  initial begin
    uvm_config_db#(virtual axi_interface)::set(null, "uvm_test_top.env.master_agent.drv", "vif", vif);
    run_test("base_test"); 
  end


  assign vif.awready = 1'b1; 
  assign vif.wready  = 1'b1;

  initial begin
    vif.bvalid = 0;
    vif.bresp  = 0; 
    forever begin
      @(posedge aclk);
      if (vif.wvalid && vif.wready) begin
        vif.bvalid <= 1'b1; 
        vif.bresp <= 1'b1;

      @(posedge aclk iff vif.bready == 1'b1);
        vif.bvalid <= 1'b0; 
      end
    end
  end


endmodule