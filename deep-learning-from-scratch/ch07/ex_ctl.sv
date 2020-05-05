module ex_ctl
  (
   input wire        clk,
   input wire        rst,
   input wire        s_init,
   input wire        out_busy,
   input wire        outrf,
   output wire       s_fin,
   output wire       k_init,
   output wire       k_fin,
   output wire       exec,
   output wire [9:0] ia,
   output wire [4:0] wa
   );
   
   parameter sample = 40-1;
   parameter ic_max = 25-1;

   wire               last_dc, last_ic;
   wire               next_dc, next_ic;
   wire [4:0]                       ic;
   wire [5:0]         dc;


   loop1 #(.W(6)) l_dc(.ini(6'd0), .fin(sample), .data(dc), .start(s_init),  .last(last_dc),
                       .clk(clk),  .rst(rst),                .next(next_dc),   .en(last_ic)  );

   wire               s_init0, k_init0, start;
   assign k_init = s_init0 | k_init0&!out_busy;

   dff #(.W(1)) d_s_init0(.in(s_init), .data(s_init0), .clk(clk), .rst(rst), .en(1'b1));
   dff #(.W(1)) d_exec   (.in(k_init|exec&!last_ic), .data(exec), .clk(clk), .rst(rst), .en(1'b1));
   dff #(.W(1)) d_start  (.in(k_init), .data(start), .clk(clk), .rst(rst), .en(1'b1));

   loop1 #(.W(5)) l_ic(.ini(5'd0), .fin(ic_max), .data(ic), .start(start),   .last(last_ic),
                       .clk(clk),  .rst(rst),                .next(next_ic),   .en(1'b1)  );

   assign ia = dc*(ic_max+1) + ic;
   assign wa = ic;

// ic loop end

   dff #(.W(1)) d_k_fin (.in(last_ic), .data(k_fin), .clk(clk), .rst(rst), .en(1'b1));
   dff #(.W(1)) d_k_init0 (.in(next_dc&!s_init), .data(k_init0), .clk(clk),
                           .rst(rst), .en(!out_busy|next_dc));

// dc loop end

   wire               s_fin0;

   dff #(.W(1)) d_s_fin0 (.in(last_dc), .data(s_fin0), .clk(clk), .rst(rst), .en(last_dc|outrf));
   dff #(.W(1)) d_s_fin (.in(s_fin0&outrf), .data(s_fin), .clk(clk), .rst(rst), .en(1'b1));

endmodule
