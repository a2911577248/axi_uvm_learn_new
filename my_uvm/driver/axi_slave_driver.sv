class axi_slave_driver extends uvm_driver #(axi_trans);
    `uvm_component_utils(axi_slave_driver)

    virtual axi_interface vif;
    axi_config axi_cfg;
    reg [7:0]mem[int unsigned];
    logic [31:0] max_illegal_addr;

    axi_trans aw_q[$];
    axi_trans b_q[$];
    axi_trans ar_q[$];

    bit en_interleave = 0;


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axi_interface)::get(this, "", "vif", vif))begin
            `uvm_fatal("SLAVE_DRV","can't get virtual interface!")
        end
        if (!uvm_config_db#(logic [31:0])::get(this, "", "max_illegal_addr", max_illegal_addr))
            max_illegal_addr = 'hFFFF_FFFF;

        if(!uvm_config_db#(axi_config)::get(this,"","axi_cfg",axi_cfg))begin
            `uvm_info("DRV", "No config found, using default config", UVM_LOW)
            axi_cfg = axi_config::type_id::create("axi_cfg");
        end

        if($value$plusargs("EN_INTERLEAVE=%d", en_interleave))begin
            
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.awready <= 0;
        vif.wready  <= 0;
        vif.bvalid  <= 0;
        vif.arready <= 0;
        vif.rvalid  <= 0;    

        wait(vif.aresetn);

        fork 
            slave_aw();
            slave_w();
            slave_b();
            slave_ar();
            slave_r();
        join
    endtask

    virtual task slave_aw();
        vif.awready <= 0;
        forever begin
            if(axi_cfg.aw_delay_en && ($urandom_range(0, 100) < 30))begin
                vif.awready <= 0;
                repeat($urandom_range(1, axi_cfg.max_delay)) @(posedge vif.aclk);
            end

            vif.awready <= 1;
            @(posedge vif.aclk iff vif.awvalid == 1'b1);
            begin
                axi_trans tr = axi_trans::type_id::create("tr");
                tr.addr  = vif.awaddr;
                tr.len   = vif.awlen;
                tr.size  = vif.awsize;
                tr.id    = vif.awid;
                aw_q.push_back(tr);                
            end
        end
    endtask

    virtual task slave_w();
        vif.wready <= 0;
        forever begin
            axi_trans tr;
            logic [31:0] temp_addr;
            int write_bytes;
            logic is_illegal;

            wait(aw_q.size() > 0);
            tr = aw_q.pop_front();
            temp_addr = tr.addr;
            write_bytes = 1 << tr.size;
            is_illegal = 1'b0;

            for(int i=0; i <= tr.len; i=i+1)begin
                if(axi_cfg.w_delay_en && ($urandom_range(0,100) < 30))begin
                    vif.wready <= 0;
                    repeat($urandom_range(1,axi_cfg.max_delay)) @(posedge vif.aclk);
                end
            
                vif.wready <= 1;
                @(posedge vif.aclk iff vif.wvalid == 1'b1);

                for(int byte_idx = 0; byte_idx < write_bytes; byte_idx = byte_idx + 1)begin
                    if(vif.wstrb[byte_idx])begin
                        if(temp_addr + byte_idx > max_illegal_addr)begin
                            is_illegal = 1'b1;
                        end else begin
                            mem[temp_addr + byte_idx] = vif.wdata[byte_idx*8 +: 8];
                        end
                    end
                end
                temp_addr = temp_addr + write_bytes;
            end
            if(aw_q.size() == 0)begin
               vif.wready <= 0; 
            end
            tr.resp = is_illegal ? 2'b10:2'b00;
            b_q.push_back(tr);
        end     
    endtask

    virtual task slave_b();
        vif.bvalid <= 0;
        forever begin
            int pop_idx;
            axi_trans tr;

            wait(b_q.size() > 0);
            pop_idx = $urandom_range(0, b_q.size() - 1);
            tr = b_q[pop_idx];
            b_q.delete(pop_idx);

            if(axi_cfg.b_delay_en && $urandom_range(0,100) < 30)begin
                vif.bvalid <= 0;
                repeat($urandom_range(1,axi_cfg.max_delay)) @(posedge vif.aclk);
            end

            vif.bvalid <= 1;
            vif.bresp <= tr.resp;
            vif.bid <= tr.id;
            @(posedge vif.aclk iff (vif.bready == 1'b1));
            if(b_q.size() == 0)begin
                vif.bvalid <= 0;
            end
        end 

    endtask

    virtual task slave_ar();
        vif.arready <= 0;
        forever begin
            if(axi_cfg.ar_delay_en && ($urandom_range(0,100)) < 30)begin
                vif.arready <= 0;
                repeat($urandom_range(1,axi_cfg.max_delay)) @(posedge vif.aclk);
            end
        end

        vif.arready <= 1;
        @(posedge vif.aclk iff (vif.arvalid == 1'b1));
        begin
            axi_trans tr;
            tr = axi_trans::type_id::create("tr");
            tr.addr = vif.araddr;
            tr.len = vif.arlen;
            tr.size = vif.arsize;
            tr.id = vif.arid;
            ar_q.push_back(tr);
        end
    endtask

    virtual task slave_r();
        if(en_interleave)begin
            slave_r_interleaved();
        end else begin
            slave_r_non_interleaved();
        end
    endtask

    virtual task slave_r_non_interleaved();
        vif.rvalid <= 0;
        forever begin
            int pop_idx;
            axi_trans tr;
            logic [31:0] temp_addr;
            int read_bytes;
            logic is_illegal;

            wait(ar_q.size() > 0);
            pop_idx = $urandom_range(0, ar_q.size()-1);
            tr = ar_q[pop_idx];
            ar_q.delete(pop_idx);

            temp_addr = tr.addr;
            read_bytes = 1 << tr.size;

            for(int i=0; i <= tr.len; i++)begin
                logic [31:0]temp_rdata = '0;
                is_illegal = 1'b0;

                if(axi_cfg.r_delay_en && ($urandom_range(0,100)) < 30)begin
                    vif.rvalid <= 0;
                    repeat($urandom_range(1,axi_cfg.max_delay)) @(posedge vif.aclk);
                end

                for(int byte_idx; byte_idx < read_bytes; byte_idx = byte_idx + 1)begin
                    if(temp_addr + byte_idx > max_illegal_addr)begin
                        is_illegal = 1'b1;
                    end else begin
                        if(mem.exists(temp_addr + byte_idx)) temp_rdata[byte_idx * 8 +: 8] = mem[temp_addr + byte_idx];
                        else temp_rdata[byte_idx * 8 +: 8] = 8'hAB; 
                    end
                end

                vif.rvalid <= 1;
                vif.rid <=tr.id;
                vif.rdata <= temp_rdata;
                vif.rresp <= is_illegal ? 2'b10:2'b00;
                vif.rlast <= (i == tr.len);

                @(posedge vif.aclk iff vif.rready == 1'b1);
                temp_addr = temp_addr + read_bytes;
            end
            if(ar_q.size() == 0)begin
                vif.rvalid <= 0;
            end
            vif.rlast <= 0;
        end
    endtask

    virtual task slave_r_interleaved();
        axi_trans active_reads[$];
        logic [31:0] current_addr[int];
        int current_beats[int];
        
        vif.rvalid <= 0;
        forever begin
            int pick_idx;
            axi_trans tr;
            int read_bytes;
            logic is_illegal;
            logic [31:0] temp_rdata;

            while(ar_q.size() > 0)begin
                axi_trans new_tr;
                new_tr = ar_q.pop_front();
                active_reads.push_back(new_tr);
                current_beats[new_tr.id] = new_tr.len + 1;
            end

            if(active_reads.size() == 0)begin
                @(posedge vif.aclk);
                continue;
            end
            pick_idx = $urandom_range(0, active_reads.size() - 1);
            tr = active_reads[pick_idx];

            read_bytes = 1 << tr.size;
            is_illegal = 1'b0;
            temp_rdata = '0;

            if (axi_cfg.r_delay_en && ($urandom_range(0, 100) < 30)) begin
                vif.rvalid <= 0; 
                repeat($urandom_range(1, axi_cfg.max_delay)) @(posedge vif.aclk);
            end

            for(int byte_idx = 0; byte_idx < read_bytes; byte_idx++) begin
                if(current_addr[tr.id] + byte_idx > max_illegal_addr) begin
                    is_illegal = 1'b1;
                end else begin
                    if(mem.exists(current_addr[tr.id] + byte_idx)) 
                        temp_rdata[byte_idx * 8 +: 8] = mem[current_addr[tr.id] + byte_idx];
                    else temp_rdata[byte_idx * 8 +: 8] = 8'hAB; 
                end                  
            end

            vif.rvalid <= 1;
            vif.rid    <= tr.id;
            vif.rdata  <= temp_rdata;
            vif.rresp  <= is_illegal ? 2'b10 : 2'b00;
            vif.rlast  <= (current_beats[tr.id] == 1);

            @(posedge vif.aclk iff vif.rready == 1'b1);
            if(active_reads.size() == 0 && ar_q.size() == 0)begin
               vif.rvalid <= 0; 
            end

            current_addr[tr.id] = current_addr[tr.id] + read_bytes;
            current_beats[tr.id] = current_beats[tr.id] - 1;
            
            if (current_beats[tr.id] == 0) begin
                active_reads.delete(pick_idx);
                current_addr.delete(tr.id);
                current_beats.delete(tr.id);
            end
        end 
    endtask

endclass


