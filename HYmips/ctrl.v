`include "defines.v"
module ctrl(
    input wire rst,
    input wire id_stop,
    input wire ex_stop,
    input wire mem_stop,
    output reg[5:0] stop
);
    always@(*) begin
        if(rst==`True)
        stop=6'b000000;
        else if(ex_stop==`True) begin
            stop=6'b001111;
        end
        else if(id_stop==`True)
        stop=6'b000111;
        else if(mem_stop==`True)
        stop=6'b001111;
        else
        stop=6'b000000;
    end
endmodule