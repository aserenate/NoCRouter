import noc_params::*;

module router #(
    parameter VC_TOTAL = 10,
    parameter PORT_NUM = 5,
    parameter VC_NUM = 2,
    parameter BUFFER_SIZE = 8,
    parameter PIPELINE_DEPTH = 5,
    parameter X_CURRENT = MESH_SIZE_X/2,
    parameter Y_CURRENT = MESH_SIZE_Y/2
)(
    input clk,
    input rst,
    router2router.upstream router_if_local_up,
    router2router.upstream router_if_north_up,
    router2router.upstream router_if_south_up,
    router2router.upstream router_if_west_up,
    router2router.upstream router_if_east_up,
    router2router.downstream router_if_local_down,
    router2router.downstream router_if_north_down,
    router2router.downstream router_if_south_down,
    router2router.downstream router_if_west_down,
    router2router.downstream router_if_east_down
);

    //connections from upstream
    flit_t data_out [PORT_NUM-1:0];
    logic valid_flit_out [PORT_NUM-1:0];
    logic [PORT_NUM-1:0] [VC_NUM-1:0] on_off_in;
    logic [PORT_NUM-1:0] [VC_NUM-1:0] is_allocatable_in;

    //connections from downstream
    flit_t data_in [PORT_NUM-1:0];
    logic valid_flit_in [PORT_NUM-1:0];
    logic [VC_NUM-1:0] on_off_out [PORT_NUM-1:0];
    logic [VC_NUM-1:0] is_allocatable_out [PORT_NUM-1:0];

    always_comb
    begin
        router_if_local_up.data = data_out[0];
        router_if_north_up.data = data_out[1];
        router_if_south_up.data = data_out[2];
        router_if_west_up.data = data_out[3];
        router_if_east_up.data = data_out[4];

        router_if_local_up.valid_flit = valid_flit_out[0];
        router_if_north_up.valid_flit = valid_flit_out[1];
        router_if_south_up.valid_flit = valid_flit_out[2];
        router_if_west_up.valid_flit = valid_flit_out[3];
        router_if_east_up.valid_flit = valid_flit_out[4];

        on_off_in[0] = router_if_local_up.on_off;
        on_off_in[1] = router_if_north_up.on_off;
        on_off_in[2] = router_if_south_up.on_off;
        on_off_in[3] = router_if_west_up.on_off;
        on_off_in[4] = router_if_east_up.on_off;

        is_allocatable_in[0] = router_if_local_up.is_allocatable;
        is_allocatable_in[1] = router_if_north_up.is_allocatable;
        is_allocatable_in[2] = router_if_south_up.is_allocatable;
        is_allocatable_in[3] = router_if_west_up.is_allocatable;
        is_allocatable_in[4] = router_if_east_up.is_allocatable;

        data_in[0] = router_if_local_down.data;
        data_in[1] = router_if_north_down.data;
        data_in[2] = router_if_south_down.data;
        data_in[3] = router_if_west_down.data;
        data_in[4] = router_if_east_down.data;

        valid_flit_in[0] = router_if_local_down.valid_flit;
        valid_flit_in[1] = router_if_north_down.valid_flit;
        valid_flit_in[2] = router_if_south_down.valid_flit;
        valid_flit_in[3] = router_if_west_down.valid_flit;
        valid_flit_in[4] = router_if_east_down.valid_flit;

        router_if_local_down.on_off = on_off_out[0];
        router_if_north_down.on_off = on_off_out[1];
        router_if_south_down.on_off = on_off_out[2];
        router_if_west_down.on_off = on_off_out[3];
        router_if_east_down.on_off = on_off_out[4];

        router_if_local_down.is_allocatable = is_allocatable_out[0];
        router_if_north_down.is_allocatable = is_allocatable_out[1];
        router_if_south_down.is_allocatable = is_allocatable_out[2];
        router_if_west_down.is_allocatable = is_allocatable_out[3];
        router_if_east_down.is_allocatable = is_allocatable_out[4];

    end

    input_block2crossbar ib2xbar_if();
    input_block2switch_allocator ib2sa_if();
    input_block2vc_allocator ib2va_if();
    switch_allocator2crossbar sa2xbar_if();

    input_block #(
        .PORT_NUM(PORT_NUM),
        .BUFFER_SIZE(BUFFER_SIZE),
        .PIPELINE_DEPTH(PIPELINE_DEPTH),
        .X_CURRENT(X_CURRENT),
        .Y_CURRENT(Y_CURRENT)
    )
    input_block (
        .rst(rst),
        .clk(clk),
        .data_i(data_in),
        .valid_flit_i(valid_flit_in),
        .crossbar_if(ib2xbar_if),
        .sa_if(ib2sa_if),
        .va_if(ib2va_if),
        .on_off_o(on_off_out),
        .vc_allocatable_o(is_allocatable_out)
    );

    crossbar #(
    )
    crossbar (
        .ib_if(ib2xbar_if),
        .sa_if(sa2xbar_if),
        .data_o(data_out)
    );

    vc_allocator #(
        .VC_TOTAL(VC_TOTAL),
        .PORT_NUM(PORT_NUM),
        .VC_NUM(VC_NUM)
    )
    vc_allocator (
        .rst(rst),
        .clk(clk),
        .idle_downstream_vc_i(is_allocatable_in),
        .ib_if(ib2va_if)
    );

    switch_allocator #(
        .VC_TOTAL(VC_TOTAL),
        .PORT_NUM(PORT_NUM),
        .VC_NUM(VC_NUM)
    )
    switch_allocator (
        .rst(rst),
        .clk(clk),
        .on_off_i(on_off_in),
        .ib_if(ib2sa_if),
        .xbar_if(sa2xbar_if),
        .valid_flit_o(valid_flit_out)
    );

endmodule