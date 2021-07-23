module regs
  (
   input wire        S_AXI_ACLK,
   input wire        S_AXI_ARESETN,

   ////////////////////////////////////////////////////////////////////////////
   // AXI Lite Slave Interface
   input wire [31:0] S_AXI_AWADDR,
   input wire        S_AXI_AWVALID,
   output wire       S_AXI_AWREADY,
   input wire [63:0] S_AXI_WDATA,
   input wire [7:0]  S_AXI_WSTRB,
   input wire        S_AXI_WVALID,
   output wire       S_AXI_WREADY,
   output wire [1:0] S_AXI_BRESP,
   output wire       S_AXI_BVALID,
   input wire        S_AXI_BREADY,

   input wire [31:0] S_AXI_ARADDR,
   input wire        S_AXI_ARVALID,
   output wire       S_AXI_ARREADY,
   output reg [63:0] S_AXI_RDATA,
   output wire [1:0] S_AXI_RRESP,
   output wire       S_AXI_RVALID,
   input wire        S_AXI_RREADY

   );

   ////////////////////////////////////////////////////////////////////////////
   // AXI Lite Slave State Control
   reg [3:0]         axist;
   reg [11:2]        wb_adr_i;
   reg [11:2]        rd_adr_i;
   reg [63:0]        wb_dat_i;
   reg [7:0]         wb_wen_i;

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
         wb_wen_i<=0;
      end else if(axist==4'b000)begin
         if(S_AXI_AWVALID & S_AXI_WVALID)begin
            axist<=4'b0011;
            wb_adr_i[11:2]<=S_AXI_AWADDR[11:2];
            wb_dat_i<=S_AXI_WDATA;
            wb_wen_i<=S_AXI_WSTRB;
         end else if(S_AXI_AWVALID)begin
            axist<=4'b0001;
            wb_adr_i[11:2]<=S_AXI_AWADDR[11:2];
         end else if(S_AXI_WVALID)begin
            axist<=4'b0010;
            wb_dat_i<=S_AXI_WDATA;
            wb_wen_i<=S_AXI_WSTRB;
         end else if(S_AXI_ARVALID)begin
            axist<=4'b0100;
            rd_adr_i[11:2]<=S_AXI_ARADDR[11:2];
         end
      end else if(axist==4'b0001)begin
         if(S_AXI_WVALID)begin
            axist<=4'b0011;
            wb_dat_i<=S_AXI_WDATA;
            wb_wen_i<=S_AXI_WSTRB;
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

   wire        regwrite = (axist==4'b0011);
   wire        regread  = (axist==4'b0100);

   ////////////////////////////////////////////////////////////////////////////
   // Register
   reg [63:0] data;
   reg [7:0]  wstrb;

   always @(posedge S_AXI_ACLK)begin
      if(~S_AXI_ARESETN)begin
         data  <= 'b0;
         wstrb <= 'b0;
      end else if(regwrite)begin
         case({wb_adr_i[9:3],3'b000})
           10'h00: if(wb_wen_i[7:4] == 'hf) begin data[63:0]  <= wb_dat_i[63:0];  wstrb <= wb_wen_i[7:0]; end
           10'h10: begin data[31:0]  <= wb_dat_i[31:0];  wstrb <= wb_wen_i[7:0]; end
           10'h18: begin data[63:32] <= wb_dat_i[63:32]; wstrb <= wb_wen_i[7:0]; end
         endcase
      end
   end

   ////////////////////////////////////////////////////////////////////////////
   // Read
   always @(posedge S_AXI_ACLK)begin
      if(regread)begin
         case({rd_adr_i[9:3],3'b000})
           10'h00: S_AXI_RDATA <= data[63:0];
           10'h08: S_AXI_RDATA <= {2{24'b0,wstrb[7:0]}};
           10'h10: S_AXI_RDATA <= {2{data[31:0]}};
           10'h18: S_AXI_RDATA <= {2{data[63:32]}};
         endcase
      end
   end
endmodule
