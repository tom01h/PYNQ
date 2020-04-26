/**********************************************************************\
*      addrress range   access size   function                         *
* reg  0x000            32bit         [0] matw matrix write            *
*                                     [1] run  data input/ matrix mul/ *
*                                              data output             *
*                                     [2] last last cycle              *
* reg  0x010            32bit         control dummy register           *
\**********************************************************************/
module top
  (
   input wire         S_AXI_ACLK,
   input wire         S_AXI_ARESETN,

   ////////////////////////////////////////////////////////////////////////////
   // AXI Lite Slave Interface
   input wire [31:0]  S_AXI_AWADDR,
   input wire         S_AXI_AWVALID,
   output wire        S_AXI_AWREADY,
   input wire [31:0]  S_AXI_WDATA,
   input wire [3:0]   S_AXI_WSTRB,
   input wire         S_AXI_WVALID,
   output wire        S_AXI_WREADY,
   output wire [1:0]  S_AXI_BRESP,
   output wire        S_AXI_BVALID,
   input wire         S_AXI_BREADY,

   input wire [31:0]  S_AXI_ARADDR,
   input wire         S_AXI_ARVALID,
   output wire        S_AXI_ARREADY,
   output reg [31:0]  S_AXI_RDATA,
   output wire [1:0]  S_AXI_RRESP,
   output wire        S_AXI_RVALID,
   input wire         S_AXI_RREADY,


   input wire         AXIS_ACLK,
   input wire         AXIS_ARESETN,

   ////////////////////////////////////////////////////////////////////////////
   // AXI Stream Master Interface
   output wire        M_AXIS_TVALID,
   output wire [63:0] M_AXIS_TDATA,
   output wire [7:0]  M_AXIS_TSTRB,
   output wire        M_AXIS_TLAST,
   input wire         M_AXIS_TREADY,

   ////////////////////////////////////////////////////////////////////////////
   // AXI Stream Slave Interface
   output wire        S_AXIS_TREADY,
   input wire [63:0]  S_AXIS_TDATA,
   input wire [7:0]   S_AXIS_TSTRB,
   input wire         S_AXIS_TLAST,
   input wire         S_AXIS_TVALID
   );

   assign M_AXIS_TSTRB = 8'hff;
   assign M_AXIS_TLAST = 1'b0;

   reg               run, matw, last;

   wire              s_init;

   wire              src_v;
   wire [3:0]        src_a;
   wire [3:0]        prm_v;
   wire [2:0]        prm_a;
   wire              dst_v;
   wire [2:0]        dst_a;

   wire              out_busy;
   wire              outr;
   wire              outrf;
   wire [3:0]        oa;
   wire              sum_update;

   wire [31:0]       d;
   wire [31:0]       acc [0:4];

   wire              s_fin;
   wire              k_init;
   wire              k_fin;
   wire              exec;
   wire [4:0]        ia;
   wire [2:0]        wa;

   wire              inp;
   wire              outp;
   wire              execp;

   batch_ctrl batch_ctrl
     (
      .clk(AXIS_ACLK),
      .reset(~AXIS_ARESETN),
      .matw(matw),
      .run(run),
      .last(last),
      .s_init(s_init),
      .s_fin(s_fin),
      .src_valid(S_AXIS_TVALID),
      .src_ready(S_AXIS_TREADY),
      .dst_valid(M_AXIS_TVALID),
      .dst_ready(M_AXIS_TREADY),
      .src_v(src_v),
      .src_a(src_a[3:0]),
      .prm_v(prm_v[3:0]),
      .prm_a(prm_a[2:0]),
      .dst_v(dst_v),
      .dst_a(dst_a[2:0]),
      .execp(execp),
      .inp(inp),
      .outp(outp)
      );

   ex_ctl ex_ctl
     (
      .clk(AXIS_ACLK),
      .rst(~run),
      .s_init(s_init),
      .out_busy(out_busy),
      .outrf(outrf),
      .s_fin(s_fin),
      .k_init(k_init),
      .k_fin(k_fin),
      .exec(exec),
      .ia(ia[4:0]),
      .wa(wa[2:0])
      );

   out_ctrl out_ctrl
     (
      .clk(AXIS_ACLK),
      .rst(~run),
      .s_init(s_init),
      .out_busy(out_busy),
      .k_init(k_init),
      .k_fin(k_fin),
      .outr(outr),
      .outrf(outrf),
      .oa(oa[3:0]),
      .update(sum_update)
   );

   src_buf src_buf
     (
      .clk(AXIS_ACLK),
      .src_v(src_v),
      .src_a({inp,src_a[3:0]}),
      .src_d(S_AXIS_TDATA),
      .exec(exec),
      .ia({execp,ia[4:0]}),
      .d(d)
      );

   assign acc[4] = 0;
   wire [31:0]       result = acc[0];

   dst_buf dst_buf
     (
      .clk(AXIS_ACLK),
      .dst_v(dst_v),
      .dst_a({outp,dst_a[2:0]}),
      .dst_d(M_AXIS_TDATA),
      .outr(outr),
      .oa({execp,oa[3:0]}),
      .result(result)
      );

   generate
      genvar         i;
      for (i = 0; i < 4; i = i + 1) begin
         core core
               (
                .clk(AXIS_ACLK),
                .init(k_init),
                .write(prm_v[i]),
                .exec(exec),
                .outr(outr),
                .update(sum_update),
                .ra(wa[2:0]),
                .wa(prm_a[2:0]),
                .d(d),
                .wd(S_AXIS_TDATA[31:0]),
                .acc_in(acc[i+1]),
                .acc(acc[i])
                );
      end
   endgenerate



   ////////////////////////////////////////////////////////////////////////////
   // AXI Lite Slave State Control
   reg [3:0]         axist;
   reg [11:2]        wb_adr_i;
   reg [11:2]        rd_adr_i;
   reg [31:0]        wb_dat_i;

   assign S_AXI_BRESP = 2'b00;
   assign S_AXI_RRESP = 2'b00;
   assign S_AXI_AWREADY = (axist == 4'b0000)|(axist == 4'b0010);
   assign S_AXI_WREADY  = (axist == 4'b0000)|(axist == 4'b0001);
   assign S_AXI_ARREADY = (axist == 4'b0000);
   assign S_AXI_BVALID  = (axist == 4'b0011);
   assign S_AXI_RVALID  = (axist == 4'b1000);

   always @(posedge S_AXI_ACLK)begin
      if(~S_AXI_ARESETN)begin
         axist<=4'b0000;

         wb_adr_i<=0;
         wb_dat_i<=0;
      end else if(axist==4'b000)begin
         if(S_AXI_AWVALID & S_AXI_WVALID)begin
            axist<=4'b0011;
            wb_adr_i[11:2]<=S_AXI_AWADDR[11:2];
            wb_dat_i<=S_AXI_WDATA;
         end else if(S_AXI_AWVALID)begin
            axist<=4'b0001;
            wb_adr_i[11:2]<=S_AXI_AWADDR[11:2];
         end else if(S_AXI_WVALID)begin
            axist<=4'b0010;
            wb_dat_i<=S_AXI_WDATA;
         end else if(S_AXI_ARVALID)begin
            axist<=4'b0100;
            rd_adr_i[11:2]<=S_AXI_ARADDR[11:2];
         end
      end else if(axist==4'b0001)begin
         if(S_AXI_WVALID)begin
            axist<=4'b0011;
            wb_dat_i<=S_AXI_WDATA;
         end
      end else if(axist==4'b0010)begin
         if(S_AXI_AWVALID)begin
            axist<=4'b0011;
            wb_adr_i[11:2]<=S_AXI_AWADDR[11:2];
         end
      end else if(axist==4'b0011)begin
         if(S_AXI_BREADY)
           axist<=4'b0000;
      end else if(axist==4'b0100)begin
         axist<=4'b1000;
      end else if(axist==4'b1000)begin
         if(S_AXI_RREADY)
           axist<=4'b0000;
      end
   end


   reg [31:0] control;

   wire       regwrite = (axist==4'b0011) & (wb_adr_i[11:10]==2'b00);
   wire       regread  = (axist==4'b0100) & (rd_adr_i[11:10]==2'b00);

   ////////////////////////////////////////////////////////////////////////////
   // Register Write
   always @(posedge S_AXI_ACLK)begin
      if(~S_AXI_ARESETN)begin
         {last, run, matw} <= 3'b000;
         control <= 32'h0;
      end else if(regwrite)begin
         case({wb_adr_i[9:2],2'b00})
           10'h00: {last, run, matw} <= wb_dat_i[2:0];
           10'h10: control <= wb_dat_i;
         endcase
      end
   end

   ////////////////////////////////////////////////////////////////////////////
   // Register Read
   always @(posedge S_AXI_ACLK)begin
      if(regread)begin
         S_AXI_RDATA <= 0;
         case({rd_adr_i[9:2],2'b00})
           10'h00: S_AXI_RDATA[2:0] <= {last, run, matw};
           10'h10: S_AXI_RDATA <= control;
         endcase
      end
   end
endmodule
