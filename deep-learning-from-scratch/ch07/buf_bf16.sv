module src_buf
  (
   input wire        clk,
   input wire        src_v,
   input wire [9:0]  src_a,
   input wire [63:0] src_d,
   input wire        exec,
   input wire [10:0] ia,
   output reg [15:0] d
   );

   reg [31:0]        buff0 [0:511];
   reg [31:0]        wd0;
   reg [31:0]        buff1 [0:511];
   reg [31:0]        wd1;
   reg [1:0]         ia_;

   always_ff @(posedge clk)
     ia_ <= {ia[10],ia[0]};
   always_comb begin
      case(ia_)
        2'd0 : d = wd0[15:0];
        2'd1 : d = wd0[31:16];
        2'd2 : d = wd1[15:0];
        2'd3 : d = wd1[31:16];
      endcase
   end

   always_ff @(posedge clk)
     if(    src_v&~src_a[9]) buff0[src_a[8:0]] <= {src_d[63:48],src_d[31:16]};
     else if(exec&~ia[10]  ) wd0 <= buff0[ia[9:1]];
   always_ff @(posedge clk)
     if(    src_v& src_a[9]) buff1[src_a[8:0]] <= {src_d[63:48],src_d[31:16]};
     else if(exec& ia[10]  ) wd1 <= buff1[ia[9:1]];

endmodule

module dst_buf
  (
   input wire               clk,
   input wire               dst_v,
   input wire [9:0]         dst_a,
   output wire [63:0]       dst_d,
   input wire               outr,
   input wire [10:0]        oa,
   input wire               signo,
   input wire signed [9:0]  expo,
   input wire signed [31:0] addo
   );

   reg [31:0]        buff00 [0:511];
   reg [31:0]        buff01 [0:511];
   reg [31:0]        buff10 [0:511];
   reg [31:0]        buff11 [0:511];

   reg               outr4,   outr5;
   reg [10:0]        oa4,     oa5;
   wire [31:0]       nrm;
   always_ff @(posedge clk)begin
      outr4   <= outr;
      outr5   <= outr4;
      oa4     <= oa;
      oa5     <= oa4;
   end

   reg [63:0]        dst_d0;
   reg [63:0]        dst_d1;

   assign dst_d = (dst_a[9]) ? dst_d1 : dst_d0;

   always_ff @(posedge clk)
     if(outr5&~oa5[0]&~oa5[10])
       buff00[oa5[9:1]] <= nrm;
     else if(dst_v&~dst_a[9])
       dst_d0[31:0] <= buff00[dst_a[8:0]];
   always_ff @(posedge clk)
     if(outr5& oa5[0]&~oa5[10])
       buff01[oa5[9:1]] <= nrm;
     else if(dst_v&~dst_a[9])
       dst_d0[63:32] <= buff01[dst_a[8:0]];

   always_ff @(posedge clk)
     if(outr5&~oa5[0]& oa5[10])
       buff10[oa5[9:1]] <= nrm;
     else if(dst_v& dst_a[9])
       dst_d1[31:0] <= buff10[dst_a[8:0]];
   always_ff @(posedge clk)
     if(outr5& oa5[0]& oa5[10])
       buff11[oa5[9:1]] <= nrm;
     else if(dst_v& dst_a[9])
       dst_d1[63:32] <= buff11[dst_a[8:0]];

   normalize normalize
     (
      .clk(clk),
      .en(outr4),
      .signo(signo),
      .expo(expo),
      .addo(addo),
      .nrm(nrm)
   );
endmodule
