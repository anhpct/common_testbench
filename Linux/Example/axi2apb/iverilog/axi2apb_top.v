/* ------------------------------------------------------------------------
日付　　： 2020/05/27
名前	: axi2apb_top.v
機能	: AXI-Lite to APB bridge
設計者	：アイン
確認者	：花盛
Icarus cmd: iverilog axi2apb_top.v bridge_status.v bridge_stm.v bridge_decoder.v axi2apb_tb.v -o axi2apb_tb.o
            vvp axi2apb_tb.o
            gtkwave axi2apb.vcd
------------------------------------------------------------------------ */
`timescale 1ns/1ps

/* for main definiton */

`define  OKAY            2'b00

`define  EXOKAY          2'b01

`define  SLVERR          2'b10

`define  DECERR          2'b11



`define AXI4_ADDR_WIDTH  32         // 32bits address AXI

`define AXI4_RDATA_WIDTH 32         // 32bits read AXI

`define AXI4_WDATA_WIDTH 32         // 32bits write AXI

`define APB_ADDR_WIDTH   16         // 16bits address APB



`define  AXI_IDLE        3'b001     //1

`define  SEND_RADDR      3'b010     //2

`define  RDATA_WAIT      3'b011     //3

`define  RDATA_TRANSFER  3'b100     //4

`define  ADDR_WRITE_DATA 3'b101     //5

`define  WDATA_WAIT      3'b110     //6

`define  WRITE_END       3'b111     //7

  

`define  APB_IDLE        3'b001     //1

`define  APB_RSETUP      3'b010     //2

`define  APB_RACCESS     3'b011     //3

`define  APB_WSETUP      3'b100     //4

`define  APB_WACCESS     3'b101     //5


/* for testbench definiton */
 module axi2apb_top(
     ACLK,ARESETn,
     AWADDR,AWVALID,AWREADY,AWPROT,WDATA,WVALID,WREADY,BRESP,BVALID,BREADY,
     ARADDR,ARVALID,ARREADY,ARPROT,RDATA,RRESP,RVALID,RREADY,
     PCLK,PRST_n,PADDR,PWRITE,PSEL,PENABLE,PWDATA,PRDATA,PREADY,PSLVERR	 
  );

   parameter UD                 = 1;          // Unit delay
 
/* ----- input/ output ----- */
   input                              ACLK;         // バスクロック信号
   input                              ARESETn;      // リセット信号,LOWアクティブ
  
// AXI-Lite slave interface 入出力
  // AXI-Lite write address bus
   input[`AXI4_ADDR_WIDTH-1:0]        AWADDR;       //AXIバスライトアドレス信号です。
   input                              AWVALID;      //AXIバス AWADDRアドレスチャネルの値が有効であることを示す信号です。
   input[2:0]                         AWPROT;       //AXIバスライトアクセスの保護レベルを示す信号です。
   output                             AWREADY;      //AXIバス スレーブがライトアドレスを受信していることを示す信号です。
  // AXI-Lite write data bus 
   input[`AXI4_WDATA_WIDTH-1:0]       WDATA;        //AXIバスライトデータ信号です。
   input                              WVALID;       //AXIバスライトデータの値が有効であることを示す信号です。
   output                             WREADY;       //AXIバス スレーブがライトデータを受信していることを示す信号です。  
 // AXI-Lite write response bus  
   output[1:0]                        BRESP;        //AXIバス スレーブのライト応答信号です。	
   output                             BVALID;       //AXIバス スレーブのライト応答が有効であることを示す信号です。
   input                              BREADY;       //AXIバスマスタが応答受信可能状態であることを示す信号です。
 // AXI-Lite read address bus
   input[`AXI4_ADDR_WIDTH-1:0]        ARADDR;       //AXIバスリードアドレス信号です。
   input                              ARVALID;      //AXIバス ARADDRアドレスチャネルの値が有効であることを示す信号です。
   input[2:0]                         ARPROT;       //AXIバスリードアクセスの保護レベルを示す信号です。
   output                             ARREADY;      //AXIバス スレーブがリードアドレスを受信していることを示す信号です。
 // AXI-Lite read data bus   
   output[`AXI4_RDATA_WIDTH-1:0]      RDATA;        //AXIバス スレーブからのリードデータ信号です。
   output                             RVALID;       //AXIバス スレーブからのリード応答が有効であることを示す信号です。
   output[1:0]                        RRESP;        //AXIバス スレーブからのリード応答信号です。
   input                              RREADY;       //AXIバス マスタがリードデータ受信可能状態であることを示す信号です。

// APB master interface 入出力
   input                              PCLK;         //APBクロック信号
   input                              PRST_n;       //APBシステムリセット信号です。LOWアクティブです。
   input                              PREADY;       //APBレディ信号です。
   input                              PSLVERR;      //APB転送エラーが発生したことをマスタに伝える信号です。
   input[`AXI4_RDATA_WIDTH-1:0]       PRDATA;       //APBリードデータです。
   output[`AXI4_ADDR_WIDTH/2-1:0]     PADDR;        //APBアドレス信号です。
   output                             PWRITE;       //APBアクセス信号です。"1"のときはライト、"0"のときはリードです。
   output                             PSEL;         //APBバスセレクト信号です。本セルはIOブロックへのアクセスを示します。
   output                             PENABLE;      //APB バス転送の2 番目以降のサイクルであることを示します。
   output[`AXI4_WDATA_WIDTH-1:0]      PWDATA;       //APBライトデータです。
   
   wire         SLVERR_sign;   
   wire         tout;
   wire         avalidend;
   wire         dvalidend;
   wire         x_valid;
   
   wire[2:0]    AXI_next_state;                     // AXI state machine
   wire[2:0]    AXI_present_state;                  // AXI state machine   
   wire[2:0]    APB_next_state;                     // APB state machine   
   wire[2:0]    APB_present_state;                  // APB state machine  


