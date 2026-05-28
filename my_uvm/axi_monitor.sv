//不支持先w后aw

import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_monitor)

    virtual axi_interface vif;
    uvm_analysis_port#(axi_trans) ap; 

    axi_trans pending_writes[int][$];
    axi_trans pending_reads[int][$];

    int w_expected_q[$];

    int r_beat_cnt[int];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axi_interface)::get(this, "", "vif", vif))begin
            `uvm_fatal("MON", "can't get virtual interface!")
        end
        ap = new("ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        wait(vif.aresetn == 1'b1);
        fork
            mon_aw();
            mon_w();
            mon_b();
            mon_ar();
            mon_r();
        join
    endtask

    virtual task mon_aw();
        forever begin
            axi_trans tr;
            @(posedge vif.aclk iff (vif.awvalid && vif.awready));
            tr = axi_trans::type_id::create("tr");
            tr.is_write = 1;
            tr.id = vif.awid;
            tr.addr = vif.awaddr;
            tr.len = vif.awlen;
            tr.size = vif.awsize;
            tr.burst = vif.awburst;
            tr.data = new[tr.len + 1];
            tr.wstrb = new[tr.len + 1];

            pending_writes[tr.id].push_back(tr);
            w_expected_q.push_back(tr.id);
        end
    endtask

    virtual task mon_w();
        int w_beat = 0;
        forever begin
            int current_id;
            axi_trans tr;
            @(posedge vif.aclk iff (vif.wready && vif.wvalid));
            if(w_expected_q.size() > 0)begin
                current_id = w_expected_q[0];
                if(pending_writes.exists(current_id) && pending_writes[current_id].size() > 0)begin
                    tr = pending_writes[current_id][0];

                    tr.data[w_beat] = vif.wdata;
                    tr.wstrb[w_beat] = vif.wstrb; 

                    if(vif.wlast)begin
                        w_beat = 0;
                        void'(w_expected_q.pop_front());
                    end else begin
                        w_beat = w_beat + 1;
                    end
                end else begin
                    `uvm_warning("MON_W", "W data received but corresponding AW transaction not found - may indicate protocol violation")
                    if(vif.wlast)begin
                        w_beat = 0;
                        void'(w_expected_q.pop_front());
                    end else begin
                        w_beat = w_beat + 1;
                    end
                end
            end else begin
                `uvm_warning("MON_W", "W data received but w_expected_q is empty - may indicate protocol violation or out-of-order write")
            end
        end
    endtask

    virtual task mon_b();
        forever begin
            axi_trans tr;
            @(posedge vif.aclk iff (vif.bvalid && vif.bready));
            if(pending_writes.exists(vif.bid) && pending_writes[vif.bid].size() > 0)begin
                tr = pending_writes[vif.bid].pop_front();
                tr.resp = vif.bresp;
                ap.write(tr);
            end else begin
                `uvm_error("MON_B", $sformatf("Received B response for unknown ID %0h", vif.bid))
            end
        end
    endtask

    virtual task mon_ar();
        forever begin
            axi_trans tr;
            @(posedge vif.aclk iff (vif.arvalid && vif.arready));
            tr = axi_trans::type_id::create("tr");
            tr.is_write = 0;
            tr.id = vif.arid;
            tr.addr = vif.araddr;
            tr.len = vif.arlen;
            tr.size = vif.arsize;
            tr.burst = vif.arburst;
            tr.data = new[vif.arlen + 1];

            pending_reads[tr.id].push_back(tr);
        end
    endtask

    virtual task mon_r();
        forever begin
            int beat;
            axi_trans tr;
            @(posedge vif.aclk iff (vif.rready && vif.rvalid));
            if(pending_reads.exists(vif.rid) && pending_reads[vif.rid].size() > 0)begin
                tr = pending_reads[vif.rid][0];

                if(!r_beat_cnt.exists(vif.rid)) r_beat_cnt[vif.rid] = 0;
                beat = r_beat_cnt[vif.rid];

                tr.data[beat] = vif.rdata;
                if(vif.rlast) tr.resp = vif.rresp;

                if(vif.rlast) begin
                    tr = pending_reads[vif.rid].pop_front();
                    r_beat_cnt.delete(vif.rid);
                    ap.write(tr);
                    // `uvm_info("MON", $sformatf("Captured READ: ID=%0h, Addr='h%0h", tr.id, tr.addr), UVM_LOW)
                end else begin
                    r_beat_cnt[vif.rid] = r_beat_cnt[vif.rid] + 1;
                end
            end else begin
                `uvm_error("MON_R", $sformatf("Received R data for unknown ID %0h", vif.rid))
            end
        end
    endtask

endclass