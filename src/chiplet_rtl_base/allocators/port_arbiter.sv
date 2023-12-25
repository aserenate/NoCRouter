import noc_params::*;

module inport_arbiter
(
    router2router.downstream extern_port,
    router2router.downstream intern_port,
    router2router.upstream input_port
);
    logic [1:0] grant;
    // local port first arbiter
    always_comb begin
        if (extern_port.is_valid == 1)
            grant = 2'b01;
        else if (intern_port.is_valid == 1)
            grant = 2'b10;
        else
            grant = 2'b00;
    end

    assign extern_port.is_on_off = (~grant[1]) & input_port.is_on_off;
    assign extern_port.is_allocatable = (~grant[1]) & input_port.is_allocatable;
    assign intern_port.is_on_off = (~grant[0]) & input_port.is_on_off;
    assign intern_port.is_allocatable = (~grant[0]) & input_port.is_allocatable;
    
    assign input_port.data = (grant[0])? extern_port.data : (grant[1])? intern_port.data : 'b0;
    assign input_port.is_valid = |grant;
endmodule

module outport_arbiter
#(
    SUB_NETWORK = 0
)
(
    input logic clk,
    input logic rst,
    router2router.downstream output_port,
    router2router.upstream extern_port,
    router2router.upstream intern_port
);

    logic network_state, network_state_next;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            network_state = SUB_NETWORK;
        else
            network_state = network_state_next;
    end

    always_comb begin
        if (output_port.is_valid && (output_port.data.flit_label == HEAD | output_port.data.flit_label == HEADTAIL))
            network_state_next = output_port.data.data.head_data.sub_network;
        else
            network_state_next = network_state;
    end

    assign extern_port.data      = output_port.data;
    assign extern_port.is_valid  = (network_state_next == SUB_NETWORK)? output_port.is_valid : 0;
    assign intern_port.data     = output_port.data;
    assign intern_port.is_valid = (network_state_next != SUB_NETWORK)? output_port.is_valid : 0;

    assign output_port.is_on_off = (network_state_next == SUB_NETWORK)? extern_port.is_on_off : intern_port.is_on_off;
    assign output_port.is_allocatable = (network_state_next == SUB_NETWORK)? extern_port.is_allocatable : intern_port.is_allocatable;

endmodule