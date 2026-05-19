interface axi_interface(input aclk, input aresetn);

    //AW
    logic [31:0] awaddr;
    logic        awvalid;
    logic        awready;

    //W
    logic [31:0] wdata;
    logic        wvalid;
    logic        wready;

    //B
    logic [1:0] bresp;
    logic       bvalid;
    logic       bready;

endinterface