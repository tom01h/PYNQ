module core
  (
   input wire        clk,
   input wire        init,
   input wire        write,
   input wire        exec,
//   input wire         outr,
   input wire [2:0]  ra,
   input wire [2:0]  wa,
   input wire [31:0] d,
   input wire [31:0] wd,
   output reg [31:0] acc
   );

   reg [31:0]        matrix [0:7];
   reg [31:0]        m;

   always_ff @(posedge clk)begin
      if(write)begin
         matrix[wa] <= wd;
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

   always_ff @(posedge clk)begin
      if(init2)begin
         acc <= 32'h0;
      end else if(exec2)begin
         acc <= acc + m2 * d2;
      end
   end

endmodule
