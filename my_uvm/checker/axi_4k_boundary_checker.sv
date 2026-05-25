import uvm_pkg::*;
`include "uvm_macros.svh"

interface axi_4k_boundary_checker(
    input aclk,
    input aresetn,
    input awvalid,
    input [31:0]awaddr,
    input [7:0] awlen,
    input [2:0] awsize

);

    logic [31:0] total_bytes;
    logic [31:0] end_addr;

    assign total_bytes = 32'(awlen+1) << awsize;
    assign end_addr = awaddr + total_bytes -1;


    property p_4k_boundary;
        @(posedge aclk) disable iff (!aresetn)
        awvalid |-> awaddr[31:12] == end_addr[31:12];
    endproperty

    a_4k_boundary:assert property (p_4k_boundary)
        else begin
            `uvm_error("4k_BOUNDARY_CHECKER", "p_4k_boundary error")
        end;

endinterface