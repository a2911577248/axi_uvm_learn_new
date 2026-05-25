interface axi_protocol_checker (
    input aclk,
    input aresetn,
    input [31:0]awaddr,
    input awvalid,
    input awready
);
    property p_axi_awaddr_stable;
        @(posedge aclk) disable iff (!aresetn)
        awvalid && !awready |=> $stable(awaddr);
    endproperty
    assert_axi_addr_stable:assert property (p_axi_awaddr_stable)
        else $error("[PROTOCOL ERROR] awvalid is high but addr not stable");

    // property p_axi_reset;
    //     @(posedge aclk)
    //     !aresetn |-> awvalid;
    // endproperty
    // assert_axi_resert:assert property (p_axi_reset)
    //     else $error("[PROTOCOL ERROR] !areset but valid is not down");

    property p_axi_aw_handshake_timeout;
        @(posedge aclk) disable iff (!aresetn)
        (awvalid && !awready) |-> ##[1:20] awready;
    endproperty
    assert_axi_aw_handshake_timeout:assert property (p_axi_aw_handshake_timeout)
        else begin
            $error("[PROTOCOL ERROR]  awready trapped for more than 20 cycles");
            $finish;
        end

endinterface