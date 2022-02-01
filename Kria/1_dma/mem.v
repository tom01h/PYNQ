/**********************************************************************\
*      addrress range   access size   function                         *
* reg  0x000            32bit         [0] stream write [1] stream read *
* reg  0x004            32bit         [7:0] stream size                *
* reg  0x010            32bit         dummy control                    *
* mem1 0x400-0x7fc      32bit                                          *
\**********************************************************************/
module mem
  (
   input wire        S_AXI_ACLK,
   input wire        S_AXI_ARESETN,

   ////////////////////////////////////////////////////////////////////////////
   // AXI Lite Slave Interface
   input wire [31:0] S_AXI_AWADDR,
   input wire        S_AXI_AWVALID,
   output wire       S_AXI_AWREADY,
   input wire [31:0] S_AXI_WDATA,
   input wire [3:0]  S_AXI_WSTRB,
   input wire        S_AXI_WVALID,
   output wire       S_AXI_WREADY,
   output wire [1:0] S_AXI_BRESP,
   output wire       S_AXI_BVALID,
   input wire        S_AXI_BREADY,

   input wire [31:0] S_AXI_ARADDR,
   input wire        S_AXI_ARVALID,
   output wire       S_AXI_ARREADY,
   output reg [31:0] S_AXI_RDATA,
   output wire [1:0] S_AXI_RRESP,
   output wire       S_AXI_RVALID,
   input wire        S_AXI_RREADY,


   input wire        AXIS_ACLK,
   input wire        AXIS_ARESETN,

   ////////////////////////////////////////////////////////////////////////////
   // AXI Stream Master Interface
   output reg        M_AXIS_TVALID,
   output reg [31:0] M_AXIS_TDATA,
   output wire [3:0] M_AXIS_TSTRB,
   output wire       M_AXIS_TLAST,
   input wire        M_AXIS_TREADY,

   ////////////////////////////////////////////////////////////////////////////
   // AXI Stream Slave Interface
   output wire       S_AXIS_TREADY,
   input wire [31:0] S_AXIS_TDATA,
   input wire [3:0]  S_AXIS_TSTRB,
   input wire        S_AXIS_TLAST,
   input wire        S_AXIS_TVALID
   );

   ////////////////////////////////////////////////////////////////////////////
   // AXI Stream State Control
   reg                s1readr, s1writer;
   reg [8:0]          ssize;
   reg [10:2]         st_adr_i;
   wire               s1read0  = s1readr &(st_adr_i!=ssize)&M_AXIS_TREADY;
   wire               s1write0 = s1writer&(st_adr_i!=ssize)&S_AXIS_TVALID;
   reg                s1read1;

   assign S_AXIS_TREADY = s1writer&(st_adr_i!=ssize);
   assign M_AXIS_TLAST = 1'b0;
   assign M_AXIS_TSTRB = 4'hf;

   always @(posedge S_AXI_ACLK)begin
      if(M_AXIS_TREADY)begin
         s1read1 <= s1read0;
      end
      M_AXIS_TVALID <= s1read1;
      if(~S_AXI_ARESETN)begin
         st_adr_i <= 9'h0;
      end else if(s1read0|s1write0)begin
         st_adr_i <= st_adr_i + 1;
      end else if(~s1readr&~s1writer)begin
         st_adr_i <= 9'h0;
      end
   end
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
   wire [11:2] wb_adr_p = ((s1write0) ?                    {2'b00,st_adr_i[9:2]} :
                           (S_AXI_AWVALID&S_AXI_AWREADY) ? S_AXI_AWADDR[11:2]
                           :                               wb_adr_i[11:2]  );
   wire [31:0] wb_dat_p = ((s1write0) ?                   S_AXIS_TDATA :
                           (S_AXI_WVALID &S_AXI_WREADY) ? S_AXI_WDATA
                           :                              wb_dat_i  );
   wire [11:2] rd_adr_p = ((s1read0) ? {2'b00,st_adr_i[9:2]}
                           :            S_AXI_ARADDR[9:2]  );

   wire        regwrite = (axist==4'b0011) & (wb_adr_i[11:10]==2'b00);
   wire        regread  = (axist==4'b0100) & (rd_adr_i[11:10]==2'b00);

   wire        m1write0 = ((axist[1] | (S_AXI_WVALID &S_AXI_WREADY)) &
                           (axist[0] | (S_AXI_AWVALID&S_AXI_AWREADY))&
                           (axist!=4'b0011))           & (wb_adr_p[11:10]==2'b01);
   wire        m1write1 = (axist==4'b0011)             & (wb_adr_i[11:10]==2'b01);
   wire        m1read0  = S_AXI_ARVALID &S_AXI_ARREADY & (S_AXI_ARADDR[11:10]==2'b01);
   wire        m1read1  = (axist==4'b0100)             & (rd_adr_i[11:10]==2'b01);

   ////////////////////////////////////////////////////////////////////////////
   // Memory
   reg [31:0]  mem1 [0:255];
   reg [31:0]  mrd1;

   always @(posedge S_AXI_ACLK)begin
     if(m1write0|s1write0)
       mem1[wb_adr_p[9:2]] <= wb_dat_p;
     else if(m1read0|s1read0)
       mrd1 <= mem1[rd_adr_p];
   end

   ////////////////////////////////////////////////////////////////////////////
   // Register
   always @(posedge S_AXI_ACLK)begin
      if(~S_AXI_ARESETN)begin
         control <= 32'h0;
         {s1readr, s1writer} <= 2'b00;
         ssize[8:0] <= 9'h0;
      end else if(regwrite)begin
         case({wb_adr_i[9:2],2'b00})
           10'h00: {s1readr, s1writer} <= wb_dat_i[1:0];
           10'h04: ssize[8:0] <= wb_dat_i[8:0];
           10'h10: control <= wb_dat_i;
         endcase
      end
   end

   ////////////////////////////////////////////////////////////////////////////
   // Read
   always @(posedge S_AXI_ACLK)begin
      if(regread)begin
         case({rd_adr_i[9:2],2'b00})
           10'h00: S_AXI_RDATA[1:0] <= {s1readr, s1writer};
           10'h04: S_AXI_RDATA[8:0] <= ssize[8:0];
           10'h10: S_AXI_RDATA <= control;
         endcase
      end else if(m1read1)begin
         S_AXI_RDATA <= mrd1;
      end
      if(s1read1&M_AXIS_TREADY)begin
         M_AXIS_TDATA <= mrd1;
      end
   end
endmodule
