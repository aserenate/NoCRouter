`timescale 1ns / 1ps

import noc_params::*;

class random_transaction;
    rand bit [ADDR_NETWORK-1:0] sub_network;
    rand bit [DEST_ADDR_SIZE_X-1:0] x_dest;
    rand bit [DEST_ADDR_SIZE_Y-1:0] y_dest;
    // rand bit [PORT_SIZE-1:0] inport_id;
    rand bit [VC_SIZE-1:0] vc_id;
    rand bit [3:0] pkt_size;
    rand bit [2:0] wait_time;

    constraint c_dist{
        sub_network inside {[0 : NETWORK_NUM-1]};
        x_dest inside {[0:MESH_SIZE_X-1]};
        y_dest inside {[0:MESH_SIZE_Y-1]};
        // inport_id inside {[0:PORT_NUM-1]};
        vc_id inside {[0:VC_NUM-1]};
        wait_time dist {0:=6, [1:7]:/4};
        pkt_size inside{[1:15]};
    }
endclass

typedef struct packed {
    int sub_network;
    int x_dest;
    int y_dest;
    // bit [PORT_SIZE-1:0] inport_id;
    bit [VC_SIZE-1:0] vc_id;
    int pkt_size;
    int wait_time;
} transaction;

class data_input;
    //    x_dest = {1,1};
    //    y_dest = {1,1};
    //    test_port_num = {1,3};
    //    packet_id = {0,1};
    //    vc_num = {0,0};
    //    pkt_size = {6,5};
    //    wait_time = {3,4};
    
    int sub_network[$];
    int x_dest[$];
    int y_dest[$];
    // bit [PORT_SIZE-1:0] test_port_num[$];
    bit [VC_SIZE-1:0] vc_num [$];
    int pkt_size[$];
    int wait_time[$];

    random_transaction ran_trans;

    function void init();
        ran_trans = new();
    endfunction
    
    function void push(transaction trans);
        this.sub_network.push_back(trans.sub_network);
        this.x_dest.push_back(trans.x_dest);
        this.y_dest.push_back(trans.y_dest);
        // this.test_port_num.push_back(trans.inport_id);
        this.vc_num.push_back(trans.vc_id);
        this.pkt_size.push_back(trans.pkt_size);
        this.wait_time.push_back(trans.wait_time);
    endfunction

    function void rand_push();
        ran_trans.randomize();
        this.sub_network.push_back(ran_trans.sub_network);
        this.x_dest.push_back(ran_trans.x_dest);
        this.y_dest.push_back(ran_trans.y_dest);
        // this.test_port_num.push_back(ran_trans.inport_id);
        this.vc_num.push_back(ran_trans.vc_id);
        this.pkt_size.push_back(ran_trans.pkt_size);
        this.wait_time.push_back(ran_trans.wait_time);
        $display("sn:%d, xd:%d, yd:%d, vc:%d, ps:%d, wt:%d.", ran_trans.sub_network, ran_trans.x_dest, ran_trans.y_dest, ran_trans.vc_id, ran_trans.pkt_size, ran_trans.wait_time);
        $display("size:%d.", this.x_dest.size());
    endfunction
endclass

module tb_router_wxy;

    // Testbench signals
    flit_t flit_written[2*PORT_NUM];
    flit_t flit_read[2*PORT_NUM];
    flit_t packet_queue[2*PORT_NUM][$];
    int outID_queue[2*PORT_NUM][$];

    data_input data_info_in;

    mailbox #(flit_t) flit_gen;
    
    // Testbench input
    int x_curr, y_curr;
    // int pkt_size[$], wait_time[$], x_dest[$], y_dest[$];
    logic [PORT_SIZE:0] test_port_num[$];
    // logic [VC_SIZE-1:0] vc_num [$];

    int flit_num[$], rest_time[$], packet_id[$];

    // Testbench control
    logic [2*PORT_NUM-1:0] insert_not_compl;
    int recv_num;

    logic clk;
    logic rst;
    wire [VC_NUM-1:0] error_o [2*PORT_NUM-1:0];

    //connections from upstream
    flit_t data_out [2*PORT_NUM-1:0];
    logic [2*PORT_NUM-1:0] valid_flit_out;
    logic [2*PORT_NUM-1:0] [VC_NUM-1:0] on_off_in;
    logic [2*PORT_NUM-1:0] [VC_NUM-1:0] is_allocatable_in;

    //connections from downstream
    flit_t data_in [2*PORT_NUM-1:0];
    logic valid_flit_in [2*PORT_NUM-1:0];
    logic [VC_NUM-1:0] on_off_out [2*PORT_NUM-1:0];
    logic [VC_NUM-1:0] is_allocatable_out [2*PORT_NUM-1:0];

    //DUT Interfaces Instantiation
    router2router local_up_0();
    router2router local_up_1();
    router2router north_up_0();
    router2router north_up_1();
    router2router south_up_0();
    router2router south_up_1();
    router2router west_up_0();
    router2router west_up_1();
    router2router east_up_0();
    router2router east_up_1();
    router2router local_down_0();
    router2router local_down_1();
    router2router north_down_0();
    router2router north_down_1();
    router2router south_down_0();
    router2router south_down_1();
    router2router west_down_0();
    router2router west_down_1();
    router2router east_down_0();
    router2router east_down_1();

    initial
    begin
        $display("START");
        dump_output();
        initialize();
        clear_reset();
        
        x_curr = 0;
        y_curr = 0;
        recv_num = 0;
        fork
            begin
                /*
                Test #1
                */
                repeat(30) begin
                    $display("\n----- NEW TEST @ %d -----", $time);
                    data_info_in = new();
                    data_info_in.init();
                    test_port_num = {0, 1};
                    packet_id = {0, 1};
                    generate_packet(2);
                    test();
                end
                $display("[All tests PASSED]");
                #20 $finish;
            end
            begin
                #1000000 $finish;
            end
        join_any
    end

    // Initialize signals
    task initialize();
        clk     <= 0;
        rst     = 1;
    endtask

    task generate_packet(int pkt_num);
        automatic int i;
        for (i=0; i<pkt_num; i++)
            data_info_in.rand_push();
    endtask
    
    // Clock update
    always #5 clk = ~clk;
    
    // De-assert the reset signal
    task clear_reset();
        @(posedge clk);
            rst <= 0;
    endtask

    task initTest();
        automatic int i,j;
        for(i=0;i<2*PORT_NUM;i++)
        begin
            valid_flit_in[i]    = 0;
            flit_num[i]         = 0;
            insert_not_compl[i] = 0;
            rest_time[i]        = 0;
            
            for(j=0; j<VC_NUM; j++)
            begin
                is_allocatable_in[i][j] = 1;    // means that downstream router is always available
                on_off_in[i][j] = 1;            // always do "read" operation from the router          
            end
        end

        for(i=0; i<test_port_num.size(); i++)    
            insert_not_compl[test_port_num[i]] = 1;
    endtask

    function bit unsigned checkEndConditions();
        automatic int i, pid;
        for(i = 0; i < test_port_num.size(); i++)
        begin
            if(packet_queue[i].size()>0 | insert_not_compl[test_port_num[i]])
                return 1; // not end
        end
        return 0; // end
    endfunction

    /*
    Create a flit to be written in both DUT and packet queue, with the given flit label and packet number in 
    the port identifier passed as port_id parameter.
    The flit to be written is created accordingly to its label, that is, HEAD and HEADTAIL flits are different
    with respect to BODY and TAIL ones.
    The last parameters, id and pkt_id, respectively refer to the identifier of the test case and the id of the packet 
    that will be inserted.
    */
    task automatic create_flit(input flit_label_t lab, input logic [PORT_SIZE-1:0] port_id, input integer id, input int pkt_id);
        flit_written[port_id].flit_label = lab;
        flit_written[port_id].vc_id      = data_info_in.vc_num[id];
        if(lab == HEAD | lab == HEADTAIL)
            begin
                flit_written[port_id].data.head_data.sub_network  = data_info_in.sub_network[id];
                flit_written[port_id].data.head_data.x_dest  = data_info_in.x_dest[id];
                flit_written[port_id].data.head_data.y_dest  = data_info_in.y_dest[id];
                flit_written[port_id].data.head_data.head_pl = pkt_id;
            end
        else
                flit_written[port_id].data.bt_pl = pkt_id;
    endtask
    
    /*
    Write flit into the DUT module in the proper port, given by the port identifier as input;
    while writing a flit into a port, the relative valid flag is set to 1.
    The last parameters, id and pkt_id, respectively refer to the identifier of the test case and the id of the packet 
    that will be inserted.
    Finally, the push task is called.
    */
    task automatic write_flit(input logic [PORT_SIZE-1:0] port_id, input integer pkt_id, input integer id);
        begin
            valid_flit_in[port_id]  <= 1;
            data_in[port_id]        <= flit_written[port_id];
        end
        push_flit(port_id, pkt_id, id);
    endtask

    /*
    Push the actual flit into the proper queue only under specific conditions.
    In particular, the push operation is done if the HEAD flit hasn't been inserted yet or
    the flit to insert is not an HEAD one (i.e. multiple_head==0).
    The two last parameters, id and pkt_id, respectively refer to the identifier of the test case and the id of the packet 
    that will be inserted.
    */
    task automatic push_flit(input logic [PORT_SIZE-1:0] port_id, input integer pkt_id, input int id);
        $display("push @(%d), dest(%d, %d, %d), dest_port %d, pktid %d", $time, data_info_in.sub_network[id], data_info_in.x_dest[id], data_info_in.y_dest[id], computeOutport(data_info_in.sub_network[id], data_info_in.x_dest[id], data_info_in.y_dest[id]), pkt_id);
        packet_queue[pkt_id].push_back(flit_written[port_id]);
        outID_queue[pkt_id].push_back(computeOutport(data_info_in.sub_network[id], data_info_in.x_dest[id], data_info_in.y_dest[id]));
        $display("Pushed flit, queue size %d", packet_queue[pkt_id].size());
    endtask

    /*
    The function checks whether the label and the content of the two given flits are equal or not.
    Notice that the check doesn't consider the vc identifier, which is computed by the internal SA module.
    The objective in this case is only to verify that the packet exiting from the router maintains the same destionation
    address and data payload.
    */
    function bit checkFlitFields(flit_t flit_read, flit_t flit_out);
        if(flit_read.flit_label === flit_out.flit_label & 
            flit_read.data === flit_out.data)
            return 1;
        return 0;
    endfunction

    /*
    This task is responsible of understanding the type of the next flit that will be inserted
    and calling the proper writing task according to some conditions.
    */
    task insertFlit();
        automatic int i,j, pkt_id, p_size;
        automatic logic [PORT_SIZE:0] port_id;
    
        for(i=0; i<test_port_num.size(); i++)
        begin // 遍历每一个待发出去的数据包
            for(j=0; j<PORT_SIZE+1; j++)
            begin
                port_id[j] = test_port_num[i][j];
            end
            // port_id: packet输入的port编号
            // pkt_id: packet的编码号
            // p_size: packet包含的Flit数目
            pkt_id = int'(packet_id[i]);
            p_size = data_info_in.pkt_size[i];

            if(p_size == 1 & insert_not_compl[port_id]) begin : HEADTAIL_FLIT
                flit_num[port_id]++;
                create_flit(HEADTAIL, port_id, i, pkt_id);
                write_flit(port_id, pkt_id, i);
                insert_not_compl[port_id] <= 0;
            end
            else begin : NOT_HEADTAIL_FLIT
                if(rest_time[port_id] == 0 & insert_not_compl[port_id] & on_off_out[port_id][data_info_in.vc_num[i]]) begin
                    // 数据包等待时间满足，并且还没有发完，并且输入的port的vc可以被写入
                    flit_num[port_id]++;
                    if (int'(flit_num[port_id]) == 1) // HEAD_FLIT
                        create_flit(HEAD, port_id, i, pkt_id);
                    else if (int'(flit_num[port_id]) == p_size) begin // TAIL_FLIT
                        create_flit(TAIL, port_id, i, pkt_id);
                        insert_not_compl[port_id] <= 0;
                    end
                    else
                        create_flit(BODY, port_id, i, pkt_id);
                    write_flit(port_id, pkt_id, i);
                    rest_time[port_id] = data_info_in.wait_time[port_id];
                end
                else begin
                    valid_flit_in[port_id] <= 0;
                    if (rest_time[port_id] > 0)
                        rest_time[port_id]--;
                end
            end
        end //end for
    endtask
    
    /*
    Checks the correspondance between the flit extracted from the queue and the one in data_o; this check is done for all the port where
    the flit in output is valid. 
    If the check goes wrong an error message is displayed and the testbench ends.
    */
    task checkFlits();
        automatic  int i, pkt_id, outport_id;
        automatic logic [PORT_SIZE-1:0] port_id;
        automatic flit_t flit_read;
        for (i=0; i<2*PORT_NUM; i++) begin
            if(valid_flit_out[i]) begin
                if (data_out[i].flit_label == HEAD || data_out[i].flit_label == HEADTAIL)
                    pkt_id = data_out[i].data.head_data.head_pl;
                else
                    pkt_id = data_out[i].data.bt_pl;
                
                flit_read = packet_queue[pkt_id].pop_front();
                outport_id = outID_queue[pkt_id].pop_front();
                recv_num ++;
                if(~checkFlitFields(flit_read, data_out[i]))
                begin
                    $display("[READ] FAILED DATA NOT EQUAL %d", $time);
                    #10 $finish;
                end
                else if (outport_id != i)
                begin
                    $display("[READ] FAILED Route error, rtl %d, tb %d,  %d", i, outport_id, $time);
                    #10 $finish;
                end
                else
                    $display("[READ] PASSED %d, RECV NUM %d, pkt_id %d", $time, recv_num, pkt_id);
                
            end
        end
        
        
    endtask

    task test();
        initTest();
        while(checkEndConditions()) @(posedge clk)
        begin            
            insertFlit();
            @(negedge clk)
            checkFlits();
        end
    endtask

    /*
    Compute the outport for the current packet according to
    the position of the router into the mesh and the destionation positions.
    */
    function int computeOutport(input int dest_sub_network, input int xdest, input int ydest);
        automatic int x_off, y_off, res;
        x_off = xdest - x_curr;
        y_off = ydest - y_curr;
        if(x_off < 0)
            res = 3*2+dest_sub_network; //WEST
        else if (x_off > 0)
            res = 4*2+dest_sub_network; //EAST
        else if (y_off < 0)
            res = 1*2+dest_sub_network; //NORTH
        else if (y_off > 0)
            res = 2*2+dest_sub_network; //SOUTH
        else // x_off=0 and y_off=0
            res = 0*2+dest_sub_network; //LOCAL
        $display("dest_sub_network:%d; xdest:%d; ydest:%d; x_off:%d; y_off:%d; res:%d", dest_sub_network, xdest, ydest, x_off, y_off, res);
        return res;
    endfunction

    // Output dump
    task dump_output();
        $vcdplusfile("simv.vpd");
        $vcdplusmemon;
        $vcdpluson;
    endtask

    //DUT Instantiation
    chiplet_router #(
        .BUFFER_SIZE(8),
        .X_CURRENT(0),
        .Y_CURRENT(0)
    )
    chiplet_router_dut (
        .clk(clk),
        .rst(rst),
        //router2router.upstream 
        .router_if_local_up_0(local_up_0),
        .router_if_local_up_1(local_up_1),
        .router_if_north_up_0(north_up_0),
        .router_if_north_up_1(north_up_1),
        .router_if_south_up_0(south_up_0),
        .router_if_south_up_1(south_up_1),
        .router_if_west_up_0(west_up_0),
        .router_if_west_up_1(west_up_1),
        .router_if_east_up_0(east_up_0),
        .router_if_east_up_1(east_up_1),
        //router2router.downstream
        .router_if_local_down_0(local_down_0),
        .router_if_local_down_1(local_down_1),
        .router_if_north_down_0(north_down_0),
        .router_if_north_down_1(north_down_1),
        .router_if_south_down_0(south_down_0),
        .router_if_south_down_1(south_down_1),
        .router_if_west_down_0(west_down_0),
        .router_if_west_down_1(west_down_1),
        .router_if_east_down_0(east_down_0),
        .router_if_east_down_1(east_down_1),
        .error_o(error_o)
    );

    routers_mock routers_mock (
        .router_if_local_up_0(local_down_0),
        .router_if_local_up_1(local_down_1),
        .router_if_north_up_0(north_down_0),
        .router_if_north_up_1(north_down_1),
        .router_if_south_up_0(south_down_0),
        .router_if_south_up_1(south_down_1),
        .router_if_west_up_0(west_down_0),
        .router_if_west_up_1(west_down_1),
        .router_if_east_up_0(east_down_0),
        .router_if_east_up_1(east_down_1),
        .router_if_local_down_0(local_up_0),
        .router_if_local_down_1(local_up_1),
        .router_if_north_down_0(north_up_0),
        .router_if_north_down_1(north_up_1),
        .router_if_south_down_0(south_up_0),
        .router_if_south_down_1(south_up_1),
        .router_if_west_down_0(west_up_0),
        .router_if_west_down_1(west_up_1),
        .router_if_east_down_0(east_up_0),
        .router_if_east_down_1(east_up_1),
        .data_out(data_out),
        .is_valid_out(valid_flit_out),
        .is_on_off_in(on_off_in),
        .is_allocatable_in(is_allocatable_in),
        .data_in(data_in),
        .is_valid_in(valid_flit_in),
        .is_on_off_out(on_off_out),
        .is_allocatable_out(is_allocatable_out)
    );
endmodule

/*
    ROUTERS MOCK MODULE
*/
module routers_mock #()
(
    router2router.upstream router_if_local_up_0,
    router2router.upstream router_if_local_up_1,
    router2router.upstream router_if_north_up_0,
    router2router.upstream router_if_north_up_1,
    router2router.upstream router_if_south_up_0,
    router2router.upstream router_if_south_up_1,
    router2router.upstream router_if_west_up_0,
    router2router.upstream router_if_west_up_1,
    router2router.upstream router_if_east_up_0,
    router2router.upstream router_if_east_up_1,
    router2router.downstream router_if_local_down_0,
    router2router.downstream router_if_local_down_1,
    router2router.downstream router_if_north_down_0,
    router2router.downstream router_if_north_down_1,
    router2router.downstream router_if_south_down_0,
    router2router.downstream router_if_south_down_1,
    router2router.downstream router_if_west_down_0,
    router2router.downstream router_if_west_down_1,
    router2router.downstream router_if_east_down_0,
    router2router.downstream router_if_east_down_1,

    //ports to propagate to downstream interfaces
    output flit_t data_out [2*PORT_NUM-1:0],
    output logic [2*PORT_NUM-1:0] is_valid_out,
    input logic [2*PORT_NUM-1:0] [VC_NUM-1:0] is_on_off_in,
    input logic [2*PORT_NUM-1:0] [VC_NUM-1:0] is_allocatable_in,

    //ports to propagate to upstream interfaces
    input flit_t data_in [2*PORT_NUM-1:0],
    input logic is_valid_in [2*PORT_NUM-1:0],
    output logic [VC_NUM-1:0] is_on_off_out [2*PORT_NUM-1:0],
    output logic [VC_NUM-1:0] is_allocatable_out [2*PORT_NUM-1:0]
);

    always_comb
    begin
       
        router_if_local_up_0.data = data_in[LOCAL*2+0];
        router_if_local_up_1.data = data_in[LOCAL*2+1];
        router_if_north_up_0.data = data_in[NORTH*2+0];
        router_if_north_up_1.data = data_in[NORTH*2+1];
        router_if_south_up_0.data = data_in[SOUTH*2+0];
        router_if_south_up_1.data = data_in[SOUTH*2+1];
        router_if_west_up_0.data  = data_in[WEST*2+0];
        router_if_west_up_1.data  = data_in[WEST*2+1];
        router_if_east_up_0.data  = data_in[EAST*2+0];
        router_if_east_up_1.data  = data_in[EAST*2+1];
        
        router_if_local_up_0.is_valid = is_valid_in[LOCAL*2+0];
        router_if_local_up_1.is_valid = is_valid_in[LOCAL*2+1];
        router_if_north_up_0.is_valid = is_valid_in[NORTH*2+0];
        router_if_north_up_1.is_valid = is_valid_in[NORTH*2+1];
        router_if_south_up_0.is_valid = is_valid_in[SOUTH*2+0];
        router_if_south_up_1.is_valid = is_valid_in[SOUTH*2+1];
        router_if_west_up_0.is_valid  = is_valid_in[WEST*2+0];
        router_if_west_up_1.is_valid  = is_valid_in[WEST*2+1];
        router_if_east_up_0.is_valid  = is_valid_in[EAST*2+0];
        router_if_east_up_1.is_valid  = is_valid_in[EAST*2+1];
        
        is_on_off_out[LOCAL*2+0] = router_if_local_up_0.is_on_off;
        is_on_off_out[LOCAL*2+1] = router_if_local_up_1.is_on_off;
        is_on_off_out[NORTH*2+0] = router_if_north_up_0.is_on_off;
        is_on_off_out[NORTH*2+1] = router_if_north_up_1.is_on_off;
        is_on_off_out[SOUTH*2+0] = router_if_south_up_0.is_on_off;
        is_on_off_out[SOUTH*2+1] = router_if_south_up_1.is_on_off;
        is_on_off_out[WEST*2+0]  = router_if_west_up_0.is_on_off;
        is_on_off_out[WEST*2+1]  = router_if_west_up_1.is_on_off;
        is_on_off_out[EAST*2+0]  = router_if_east_up_0.is_on_off;
        is_on_off_out[EAST*2+1]  = router_if_east_up_1.is_on_off;
        
        is_allocatable_out[LOCAL*2+0] = router_if_local_up_0.is_allocatable;
        is_allocatable_out[LOCAL*2+1] = router_if_local_up_1.is_allocatable;
        is_allocatable_out[NORTH*2+0] = router_if_north_up_0.is_allocatable;
        is_allocatable_out[NORTH*2+1] = router_if_north_up_1.is_allocatable;
        is_allocatable_out[SOUTH*2+0] = router_if_south_up_0.is_allocatable;
        is_allocatable_out[SOUTH*2+1] = router_if_south_up_1.is_allocatable;
        is_allocatable_out[WEST*2+0]  = router_if_west_up_0.is_allocatable;
        is_allocatable_out[WEST*2+1]  = router_if_west_up_1.is_allocatable;
        is_allocatable_out[EAST*2+0]  = router_if_east_up_0.is_allocatable;
        is_allocatable_out[EAST*2+1]  = router_if_east_up_1.is_allocatable;
        
        data_out[LOCAL*2+0] = router_if_local_down_0.data;
        data_out[LOCAL*2+1] = router_if_local_down_1.data;
        data_out[NORTH*2+0] = router_if_north_down_0.data;
        data_out[NORTH*2+1] = router_if_north_down_1.data;
        data_out[SOUTH*2+0] = router_if_south_down_0.data;
        data_out[SOUTH*2+1] = router_if_south_down_1.data;
        data_out[WEST*2+0]  = router_if_west_down_0.data;
        data_out[WEST*2+1]  = router_if_west_down_1.data;
        data_out[EAST*2+0]  = router_if_east_down_0.data;
        data_out[EAST*2+1]  = router_if_east_down_1.data;
        
        is_valid_out[LOCAL*2+0] = router_if_local_down_0.is_valid;
        is_valid_out[LOCAL*2+1] = router_if_local_down_1.is_valid;
        is_valid_out[NORTH*2+0] = router_if_north_down_0.is_valid;
        is_valid_out[NORTH*2+1] = router_if_north_down_1.is_valid;
        is_valid_out[SOUTH*2+0] = router_if_south_down_0.is_valid;
        is_valid_out[SOUTH*2+1] = router_if_south_down_1.is_valid;
        is_valid_out[WEST*2+0]  = router_if_west_down_0.is_valid;
        is_valid_out[WEST*2+1]  = router_if_west_down_1.is_valid;
        is_valid_out[EAST*2+0]  = router_if_east_down_0.is_valid;
        is_valid_out[EAST*2+1]  = router_if_east_down_1.is_valid;
                
        router_if_local_down_0.is_on_off = is_on_off_in[LOCAL*2+0];
        router_if_local_down_1.is_on_off = is_on_off_in[LOCAL*2+1];
        router_if_north_down_0.is_on_off = is_on_off_in[NORTH*2+0];
        router_if_north_down_1.is_on_off = is_on_off_in[NORTH*2+1];
        router_if_south_down_0.is_on_off = is_on_off_in[SOUTH*2+0];
        router_if_south_down_1.is_on_off = is_on_off_in[SOUTH*2+1];
        router_if_west_down_0.is_on_off  = is_on_off_in[WEST*2+0];
        router_if_west_down_1.is_on_off  = is_on_off_in[WEST*2+1];
        router_if_east_down_0.is_on_off  = is_on_off_in[EAST*2+0];
        router_if_east_down_1.is_on_off  = is_on_off_in[EAST*2+1];
        
        router_if_local_down_0.is_allocatable = is_allocatable_in[LOCAL*2+0];
        router_if_local_down_1.is_allocatable = is_allocatable_in[LOCAL*2+1];
        router_if_north_down_0.is_allocatable = is_allocatable_in[NORTH*2+0];
        router_if_north_down_1.is_allocatable = is_allocatable_in[NORTH*2+1];
        router_if_south_down_0.is_allocatable = is_allocatable_in[SOUTH*2+0];
        router_if_south_down_1.is_allocatable = is_allocatable_in[SOUTH*2+1];
        router_if_west_down_0.is_allocatable  = is_allocatable_in[WEST*2+0];
        router_if_west_down_1.is_allocatable  = is_allocatable_in[WEST*2+1];
        router_if_east_down_0.is_allocatable  = is_allocatable_in[EAST*2+0];
        router_if_east_down_1.is_allocatable  = is_allocatable_in[EAST*2+1];
        
    end 
endmodule