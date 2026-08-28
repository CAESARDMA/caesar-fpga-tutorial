module counter (
    input  logic       clk,
    input  logic       reset_n,
    output logic [7:0] count
);

    always_ff @(posedge clk) begin
        if (!reset_n)
            count <= 8'h00;
        else
            count <= count + 1'b1;
    end

endmodule
