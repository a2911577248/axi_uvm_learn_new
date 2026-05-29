    import uvm_pkg::*;
    `include "uvm_macros.svh"
interface outstanding_interleadving_checker(
    input aclk,
    input aresetn,
    input [3:0]arid,
    input [7:0]arlen,
    input arvalid,
    input arready,
    input rvalid,
    input rready,
    input [3:0]rid,
    input rlast

);

    int unsigned expected_len_q[int][$];
    int unsigned active_beat_cnt[int];

    always @(posedge aclk) begin
        if (aresetn && arvalid && arready) begin
            expected_len_q[arid].push_back(arlen); 
        end
    end

    always @(posedge aclk) begin
        if (aresetn && rvalid && rready) begin
            
            // 【基础检查】：这个 ID 必须有未完成的请求
            if (!(expected_len_q.exists(rid) && expected_len_q[rid].size() > 0)) begin
                `uvm_error("outstanding_interleadving_checker", $sformatf("Protocol Error: R data received for ID=%0h, but no outstanding AR exists!", rid))
            end else begin
                
                // 初始化这个 ID 的拍数计数器
                if (!active_beat_cnt.exists(rid)) active_beat_cnt[rid] = 0;

                if (rlast) begin
                    // 【核心校验】：当 RLAST 拉高时，当前累计的拍数，必须等于该 ID 队列【最头部】的那笔请求的 ARLEN！
                    if (active_beat_cnt[rid] != expected_len_q[rid][0]) begin
                        `uvm_error("outstanding_interleadving_checker", $sformatf("Protocol Error: RLAST asserted for ID=%0h at beat %0d, but expected ARLEN was %0d!", 
                                            rid, active_beat_cnt[rid], expected_len_q[rid][0]))
                    end
                    
                    // 完美完成了一笔 Burst。把队头请求弹出，清空计数器。
                    // 这样该 ID 的下一笔 R 数据，就会自动去匹配队列里的下一个 ARLEN。
                    void'(expected_len_q[rid].pop_front());
                    active_beat_cnt.delete(rid);
                    
                end else begin
                    // 还没结束，拍数 + 1
                    active_beat_cnt[rid]++;

                end
            end
        end
    end    


endinterface