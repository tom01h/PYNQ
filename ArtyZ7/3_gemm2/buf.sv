module src_buf
  (
   input wire        clk,
   input wire        src_v,
   input wire [4:0]  src_a,
   input wire [63:0] src_d,
   input wire        exec,
   input wire [5:0]  ia,
   output reg [31:0] d
   );

   reg [63:0]        buff0 [0:15];
   reg [63:0]        wd0;
   reg [63:0]        buff1 [0:15];
   reg [63:0]        wd1;
   reg [1:0]         ia_;

   always_ff @(posedge clk)
     ia_ <= {ia[5],ia[0]};
   always_comb begin
      case(ia_)
        2'd0 : d = wd0[31:0];
        2'd1 : d = wd0[63:32];
        2'd2 : d = wd1[31:0];
        2'd3 : d = wd1[63:32];
      endcase
   end

   always_ff @(posedge clk)
     if(    src_v&~src_a[4]) buff0[src_a[3:0]] <= src_d;
     else if(exec&~ia[5]   ) wd0 <= buff0[ia[4:1]];
   always_ff @(posedge clk)
     if(    src_v& src_a[4]) buff1[src_a[3:0]] <= src_d;
     else if(exec& ia[5]   ) wd1 <= buff1[ia[4:1]];

endmodule

module dst_buf
  (
   input wire         clk,
   input wire         dst_v,
   input wire [3:0]   dst_a,
   output wire [63:0] dst_d,
   input wire         outr,
   input wire [4:0]   oa,
   input wire [31:0]  result
   );

   reg [31:0]        buff00 [0:7];
   reg [31:0]        buff01 [0:7];
   reg [31:0]        buff10 [0:7];
   reg [31:0]        buff11 [0:7];

   reg [63:0]        dst_d0;
   reg [63:0]        dst_d1;

   assign dst_d = (dst_a[3]) ? dst_d1 : dst_d0;

   always_ff @(posedge clk)
     if(outr&~oa[0]&~oa[4])
       buff00[oa[3:1]] <= result;
     else if(dst_v&~dst_a[3])
       dst_d0[31:0] <= buff00[dst_a[2:0]];
   always_ff @(posedge clk)
     if(outr& oa[0]&~oa[4])
       buff01[oa[3:1]] <= result;
     else if(dst_v&~dst_a[3])
       dst_d0[63:32] <= buff01[dst_a[2:0]];

   always_ff @(posedge clk)
     if(outr&~oa[0]& oa[4])
       buff10[oa[3:1]] <= result;
     else if(dst_v& dst_a[3])
       dst_d1[31:0] <= buff10[dst_a[2:0]];
   always_ff @(posedge clk)
     if(outr& oa[0]& oa[4])
       buff11[oa[3:1]] <= result;
     else if(dst_v& dst_a[3])
       dst_d1[63:32] <= buff11[dst_a[2:0]];

endmodule
