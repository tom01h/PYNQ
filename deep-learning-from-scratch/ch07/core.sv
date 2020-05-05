module core
  (
   input wire        clk,
   input wire        init,
   input wire        write,
   input wire        exec,
   input wire        outr,
   input wire        update,
   input wire [4:0]  ra,
   input wire [4:0]  wa,
   input wire [31:0] d,
   input wire [64:0] wd,
   input wire        ws,
   input wire [31:0] acc_in,
   output reg [31:0] acc
   );

   reg [31:0]        matrix [0:31];
   reg [31:0]        m;

   reg [31:0]        acct, accl;

   assign acc  = (update) ? accl  : acct;

   always_ff @(posedge clk)begin
      if(write)begin
         if(ws)begin
            matrix[wa] <= wd[63:32];
         end else begin
            matrix[wa] <= wd[31:0];
         end
      end else if(exec)begin
         m <= matrix[ra];
      end
   end

   reg               init1, init2;
   reg               exec1, exec2;

   always_ff @(posedge clk)begin
      init1 <= init;
      init2 <= init1;
      exec1 <= exec;
      exec2 <= exec1;
   end   

   reg [31:0]        m2,d2;
   always_ff @(posedge clk)begin
      if(exec1)begin
         m2 <= m;
         d2 <= d;
      end
   end   

   wire        m2_s = m2[31];
   wire [10:0] m2_e = m2[30:23] - 127 + 1023;
   wire [51:0] m2_f ={m2[22:0],29'h0};
   real        m2_r;
   always @*
     if(m2[30:23]==0)
       m2_r = 0;
     else
       m2_r = $bitstoreal({m2_s,m2_e,m2_f});

   wire        d2_s = d2[31];
   wire [10:0] d2_e = d2[30:23] - 127 + 1023;
   wire [51:0] d2_f ={d2[22:0],29'h0};
   real        d2_r;
   always @*
     if(d2[30:23]==0)
       d2_r = 0;
     else
       d2_r = $bitstoreal({d2_s,d2_e,d2_f});

   real        accl_r;
   always_ff @(posedge clk)begin
      if(init2)begin
         accl_r <= 0;
      end else if(exec2)begin
         accl_r <= accl_r + m2_r * d2_r;
      end
      if(outr)begin
         acct <= acc_in;
      end
   end
   wire [63:0] accl_w = $realtobits(accl_r);
   wire        accl_s = accl_w[63];
   wire [7:0]  accl_e = accl_w[62:52] - 1023 + 127;
   wire [22:0] accl_f = accl_w[51:(51-22)];
   always @*
     if(accl_w[62:52]==0)
       accl = 32'h0;
     else
       accl = {accl_s,accl_e,accl_f};

/*
   always_ff @(posedge clk)begin
      if(init2)begin
         accl <= 32'h0;
      end else if(exec2)begin
         accl <= accl + m2 * d2;
      end
      if(outr)begin
         acct <= acc_in;
      end
   end
*/
endmodule
