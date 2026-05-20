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
    


    logic        arvalid;
    logic        arready;
    logic [31:0] araddr;


    logic        rvalid;
    logic        rready;
    logic [31:0] rdata;
    logic [1:0]  rresp;

endinterface