module ex_ctl
  (
   input wire        clk,
   input wire        rst,
   input wire        s_init,
   input wire        out_busy,
   input wire        outr,
   output wire       s_fin,
   output wire       k_init,
   output wire       k_fin,
   output wire       exec,
   output wire [4:0] ia,
   output wire [2:0] wa
   );
   
   wire               last_dc, last_ic;
   wire               next_dc, next_ic;
   wire [2:0]                       ic;
   wire [1:0]         dc;


   loop1 #(.W(2)) l_dc(.ini(2'd0), .fin(3),   .data(dc), .start(s_init),  .last(last_dc),
                       .clk(clk),  .rst(rst),             .next(next_dc),   .en(last_ic)  );

   wire               s_init0, k_init0, start;
   assign k_init = s_init0 | k_init0&!out_busy;

   dff #(.W(1)) d_s_init0(.in(s_init), .data(s_init0), .clk(clk), .rst(rst), .en(1'b1));
   dff #(.W(1)) d_exec   (.in(k_init|exec&!last_ic), .data(exec), .clk(clk), .rst(rst), .en(1'b1));
   dff #(.W(1)) d_start  (.in(k_init), .data(start), .clk(clk), .rst(rst), .en(1'b1));

   loop1 #(.W(3)) l_ic(.ini(3'd0), .fin(7),   .data(ic), .start(start),   .last(last_ic),
                       .clk(clk),  .rst(rst),             .next(next_ic),   .en(1'b1)  );

   assign ia = dc*8 + ic;
   assign wa = ic;

// ic loop end

   dff #(.W(1)) d_k_fin (.in(last_ic), .data(k_fin), .clk(clk), .rst(rst), .en(1'b1));
   dff #(.W(1)) d_k_init0 (.in(next_dc&!s_init), .data(k_init0), .clk(clk),
                           .rst(rst), .en(!out_busy|next_ic));

// dc loop end

   wire               s_fin0, s_fin1, s_fin2, s_fin3;

   dff #(.W(1)) d_s_fin0 (.in(last_dc), .data(s_fin0), .clk(clk), .rst(rst), .en(1'b1));
   dff #(.W(1)) d_s_fin1 (.in(s_fin0), .data(s_fin1), .clk(clk), .rst(rst), .en(1'b1));
   dff #(.W(1)) d_s_fin2 (.in(s_fin1), .data(s_fin2), .clk(clk), .rst(rst), .en(1'b1));
   dff #(.W(1)) d_s_fin3 (.in(s_fin2), .data(s_fin3), .clk(clk), .rst(rst), .en(!outr|s_fin2));

   assign s_fin = s_fin3 & !outr;

endmodule
