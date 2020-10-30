/* ------------------------------------------------------------------------
日付　　： 2020/04/24
名前	: timer_tb
機能	: 
設計者	：アイン
確認者	：花盛
Icarus cmd: iverilog timer.v timer_tb.v -o timer_tb.o
			vvp timer_tb.o -> logfile.txt
            gtkwave timer.vcd
------------------------------------------------------------------------ */
`timescale 1ns/1ps

/* for main definiton */

 `define CNT1 3      //  number bit data of counter 1

 `define CNT2 3      //  number bit data of counter 2

 `define COMP 3      //  number bit data of comp_out

 `define ADDR 1

 `define WDATA 7

 `define RDATA 7 

 `define DEFAULT1  8'h00  // default startstop value

 `define DEFAULT2  8'h99  // default timer value

/* for testbench definiton */

 `define WIDTH1 10000    // =10us

 `define WIDTH2 50000    // SW = 4'h4 -> tout_100 = 50us and WIDTH2 = 50000

 `define WIDTH3 100000   // SW = 4'h9 -> tout_100 = 100us and WIDTH2 = 100000
 
 
module timer_tb;
reg clk,rst_n,sel;
reg read,write;
reg [1:0]addr;
reg [7:0]wdata;

wire [7:0]rdata;
wire tout_10;
wire tout_100;

parameter CYC =1000; // clock period 1us
integer i,j;
/* ------DUT Instantiation------ */
timer tb(
.clk (clk),
.rst_n (rst_n),
.sel (sel),
.write (write),
.read (read),
.addr (addr),
.wdata (wdata),
.rdata (rdata),
.tout_10 (tout_10),
.tout_100 (tout_100)
);
/* -------初期値セット--------- */
 initial begin
     clk = 1'b0;rst_n = 1'b0; sel = 1'b0;
	 write = 1'b0;read = 1'b0;wdata=8'h00;
 end
/* -------1MHZクロックを作成-------- */
initial begin
forever #(CYC/2) clk = !clk;
end

