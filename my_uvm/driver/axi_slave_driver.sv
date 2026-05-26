class axi_slave_driver extends uvm_driver #(axi_trans);
    `uvm_component_utils(axi_slave_driver)

    virtual axi_interface vif;
    axi_config axi_cfg;
    reg [7:0]mem[int unsigned];
    logic [31:0] max_illegal_addr;


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
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.awready <= 0;
        vif.wready  <= 0;
        vif.bvalid  <= 0;
        vif.arready <= 0;
        vif.rvalid  <= 0;    


        wait(vif.aresetn);


        //W
        fork
            forever begin
                logic [31:0]temp_addr;
                logic [7:0] temp_len;
                logic is_illegal;
                int write_bytes;
                //logic [2:0] temp_size;

                //AW
                is_illegal = 1'b0;
                vif.awready <= 0; 

                @(posedge vif.aclk iff vif.awvalid == 1'b1);
                
                if (axi_cfg.delay_en) begin
                    repeat($urandom_range(0, axi_cfg.max_delay)) @(posedge vif.aclk);
                end

                
                vif.awready <= 1;
                @(posedge vif.aclk); 

                temp_addr = vif.awaddr;
                temp_len = vif.awlen;
                vif.awready <= 0; 
                write_bytes = 1 << vif.awsize;
                //W
                for(int i=0; i <= temp_len; i = i+1)begin
                    vif.wready <= 0;
                    @(posedge vif.aclk iff vif.wvalid == 1'b1); 
                    
                    if (axi_cfg.delay_en) begin
                        repeat($urandom_range(0, axi_cfg.max_delay)) @(posedge vif.aclk);
                    end
                    
                    vif.wready <= 1;
                    @(posedge vif.aclk); 
                    vif.wready <= 0;     
                    
                    for(int byte_idx = 0; byte_idx < write_bytes; byte_idx = byte_idx + 1)begin
                        if(vif.wstrb[byte_idx])begin
                            if(temp_addr + byte_idx > max_illegal_addr)begin
                                is_illegal = 1'b1;
                            end else begin
                                mem[temp_addr + byte_idx] = vif.wdata[byte_idx * 8 +: 8];
                            end
                        end
                    end
                    temp_addr = temp_addr + write_bytes;
                end
                //B
                if (axi_cfg.delay_en) begin
                    repeat($urandom_range(0, axi_cfg.max_delay)) @(posedge vif.aclk);
                end
                
                vif.bvalid <= 1'b1;
                if(is_illegal)begin
                    vif.bresp <= 2'b10; // SLVERR (Slave Error)
                end else begin
                    vif.bresp <= 2'b00;
                end


                @(posedge vif.aclk iff vif.bready == 1'b1);
                vif.bvalid <= 0;
            end

            //R
            forever begin
                logic [31:0]temp_addr;
                logic [7:0] temp_len;
                int read_bytes;
                logic is_illegal;
                //AR
                is_illegal = 1'b0;
                vif.arready <= 0;
                
                @(posedge vif.aclk iff vif.arvalid == 1'b1);
                
                if (axi_cfg.delay_en) begin
                    repeat($urandom_range(0, axi_cfg.max_delay)) @(posedge vif.aclk);
                end
                
                vif.arready <= 1;
                @(posedge vif.aclk);
                vif.arready <= 0;
                
                temp_addr = vif.araddr;
                temp_len = vif.arlen;
                read_bytes = 1 << vif.arsize;
                //R
                for(int i=0; i <= temp_len; i = i+1)begin
                    logic [31:0] temp_rdata;
                    
                    if (axi_cfg.delay_en) begin
                        repeat($urandom_range(0, axi_cfg.max_delay)) @(posedge vif.aclk);
                    end
                    vif.rvalid <= 1;
                    temp_rdata ='0;
                    is_illegal = 1'b0;
                    for(int byte_idx = 0; byte_idx < read_bytes; byte_idx = byte_idx + 1)begin
                        if(temp_addr + byte_idx > max_illegal_addr)begin
                            is_illegal = 1'b1;
                        end else if(mem.exists(temp_addr + byte_idx))begin
                            temp_rdata[byte_idx * 8 +: 8] = mem[temp_addr + byte_idx];
                        end else begin
                            temp_rdata[byte_idx * 8 +: 8] = 8'hAB;
                        end                       
                    end
                    vif.rdata <= temp_rdata;
                    if(is_illegal) begin
                        vif.rresp <= 2'b10;
                    end else begin
                        vif.rresp <= 2'b00;
                    end
                    vif.rlast <= (i == temp_len);
                    @(posedge vif.aclk iff vif.rready == 1'b1); // 等待 master 的 rready 发生握手
                    vif.rvalid <= 0; // 握手后马上拉低
                    temp_addr = temp_addr + read_bytes;
                end
                vif.rlast <= 1'b0;
            end

        join


    endtask

endclass