import noc_params::*;

module chiplet_rc_unit #(
    parameter X_CURRENT = 0,
    parameter Y_CURRENT = 0,
    parameter DEST_ADDR_SIZE_X = 4,
    parameter DEST_ADDR_SIZE_Y = 4
)(
    input logic network_id,
    input logic [DEST_ADDR_SIZE_X-1 : 0] x_dest_i,
    input logic [DEST_ADDR_SIZE_Y-1 : 0] y_dest_i,
    output port_t out_port_o
);

    wire signed [DEST_ADDR_SIZE_X : 0] x_offset;
    wire signed [DEST_ADDR_SIZE_Y : 0] y_offset;

    assign x_offset = x_dest_i - X_CURRENT;
    assign y_offset = y_dest_i - Y_CURRENT;

    /*
    Combinational logic:
    - the route computation follows a DOR (Dimension-Order Routing) algorithm,
      with the nodes of the Network-on-Chip arranged in a 2D mesh structure,
      hence with 5 inputs and 5 outputs per node (except for boundary routers),
      i.e., both for input and output:
        * left, right, up and down links to the adjacent nodes
        * one link to the end node
    - the 2D Mesh coordinates scheme is mapped as following:
        * X increasing from Left to Right
        * Y increasing from  Up  to Down
    */
    always_comb
    begin
        if (network_id == 0) begin
            if (x_offset < 0)
            begin
                out_port_o = WEST_0;
            end
            else if (x_offset > 0)
            begin
                out_port_o = EAST_0;
            end
            else if (x_offset == 0 & y_offset < 0)
            begin
                out_port_o = NORTH_0;
            end
            else if (x_offset == 0 & y_offset > 0) begin
                out_port_o = SOUTH_0;
            end
            else begin
                out_port_o = LOCAL_0;
            end
        end
        else begin
            if (x_offset < 0)
            begin
                out_port_o = WEST_1;
            end
            else if (x_offset > 0)
            begin
                out_port_o = EAST_1;
            end
            else if (x_offset == 0 & y_offset < 0)
            begin
                out_port_o = NORTH_1;
            end
            else if (x_offset == 0 & y_offset > 0) begin
                out_port_o = SOUTH_1;
            end
            else begin
                out_port_o = LOCAL_1;
            end
        end
    end

endmodule