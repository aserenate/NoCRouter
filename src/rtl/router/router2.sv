import noc_params::*;

module router2 #(
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
    .router_if_north_up     (router_if_north_up_0   ),
    .router_if_south_up     (router_if_south_up_0   ),
    .router_if_west_up      (router_if_west_up_0    ),
    .router_if_east_up      (router_if_east_up_0    ),
    .router_if_local_down   (router_if_local_down_0 ),
    .router_if_north_down   (router_if_north_down_0 ),
    .router_if_south_down   (router_if_south_down_0 ),
    .router_if_west_down    (router_if_west_down_0  ),
    .router_if_east_down    (router_if_east_down_0  ),
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
    .router_if_north_up     (router_if_north_up_1   ),
    .router_if_south_up     (router_if_south_up_1   ),
    .router_if_west_up      (router_if_west_up_1    ),
    .router_if_east_up      (router_if_east_up_1    ),
    .router_if_local_down   (router_if_local_down_1 ),
    .router_if_north_down   (router_if_north_down_1 ),
    .router_if_south_down   (router_if_south_down_1 ),
    .router_if_west_down    (router_if_west_down_1  ),
    .router_if_east_down    (router_if_east_down_1  ),
    .error_o                (error_o[2*PORT_NUM-1:PORT_NUM])
);

endmodule