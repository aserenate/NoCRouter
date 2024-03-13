import noc_params::*;

module chiplet_router #(
    parameter BUFFER_SIZE = 8,
    parameter X_CURRENT = MESH_SIZE_X/2,
    parameter Y_CURRENT = MESH_SIZE_Y/2
)(
    input clk,
    input rst,
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
    output logic [VC_NUM-1:0] error_o [PORT_NUM*2-1:0]
);

// router port
router2router south_in_0();
router2router south_in_1();
router2router west_in_0();
router2router west_in_1();
router2router north_in_0();
router2router north_in_1();
router2router east_in_0();
router2router east_in_1();

router2router south_out_0();
router2router south_out_1();
router2router west_out_0();
router2router west_out_1();
router2router north_out_0();
router2router north_out_1();
router2router east_out_0();
router2router east_out_1();

// trans port
    router2router south_0_trans_1();
    router2router south_1_trans_0();
    router2router west_0_trans_1();
    router2router west_1_trans_0();
    router2router north_0_trans_1();
    router2router north_1_trans_0();
    router2router east_0_trans_1();
    router2router east_1_trans_0();

// inport arbiter
    inport_arbiter
    south_inport_u0
    (
        .extern_port(router_if_south_down_0),
        .intern_port(south_1_trans_0),
        .input_port(south_in_0)
    );

    inport_arbiter
    south_inport_u1
    (
        .extern_port(router_if_south_down_1),
        .intern_port(south_0_trans_1),
        .input_port(south_in_1)
    );

    inport_arbiter
    north_inport_u0
    (
        .extern_port(router_if_north_down_0),
        .intern_port(north_1_trans_0),
        .input_port(north_in_0)
    );

    inport_arbiter
    north_inport_u1
    (
        .extern_port(router_if_north_down_1),
        .intern_port(north_0_trans_1),
        .input_port(north_in_1)
    );

    inport_arbiter
    west_inport_u0
    (
        .extern_port(router_if_west_down_0),
        .intern_port(west_1_trans_0),
        .input_port(west_in_0)
    );

    inport_arbiter
    west_inport_u1
    (
        .extern_port(router_if_west_down_1),
        .intern_port(west_0_trans_1),
        .input_port(west_in_1)
    );

    inport_arbiter
    east_inport_u0
    (
        .extern_port(router_if_east_down_0),
        .intern_port(east_1_trans_0),
        .input_port(east_in_0)
    );

    inport_arbiter
    east_inport_u1
    (
        .extern_port(router_if_east_down_1),
        .intern_port(east_0_trans_1),
        .input_port(east_in_1)
    );

// outport arbiter

    outport_arbiter #(.SUB_NETWORK(0))
    south_outport_u0
    (
        .clk(clk),
        .rst(rst),
        .output_port(south_out_0),
        .extern_port(router_if_south_up_0),
        .intern_port(south_0_trans_1)
    );

    outport_arbiter #(.SUB_NETWORK(1))
    south_outport_u1
    (
        .clk(clk),
        .rst(rst),
        .output_port(south_out_1),
        .extern_port(router_if_south_up_1),
        .intern_port(south_1_trans_0)
    );

    outport_arbiter #(.SUB_NETWORK(0))
    north_outport_u0
    (
        .clk(clk),
        .rst(rst),
        .output_port(north_out_0),
        .extern_port(router_if_north_up_0),
        .intern_port(north_0_trans_1)
    );

    outport_arbiter #(.SUB_NETWORK(1))
    north_outport_u1
    (
        .clk(clk),
        .rst(rst),
        .output_port(north_out_1),
        .extern_port(router_if_north_up_1),
        .intern_port(north_1_trans_0)
    );

    outport_arbiter #(.SUB_NETWORK(0))
    west_outport_u0
    (
        .clk(clk),
        .rst(rst),
        .output_port(west_out_0),
        .extern_port(router_if_west_up_0),
        .intern_port(west_0_trans_1)
    );

    outport_arbiter #(.SUB_NETWORK(1))
    west_outport_u1
    (
        .clk(clk),
        .rst(rst),
        .output_port(west_out_1),
        .extern_port(router_if_west_up_1),
        .intern_port(west_1_trans_0)
    );

    outport_arbiter #(.SUB_NETWORK(0))
    east_outport_u0
    (
        .clk(clk),
        .rst(rst),
        .output_port(east_out_0),
        .extern_port(router_if_east_up_0),
        .intern_port(east_0_trans_1)
    );

    outport_arbiter #(.SUB_NETWORK(1))
    east_outport_u1
    (
        .clk(clk),
        .rst(rst),
        .output_port(east_out_1),
        .extern_port(router_if_east_up_1),
        .intern_port(east_1_trans_0)
    );

// router connection
router #(
    .BUFFER_SIZE(BUFFER_SIZE),
    .X_CURRENT(X_CURRENT),
    .Y_CURRENT(Y_CURRENT)
)
router_0
(
    .clk                    (clk                    ),
    .rst                    (rst                    ),
    .router_if_local_up     (router_if_local_up_0   ),
    .router_if_north_up     (north_out_0            ),
    .router_if_south_up     (south_out_0            ),
    .router_if_west_up      (west_out_0             ),
    .router_if_east_up      (east_out_0             ),
    .router_if_local_down   (router_if_local_down_0 ),
    .router_if_north_down   (north_in_0             ),
    .router_if_south_down   (south_in_0             ),
    .router_if_west_down    (west_in_0              ),
    .router_if_east_down    (east_in_0              ),
    .error_o                (error_o[PORT_NUM-1:0]  )
);

router #(
    .BUFFER_SIZE(BUFFER_SIZE),
    .X_CURRENT(X_CURRENT),
    .Y_CURRENT(Y_CURRENT)
)
router_1
(
    .clk                    (clk                    ),
    .rst                    (rst                    ),
    .router_if_local_up     (router_if_local_up_1   ),
    .router_if_north_up     (north_out_1            ),
    .router_if_south_up     (south_out_1            ),
    .router_if_west_up      (west_out_1             ),
    .router_if_east_up      (east_out_1             ),
    .router_if_local_down   (router_if_local_down_1 ),
    .router_if_north_down   (north_in_1             ),
    .router_if_south_down   (south_in_1             ),
    .router_if_west_down    (west_in_1              ),
    .router_if_east_down    (east_in_1              ),
    .error_o                (error_o[2*PORT_NUM-1:PORT_NUM])
);

endmodule