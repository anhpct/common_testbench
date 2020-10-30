/* ------------------------------------------------------------------------
日付　　： 2020/04/24
名前	: timer
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
 
 
 module timer(
  clk,rst_n,sel,tout_10,tout_100,
  read,write,addr,wdata,rdata
  );
/* ----- input/ output ----- */
  input clk,rst_n,sel;
  input read,write;              //read and write input signal
  input [`ADDR:0] addr;         // address input
  input [`WDATA:0]wdata;       // write data input
  output[`RDATA:0]rdata;      // read data output
  output reg tout_10;        // timer output
  output reg tout_100;      // timer output
  
  
  reg clk2,sel1,sel_out,cnt_adj;	
  reg [`CNT1:0]cnt1;     // number of bits counter 1
  reg [`CNT2:0]cnt2;     // number of bits counter 2
  wire clk_out;
  wire[`COMP:0] comp_out;
  wire flag1,flag2,comb;
  
  wire [7:0]startstop;     
  wire [7:0]timer1;          
  wire [7:0]timer2;         
  
  wire start_flag,clrcnt_flag;
  wire [3:0]CMP1_flagA,CMP1_flagB,CMP2_flagA,CMP2_flagB;         // compare flag
  parameter UD=1; // Unit delay

/* -----Multiplexer------ */   
  assign clk_out = (sel_out==1'b0) ? clk : clk2;                 // change clock 
  assign comp_out = (sel_out==1'b0) ? CMP1_flagA : CMP1_flagB;   // sel_out=0 comp_out=9 or sel_out=1 comp_out=4
  
/* -----Output of comparator-----  */ 
  assign  flag1 =(cnt1 == comp_out)?1:0;
  assign  flag2 =(cnt2 == CMP2_flagA)?1:0;
  assign  comb = flag1 && flag2;   
  
  wire clr_comb;     // if start_flag = 0 and clrcnt_flag = 1, clear counter
  assign clr_comb = clrcnt_flag & ~start_flag ;
  //assign clr_cnt2 = clr_comb | flag2;

/*  write enable data flag */
  wire WE1,WE2,WE3;
  assign WE1 = (write && (addr[`ADDR:0] == 2'b00)) ? 1 :0; 
  assign WE2 = (write && (addr[`ADDR:0] == 2'b01)) ? 1 :0;
  assign WE3 = (write && (addr[`ADDR:0] == 2'b10)) ? 1 :0;
  
/*  start/stop clear flag */
  assign start_flag  = startstop[0];
  assign clrcnt_flag = startstop[7];
/*  counter 1 compare flag  */
  assign CMP1_flagA  = timer1[3:0]; 
  assign CMP1_flagB  = timer1[7:4];
/*  counter 2 compare flag  */
  assign CMP2_flagA  = timer2[3:0];
  assign CMP2_flagB  = timer2[7:4];
  
  
  assign startstop[7:0] = (rst_n==1'b0) ? `DEFAULT1 :                     // default stage: startstop = 8'h00   
						  (WE1==1'b1) ? wdata[7:0]  : startstop[7:0];  // enable flag = 1 write data into startstop register				  
  assign timer1[7:0]    = (rst_n==1'b0) ? `DEFAULT2 :                     // default stage: timer1 = 8'h99   
                          (WE2==1'b1) ? wdata[7:0]  : timer1[7:0];     // enable flag = 1 write data into timer1 register
  assign timer2[7:0]    = (rst_n==1'b0) ? `DEFAULT2 :                     // default stage: timer2 = 8'h99   
                          (WE3==1'b1) ? wdata[7:0]  : timer2[7:0];  	  // enable flag = 1 write data into timer2 register				   
/* read data in register */
  wire RE1,RE2,RE3;
  assign RE1 = (read && (addr[`ADDR:0] == 2'b00)) ? 1 :0;
  assign RE2 = (read && (addr[`ADDR:0] == 2'b01)) ? 1 :0;
  assign RE3 = (read && (addr[`ADDR:0] == 2'b10)) ? 1 :0;
  
  assign rdata[7:0] = (RE1==1'b1)? {startstop[7],6'h00,startstop[0]}:
                      (RE2==1'b1)? {CMP1_flagB[3:0],CMP1_flagA[3:0]}:
			          (RE3==1'b1)? {CMP2_flagB[3:0],CMP2_flagA[3:0]}: 8'h0;
				 
/* -----Clock divider------ */  
  always @(posedge clk or negedge rst_n) begin
  if(rst_n==1'b0)
     clk2 <= #(UD) 1'b0;             // UDが抜けているところを直した
  else
	 clk2 <= #(UD)~clk2;            // clk2 = 0.5 Mhz
  end
/* -----synchronization------ */   
  always @(posedge clk2 or negedge rst_n) begin  // synchronized sel1 with clk2 
  if (rst_n == 1'b0)
     sel1 <= #(UD)1'b0;
  else
     sel1 <= #(UD)sel;
  end  
  always @(posedge clk2 or negedge rst_n) begin  // synchronized sel_out with clk2 and comb
  if (rst_n == 1'b0)
     sel_out <= #(UD)1'b0;
  else if(comb == 1'b0)
     sel_out <= #(UD)sel_out;  
  else
	 sel_out <= #(UD)sel1;
  end
/* ----------Timer 1 ----------- */
  always @(posedge clk) begin   // cnt_adj 同期リセット　　　同期リセットで抜けるとろこを直した。
    if (clr_comb)
	 cnt_adj = #(UD) 1'b0;
  end
  always @(posedge clk2 or negedge rst_n) begin  // adjusting counter1 signal
  if(rst_n == 1'b0)             
     cnt_adj <= #(UD)1'b0;
  else if ((clr_comb == 1'b0) && (rst_n == 1'b1))
     cnt_adj <= #(UD)1'b1;
  end  
  
  always @(posedge clk) begin   // cnt1 同期リセット
     if (clr_comb)
	 cnt1 = #(UD) 1'b0;
  end   
  always @(posedge clk_out or negedge rst_n)begin  //Counter1 4bits
  if(rst_n == 1'b0)                      //  reset　非同期
     cnt1 <= #(UD)1'b0; 
  else if (cnt_adj == 1'b0 || flag1 == 1'b1) 
     cnt1 <= #(UD) 1'b0 ;  //  reset　非同期
  else if(start_flag && cnt_adj)
     cnt1 <= #(UD) cnt1+1;  
  end
  
  always @(posedge clk_out or negedge rst_n) begin  //DFF4
  if(rst_n == 1'b0)                     //  reset　非同期
     tout_10 <= #(UD)1'b0;
  else 
     tout_10 <= #(UD)(flag1==1) ? 1 : 0;         //  reset　非同期
  end
  
  /* ----------Timer 2 ----------- */
  always @(posedge clk) begin   // cnt2 同期リセット　　　　同期リセットで抜けるとろこを直した。
     if (clr_comb)
	 cnt2 = #(UD) 1'b0;
  end 
  always @(posedge clk_out or negedge rst_n) begin   //Counter2 4bits
  if(rst_n==1'b0)                          //  reset　非同期
     cnt2 <= #(UD)1'b0;
  else if ( comb ) 
     cnt2<=#(UD)1'b0; 
  else if(flag1)                          
     cnt2<=#(UD) cnt2+1;      //  reset　非同期
  end  

  always @(posedge clk_out or negedge rst_n) begin  //DFF5
  if(rst_n == 1'b0)                      //  reset　非同期
     tout_100 <= #(UD)1'b0;
  else 
     tout_100 <= #(UD)(comb == 1) ? 1 : 0;   // AND gate flag1, flag2
  end
  endmodule 