module top (
    input  logic       clk,
    input  logic       reset_n,
    output logic [7:0] counter_out
);

    counter u_counter (
        .clk     (clk),
        .reset_n (reset_n),
        .count   (counter_out)
    );

endmodule
