interface axi_interface(input aclk, input aresetn);

    //AW
    logic [31:0] awaddr;
    logic        awvalid;
    logic        awready;

    logic [7:0]  awlen;
    logic [2:0]  awsize;
    logic [1:0]  awburst;

    //W
    logic [31:0] wdata;
    logic        wvalid;
    logic        wready;

    logic        wlast;
    logic [3:0]  wstrb;

    //B
    logic [1:0] bresp;
    logic       bvalid;
    logic       bready;
    


    logic        arvalid;
    logic        arready;
    logic [31:0] araddr;

    logic [7:0]  arlen;
    logic [2:0]  arsize;
    logic [1:0]  arburst;

    logic        rvalid;
    logic        rready;
    logic [31:0] rdata;
    logic [1:0]  rresp;

    logic        rlast;

endinterface