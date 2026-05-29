interface axi_burst_checker(
    input aclk,
    input aresetn,


    input [31:0]awaddr,
    input [7:0]awlen,
    input [2:0]awsize,
    input [1:0]awburst,
    input awvalid,
    input awready,

    input wready,
    input wvalid,
    input wlast,

    //todo ar burst checker
    input arvalid,
    input arready,
    input [7:0] arlen,

    input rready,
    input rvalid,
    input rlast
);



    typedef struct{
        logic [31:0] awaddr;
        logic [7:0] awlen;
        logic [2:0] awsize;
        logic [1:0] awburst;
    } aw_info_t;

    aw_info_t aw_info_q[$];
    logic [8:0] w_beat_numb;

    always_ff @(posedge aclk or negedge aresetn) begin
        aw_info_t temp_aw_info_t;
        if(!aresetn) begin
            aw_info_q.delete();
            w_beat_numb <= '0;
        end else begin
            if(awvalid && awready) begin
                temp_aw_info_t.awaddr = awaddr;
                temp_aw_info_t.awlen   = awlen;
                temp_aw_info_t.awsize  = awsize;
                temp_aw_info_t.awburst = awburst;
                aw_info_q.push_back(temp_aw_info_t);
            end

            if(wvalid && wready) begin
                if(aw_info_q.size() == 0) begin
                    `uvm_error("AXI_BURST_CHECKER", "write data handshake without outstanding AW")
                end else if(w_beat_numb == aw_info_q[0].awlen) begin
                    if(!wlast) begin
                        `uvm_error("AXI_BURST_CHECKER", "assert_wlast_missing")
                    end
                    w_beat_numb <= '0;
                    void'(aw_info_q.pop_front());
                end else begin
                    if(wlast) begin
                        `uvm_error("AXI_BURST_CHECKER", "assert_wlast_early")
                    end
                    w_beat_numb <= w_beat_numb + 1;
                end
            end
        end
    end



endinterface