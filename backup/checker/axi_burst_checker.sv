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

    //W
    always_ff @(posedge aclk or negedge aresetn)begin
        if(!aresetn)begin
            aw_info_q.delete();
        end else begin
            aw_info_t temp_aw_info_t;
            if(awready && awvalid)begin
              temp_aw_info_t.awaddr = awaddr;
              temp_aw_info_t.awlen = awlen;
              temp_aw_info_t.awsize = awsize;
              temp_aw_info_t.awburst = awburst;
              aw_info_q.push_back(temp_aw_info_t);
            end
        end
    end

    always_ff@(posedge aclk or negedge aresetn)begin
        if(!aresetn)begin
            w_beat_numb <= '0;
        end else begin
            if(wready && wvalid)begin
                if(wlast)begin
                    w_beat_numb <= '0;
                    if(aw_info_q.size() >= 1)begin
                        void'(aw_info_q.pop_front());
                    end
                end else begin
                    w_beat_numb <= w_beat_numb + 1;
                end
            end
        end
    end

    logic [31:0] expect_awaddr;
    logic [7:0]  expect_awlen;
    logic [2:0]  expect_awsize;
    logic [1:0]  expect_awburst;
    logic is_w_last_beat;

    always_comb begin
        if (aw_info_q.size() > 0) begin
            expect_awaddr = aw_info_q[0].awaddr;
            expect_awlen   = aw_info_q[0].awlen;
            expect_awsize  = aw_info_q[0].awsize;
            expect_awburst = aw_info_q[0].awburst;
            is_w_last_beat = (w_beat_numb == expect_awlen);
        end else begin
            expect_awaddr = '0;
            expect_awlen   = '0;
            expect_awsize  = '0;
            expect_awburst = '0;
            is_w_last_beat = 1'b0;
        end
    end


    property p_wlast_must_in_last;
        @(posedge aclk) disable iff  (!aresetn)
        (wvalid && wready && is_w_last_beat) |-> wlast;
    endproperty

    property p_wlast_must_no_early;
        @(posedge aclk) disable iff (!aresetn)
        (wvalid && wready && !is_w_last_beat) |-> !wlast;
    endproperty

    assert_wlast_missing:assert property(p_wlast_must_in_last)
        else `uvm_error("AXI_BURST_CHECKER", "assert_wlast_missing")

    assert_wlast_early:assert property(p_wlast_must_no_early)
        else `uvm_error("AXI_BURST_CHECKER", "assert_wlast_early")



endinterface