// coverage off
/* Display reset event in the logfile */
 always @( rst_n) begin   // Notifications  have a reset event
  if (rst_n)
     $display(" Reset = 1   Time: %t ", $realtime);
  else
     $display(" Reset = 0   Time: %t", $realtime);
     $timeformat(-6, 3, " us", 12);  
  end

 always @(sel)  
   begin
     if (sel ==1'b0) 
	 $display(" Select = 0    1Mhz     Time: %t", $realtime);
	 else if (sel ==1'b1) 
	 $display(" Select = 1    0.5Mhz    Time: %t", $realtime);
	 $timeformat(-6, 3, " us", 12);  
  end
  
/* --------timer の幅を表示する-------- */
 real edge10,edge100;
/* -timer 10us の幅を表示する- */
 always@(rst_n) begin
  if(rst_n==0) 
     i=0;j=0;
  end
 always @(posedge tout_10) begin
     i = i+1;
	 edge10 <= $realtime;
     $timeformat(-6, 3, " us", 12);  
 if (i>=2)   // intervalの計算のは tout_10の１周期がディレイ
   if ( (($realtime-edge10) >= `WIDTH1-1) && (($realtime-edge10) <= `WIDTH1+1) )
     $display("interval_num_%2d",i-1,"    In fact tout_10 = %t", ($realtime-edge10)," - PASS  "," at time: ",$realtime); 
   else 
     $display("interval_num_%2d",i-1,"    In fact tout_10 = %t", ($realtime-edge10)," - FAIL  "," at time: ",$realtime); 
end

always @(posedge tout_100) begin
     j = j+1;
     edge100 <= $realtime;
   $timeformat(-6, 3, " us", 12);  
 if (j>=2)   // intervalの計算のは tout_10の１周期がディレイ
   if ( (($realtime-edge100) >= `WIDTH2-1) && (($realtime-edge100) <= `WIDTH2+1) )
   $display("\ninterval_num_%2d",j-1,"    In fact tout_100 = %t", ($realtime-edge100)," - PASS  ","at time: ",$realtime,"  setup tout_100 = 50us \n"); 
   else if ( (($realtime-edge100) >= `WIDTH3-1) && (($realtime-edge100) >= `WIDTH3+1)  )
   $display("\ninterval_num_%2d",j-1,"    In fact tout_100 = %t", ($realtime-edge100)," - PASS  ","at time: ",$realtime,"  setup tout_100 = 100us \n"); 
   else 
   $display("\ninterval_num_%2d",j-1,"    In fact tout_100 = %t", ($realtime-edge100)," - FAIL  ","at time: ",$realtime,"\n"); 
end 

/* write data in Block function */
task WRITE_DATA;
input [1:0]W_ADDR;
input [7:0]W_DATA ;
  begin
     // #(CYC*1) 
	 addr = W_ADDR;
	 wdata = W_DATA;#(CYC*1) 
     write =1'b1;#(CYC*1) 
	 write=1'b0;addr[1:0]= 2'b00;#1
	 wdata=1'b0;
  end
 endtask
 // coverage off
/* read data in Block function */
 task READ_DATA;
 input [1:0]R_ADDR;
  begin
     addr[1:0] = R_ADDR[1:0];#(CYC*1)
	 read = 1'b1; #1 
	case (addr)
	2'b00: $display("At address %2b  :   Data in the startstop register = %h",addr,rdata,"　  at time: ",$realtime); 
	2'b01: $display("At address %2b  :   Data in the timer1 register    = %h",addr,rdata,"　  at time: ",$realtime);
	2'b10: $display("At address %2b  :   Data in the timer2 register    = %h",addr,rdata,"　  at time: ",$realtime);
	endcase
	#(CYC*1)
	 read=1'b0;addr[1:0]= 2'b00;
  end
 endtask
 // coverage on 
 
 /*   -----------------------TEST PATTERN------------------------ */
initial begin
// insert on
 $dumpfile ("TP_003_tb.vcd");  $dumpvars(0,timer_tb); 
 //クロック切替　tout_100出力は3回行う when tout_100 = 100us
 sel = 1'b1;
 WRITE_DATA(2'b00,8'h80);#(CYC*10)                            // start_flag=0 and cntclr_flag =0 => clear counter
 WRITE_DATA(2'b00,8'h1);#(CYC*500)                            // start_flag=1 => start counter
 READ_DATA(2'b00);#(CYC*1)     // checking read data in startstop register
 READ_DATA(2'b01);#(CYC*1)     // checking read data in timer1 register
 READ_DATA(2'b10);#(CYC*1)     // checking read data in timer2 register  
 sel = 1'b0; #(CYC*150) 
 
 //if press reset, circuit become default stage: startstop = 8'h99,timer1 = 8'h99, timer2 = 8'h99
 rst_n = 1'b0;#(CYC*20)  
 
 // write data from CPU into register timer1 = 8'h49, timer2 = 8'h4 => tout_10 = 10us and tout_100 = 50us
 rst_n = 1'b1;
 WRITE_DATA(2'b00,8'h01);WRITE_DATA(2'b01,8'h49);WRITE_DATA(2'b10,8'h4);#(CYC*150)  
 READ_DATA(2'b00);#(CYC*1)     // checking read data in startstop register
 READ_DATA(2'b01);#(CYC*1)     // checking read data in timer1 register
 READ_DATA(2'b10);#(CYC*1)     // checking read data in timer2 register
 
 //クロック切替　tout_100出力は3回行う when tout_100 = 50us
 sel = 1'b1;
 WRITE_DATA(2'b00,8'h80);#(CYC*10)                            // start_flag=0 and cntclr_flag =0 => clear counter
 WRITE_DATA(2'b00,8'h1);#(CYC*200)                            // start_flag=1 => start counter
 READ_DATA(2'b00);#(CYC*1)     // checking read data in startstop register
 READ_DATA(2'b01);#(CYC*1)     // checking read data in timer1 register
 READ_DATA(2'b10);#(CYC*1)     // checking read data in timer2 register  
 
 sel = 1'b0;
 WRITE_DATA(2'b00,8'h81);#(CYC*50)
 WRITE_DATA(2'b00,8'h01);
 #(CYC*150)  

$finish;     // Simulation STOP条件
end
endmodule
