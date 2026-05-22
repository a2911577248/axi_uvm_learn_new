class axi_slave_driver extends uvm_driver #(axi_trans);
    `uvm_component_utils(axi_slave_driver)

    virtual axi_interface vif;
    reg [7:0]mem[int unsigned];


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axi_interface)::get(this, "", "vif", vif))begin
            `uvm_fatal("SLAVE_DRV","can't get virtual interface!")
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
            forever begin
                logic [31:0]temp_addr;
                logic [7:0] temp_len;
                int write_bytes;
                //logic [2:0] temp_size;
                //AW
                vif.awready <= 1;
                @(posedge vif.aclk iff vif.awvalid == 1'b1);
                temp_addr = vif.awaddr;
                temp_len = vif.awlen;
                vif.awready <= 0;
                write_bytes = 1 << vif.awsize;
                //W
                vif.wready <=1;
                for(int i=0; i <= temp_len; i = i+1)begin
                    @(posedge vif.aclk iff vif.wvalid == 1'b1);
                    for(int byte_idx = 0; byte_idx <= write_bytes; byte_idx = byte_idx + 1)begin
                        if(vif.wstrb[byte_idx])begin
                            mem[temp_addr + byte_idx] = vif.wdata[byte_idx * 8 +: 8];
                        end
                    end
                    temp_addr = temp_addr + write_bytes;
                end
                vif.wready <= 0;
                //B
                vif.bvalid <= 1'b1;
                vif.bresp <= 2'b00;
                @(posedge vif.aclk iff vif.bready == 1'b1);
                vif.bvalid <= 0;
            end

            forever begin
                logic [31:0]temp_addr;
                logic [7:0] temp_len;
                int read_bytes;
                //AR
                vif.arready <= 1;
                @(posedge vif.aclk iff vif.arvalid == 1'b1);
                vif.arready <= 0;
                temp_addr = vif.araddr;
                temp_len = vif.arlen;
                read_bytes = 1 << vif.arsize;
                //R
                vif.rvalid <= 1;
                vif.rresp <= 2'b00;

                for(int i=0; i <= temp_len; i = i+1)begin
                    logic [31:0] temp_rdata;
                    temp_rdata ='0;
                    for(int byte_idx = 0; byte_idx <= read_bytes; byte_idx = byte_idx + 1)begin
                        if(mem.exists(temp_addr + byte_idx))begin
                            temp_rdata[byte_idx * 8 +: 8] = mem[temp_addr + byte_idx];
                        end else begin
                            temp_rdata[byte_idx * 8 +: 8] = 8'hAB;
                        end                       
                    end
                    vif.rdata <= temp_rdata;
                    vif.rlast <= (i == temp_len);
                    @(posedge vif.aclk iff vif.rready == 1'b1);
                    temp_addr = temp_addr + read_bytes;
                end
                vif.rvalid <= 0;
                vif.rlast <= 1'b0;
            end

        join


    endtask

endclass