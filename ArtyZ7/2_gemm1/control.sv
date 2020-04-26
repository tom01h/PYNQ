module batch_ctrl
  (
   input wire        clk,
   input wire        reset,
   input wire        matw,
   input wire        run,
   output wire       s_init,
   input wire        s_fin,
   input wire        src_valid,
   output wire       src_ready,
   output wire       dst_valid,
   input wire        dst_ready,
   output wire       src_v,
   output wire [4:0] src_a,
   output wire [3:0] prm_v,
   output reg [2:0]  prm_a,
   output wire       dst_v,
   output wire [3:0] dst_a
   );

////////////////////// dst_v, dst_a /// dst_valid ///////////////

   wire              last_da;
   wire              next_da;
   reg [3:0]         da;

   wire              den = dst_ready;

   wire              dstart, dstart0;
   wire              dst_v0;
   wire              dst_v0_in = s_fin | dst_v0&!last_da;

   dff #(.W(1)) d_dstart0 (.in(s_fin), .data(dstart0), .clk(clk), .rst(~run), .en(den|s_fin));
   dff #(.W(1)) d_dst_v0 (.in(dst_v0_in), .data(dst_v0), .clk(clk), .rst(~run), .en(den|s_fin));

   assign dstart = den&dstart0;

   loop1 #(.W(4)) l_da(.ini(4'd0), .fin(15),  .data(da), .start(dstart),  .last(last_da),
                       .clk(clk),   .rst(~run),           .next(next_da),   .en(den) );

   assign dst_a = da;
   assign dst_v = dst_v0 & dst_ready;
   dff #(.W(1)) d_dst_valid (.in(dst_v0), .data(dst_valid), .clk(clk), .rst(~run), .en(den));

////////////////////// src_v, src_a /// s_init, src_ready ///////

   wire              last_sa;
   wire              next_sa;
   reg [4:0]         sa;

   wire              sen = src_valid&src_ready;
   wire              sstart = sen&run&~matw;

   assign src_ready = 1'b1;

   loop1 #(.W(5)) l_sa(.ini(5'd0), .fin(31),  .data(sa), .start(sstart),  .last(last_sa),
                        .clk(clk), .rst(~src_ready|~run), .next(next_sa),   .en(sen) );
   assign src_a = sa;
   assign src_v = run & src_valid & src_ready & ~matw;
   assign s_init = last_sa;

////////////////////// prm_v, prm_a /////////////////////////////

   reg [1:0]         prm_sel;

   assign prm_v = (~src_valid|~matw) ? 4'h0 : 1<<(prm_sel);

   always_ff @(posedge clk)begin
      if(reset|~matw)begin
         prm_sel <= 2'h0;
         prm_a <= 3'h0;
      end else if(src_valid)begin
         prm_a <= prm_a + 1;
         if(prm_a == 3'h7)begin
            prm_sel <= prm_sel + 1;
         end
      end
   end
endmodule

module out_ctrl
  (
   input wire        clk,
   input wire        rst,
   input wire        s_init,
   output reg        out_busy,
   input wire        k_fin,
   output reg        outr,
   output wire [3:0] oa
   );

   wire              last_wi, last_ct;
   wire              next_wi, next_ct;
   wire [1:0]        wi     , ct;

   assign oa = wi*4 + ct;

   reg               start, k_fin0;

   always_ff @(posedge clk)begin
      k_fin0 <= k_fin;
      if(rst)begin
         start <= 1'b0;
      end else begin
         start <= k_fin0;
      end
   end

   loop1 #(.W(2)) l_wi(.ini(2'd0), .fin(3),  .data(wi), .start(s_init),  .last(last_wi),
                       .clk(clk),  .rst(rst),            .next(next_wi),   .en(last_ct)  );

   loop1 #(.W(2)) l_ct(.ini(2'd0), .fin(3),  .data(ct), .start(start),   .last(last_ct),
                       .clk(clk),  .rst(rst),            .next(next_ct),   .en(1'b1)  );

   always_ff @(posedge clk)begin
      if(rst|last_ct)begin
         out_busy <= 1'b0;
      end else if(k_fin)begin
         out_busy <= 1'b1;
      end
      if(rst|last_ct)begin
         outr <= 1'b0;
      end else if(k_fin0)begin
         outr <= 1'b1;
      end
   end
endmodule
