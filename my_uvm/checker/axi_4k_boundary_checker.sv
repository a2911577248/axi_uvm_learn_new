import uvm_pkg::*;
`include "uvm_macros.svh"

interface axi_4k_boundary_checker(
    input aclk,
    input aresetn,
    input awvalid,
    input awready,
    input [31:0]awaddr,
    input [7:0] awlen,
    input [2:0] awsize,
    input [1:0] awburst

);

    logic [31:0] total_bytes;
    logic [31:0] burst_base;
    logic [31:0] end_addr;

    assign total_bytes = 32'(awlen+1) << awsize;

    always_comb begin
        burst_base = awaddr;
        end_addr = awaddr;

        case (awburst)
            2'b00: begin
                burst_base = awaddr;
                end_addr = awaddr;
            end

            2'b01: begin
                burst_base = awaddr;
                end_addr = awaddr + total_bytes - 1;
            end

            2'b10: begin
                burst_base = awaddr & ~(total_bytes - 1);
                end_addr = burst_base + total_bytes - 1;
            end

            default: begin
                burst_base = awaddr;
                end_addr = awaddr + total_bytes - 1;
            end
        endcase
    end

    property p_wrap_alignment;
        @(posedge aclk) disable iff (!aresetn)
        (awvalid && awready && awburst == 2'b10) |-> ((awaddr & (total_bytes - 1)) == 0);
    endproperty

    a_wrap_alignment: assert property (p_wrap_alignment)
        else begin
            `uvm_error("4k_BOUNDARY_CHECKER", "wrap burst address is not aligned to its total burst size")
        end;


    property p_4k_boundary;
        @(posedge aclk) disable iff (!aresetn)
        (awvalid && awready) |-> awaddr[31:12] == end_addr[31:12];
    endproperty

    a_4k_boundary:assert property (p_4k_boundary)
        else begin
            `uvm_error("4k_BOUNDARY_CHECKER", "p_4k_boundary error")
        end;

endinterface