bridge_stm stm(
	.ACLK	            (ACLK), 
    .ARESETn            (ARESETn),		
	.AWVALID	        (AWVALID),
	.WVALID	            (WVALID),
	.ARVALID	        (ARVALID),	
	
	.PSEL	            (PSEL),
	.PREADY	            (PREADY),
	.PSLVERR	        (PSLVERR),	
	
	.AXI_next_state	    (AXI_next_state),
	.AXI_present_state  (AXI_present_state),
	.APB_present_state  (APB_present_state),
	.APB_next_state	    (APB_next_state),
	
	.tout	            (tout),
	.SLVERR_sign	    (SLVERR_sign),
	.avalidend	        (avalidend),
	.dvalidend	        (dvalidend)
);

bridge_status status(
	.ACLK               (ACLK),
	.ARESETn            (ARESETn), 
	
	.AWVALID            (AWVALID),
	.WVALID	            (WVALID),
	.AWREADY	        (AWREADY), 
	.WREADY	            (WREADY),
	.BVALID	            (BVALID),
	.BRESP              (BRESP),
	.AWADDR             (AWADDR),
	.WDATA              (WDATA),
	
	.ARVALID	        (ARVALID), 	
	.ARREADY	        (ARREADY),
	.RVALID	            (RVALID),
	.RDATA	            (RDATA),
	.RRESP              (RRESP),	
	.ARADDR             (ARADDR),
	
	.PWRITE	            (PWRITE),
	.PSEL	            (PSEL),
	.PENABLE	        (PENABLE),
	.PWDATA	            (PWDATA),
	.PADDR              (PADDR),
    .PSLVERR            (PSLVERR),
	.PREADY             (PREADY),
	.PRDATA             (PRDATA),
	
	.APB_next_state     (APB_next_state),
	.AXI_next_state     (AXI_next_state),
	.avalidend	        (avalidend),
	.dvalidend	        (dvalidend),
    .x_valid            (x_valid),
    .tout               (tout),
	.SLVERR_sign        (SLVERR_sign)
);

bridge_decoder decoder(
    .ACLK               (ACLK),
	.ARESETn            (ARESETn),
    .AWADDR             (AWADDR),	
    .x_valid            (x_valid),
	.ARADDR             (ARADDR),
	.SLVERR_sign	    (SLVERR_sign)
);
  endmodule