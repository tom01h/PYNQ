module src_buf
  (
   input wire        clk,
   input wire        src_v,
   input wire [4:0]  src_a,
   input wire [31:0] src_d,
   input wire        exec,
   input wire [4:0]  ia,
   output reg [31:0] d
   );

   reg [31:0]        buff [0:31];

   always_ff @(posedge clk)
     if(    src_v) buff[src_a[4:0]] <= src_d;
     else if(exec) d <= buff[ia];

endmodule

module dst_buf
  (
   input wire        clk,
   input wire        dst_v,
   input wire [3:0]  dst_a,
   output reg [31:0] dst_d,
   input wire        outr,
   input wire [3:0]  oa,
   input wire [31:0] result
   );

   reg [31:0]        buff [0:15];

   always_ff @(posedge clk)
     if(outr)
       buff[oa[3:0]] <= result;
     else if(dst_v)
       dst_d <= buff[dst_a[3:0]];

endmodule

