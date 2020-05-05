module batch_ctrl
  (
   input wire         clk,
   input wire         reset,
   input wire         matw,
   input wire         run,
   input wire         last,
   output reg         s_init,
   input wire         s_fin,
   input wire         src_valid,
   output wire        src_ready,
   output wire        dst_valid,
   input wire         dst_ready,
   output wire        src_v,
   output wire [8:0]  src_a,
   output wire [31:0] prm_v,
   output reg [4:0]   prm_a,
   output wire        dst_v,
   output wire [9:0]  dst_a,
   output reg         execp,
   output wire        inp,
   output wire        outp
   );

   parameter prm_sel_max = 30/2 -1;   //oc / 2
   parameter src_a_max = 25*40/2 -1;  //kernel * sample / 2
   parameter dst_a_max = 30*40/2 -1;  //oc * sample / 2

   assign inp  = ~execp;
   assign outp = ~execp;

   wire               den = dst_ready;

   reg [1:0]          src_en;
   wire               src_fin;
   reg                s_fin_h;
   wire               s_fin_in = (s_fin | s_fin_h) & (src_en[inp] | last) & den;

   always_ff @(posedge clk)begin
      if(~run)begin
         s_init <= 1'b0;
         execp <= 1'b1;
         s_fin_h <= 1'b0;
      end else if(src_fin & src_en[1:0]==2'b00)begin
         s_init <= 1'b1;
         execp <= ~execp;
      end else if(s_fin_in)begin
         s_init <= ~last;
         execp <= ~execp;
         s_fin_h <= 1'b0;
      end else if(s_fin)begin
         s_fin_h <= 1'b1;
      end else begin
         s_init <= 1'b0;
      end

      if(~run)begin
         src_en[1:0] <= 2'b00;
      end else if(src_fin)begin
         src_en[inp] <= 1'b1;
      end else if(s_fin_in & src_en[inp])begin
         src_en[execp] <= 1'b0;
      end
   end

////////////////////// dst_v, dst_a /// dst_valid ///////////////

   wire              last_da;
   wire              next_da;
   reg [9:0]         da;

   wire              dstart, dstart0;
   wire              dst_v0;
   wire              dst_v0_in = s_fin_in | dst_v0&!last_da;

   dff #(.W(1)) d_dstart0 (.in(s_fin_in), .data(dstart0), .clk(clk), .rst(~run), .en(den));
   dff #(.W(1)) d_dst_v0 (.in(dst_v0_in), .data(dst_v0), .clk(clk), .rst(~run), .en(den));

   assign dstart = den&dstart0;

   loop1 #(.W(10)) l_da(.ini(10'd0), .fin(dst_a_max), .data(da), .start(dstart),  .last(last_da),
                        .clk(clk),   .rst(~run),                  .next(next_da),   .en(den) );

   assign dst_a = da;
   assign dst_v = dst_v0 & dst_ready;
   dff #(.W(1)) d_dst_valid (.in(dst_v0), .data(dst_valid), .clk(clk), .rst(~run), .en(den));

////////////////////// src_v, src_a /// s_init, src_ready ///////

   wire              last_sa;
   wire              next_sa;
   reg [8:0]         sa;

   wire              sen = src_valid&src_ready;
   wire              sstart = sen&run&~matw;

   assign src_ready = (src_en!=2'b11);

   loop1 #(.W(9)) l_sa(.ini(9'd0), .fin(src_a_max),
                       .data(sa), .start(sstart),  .last(last_sa),
                       .clk(clk), .rst(~src_ready|~run), .next(next_sa),   .en(sen) );
   assign src_a = sa;
   assign src_v = run & src_valid & src_ready & ~matw;
   assign src_fin = last_sa;

////////////////////// prm_v, prm_a /////////////////////////////

   reg [3:0]         prm_sel;

   assign prm_v = (~src_valid|~matw) ? 32'h0 : 3<<(prm_sel*2);

   always_ff @(posedge clk)begin
      if(reset|~matw)begin
         prm_sel <= 4'h0;
         prm_a <= 5'h0;
      end else if(src_valid)begin
         if(prm_sel != prm_sel_max)begin
            prm_sel <= prm_sel + 1;
         end else begin
            prm_sel <= 4'h0;
            prm_a <= prm_a + 1;
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
   input wire        k_init,
   input wire        k_fin,
   output reg        outr,
   output reg        outrf,
   output reg [10:0] oa,
   output reg        update
   );

   parameter sample = 40-1;
   parameter ct_max = 30-1;

   reg               out_busy1;
   reg               outr00;
   reg [10:0]        oa0;

   wire              last_wi, last_ct;
   wire              next_wi, next_ct;
   wire [5:0]        wi;
   wire [4:0]                 ct;
   reg               last_wi0, last_ct0;
   reg               outr0;
   reg               update0;

   wire start = k_fin&!outr00|last_ct0&out_busy1;

   always_ff @(posedge clk)begin
      if(rst)begin
         out_busy <= 1'b0;
      end else if(last_ct0)begin
         out_busy <= 1'b0;
      end else if(k_init&outr0)begin
         out_busy <= 1'b1;
      end
      if(rst)begin
         out_busy1 <= 1'b0;
      end else if(last_ct0)begin
         out_busy1 <= 1'b0;
      end else if(k_fin&out_busy)begin
         out_busy1 <= 1'b1;
      end
      if(rst)begin
         outr00 <= 1'b0;
      end else if(start)begin
         outr00 <= 1'b1;
      end else if(last_ct)begin
         outr00 <= 1'b0;
      end
   end

   loop1 #(.W(6)) l_wi(.ini(6'd0), .fin(sample), .data(wi), .start(s_init),  .last(last_wi),
                       .clk(clk),  .rst(rst),                .next(next_wi),   .en(last_ct)  );

   loop1 #(.W(5)) l_ct(.ini(5'd0), .fin(ct_max), .data(ct), .start(start),   .last(last_ct),
                       .clk(clk),  .rst(rst),                .next(next_ct),   .en(1'b1)  );

   always_ff @(posedge clk)begin
      if(rst)begin
         oa <= 0;           oa0 <= 0;
         outr <= 1'b0;      outr0 <= 1'b0;
         update <= 1'b0;    update0 <= 1'b0;
         last_ct0 <= 1'b0;
         last_wi0 <= 1'b0;
      end else begin
         oa <= oa0;         oa0 <= wi*(ct_max+1) + ct;
         outr <= outr0;     outr0 <= outr00|start;
         outrf <= last_wi0;
         update <= update0; update0 <= start;
         last_ct0 <= last_ct;
         last_wi0 <= last_wi;
      end
   end
endmodule
