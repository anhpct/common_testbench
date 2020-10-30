/* ------------------------------------------------------------------------
日付　　： 2020/05/22
名前	: axi2apb_tb.v
機能	: AXI-Lite to APB bridge testbench
設計者	：アイン
確認者	：花盛
Icarus cmd: 




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
module axi2apb_tb;
   parameter UD                 = 1;          // Unit delay
  
   reg                          ACLK;         // バスクロック信号
   reg                          ARESETn;      // リセット信号,LOWアクティブ
 // AXI-Lite write address bus
   reg[`AXI4_ADDR_WIDTH-1:0]    AWADDR;       //AXIバスライトアドレス信号です。
   reg                          AWVALID;      //AXIバス AWADDRアドレスチャネルの値が有効であることを示す信号です。
   reg [2:0]                    AWPROT;       //AXIバスライトアクセスの保護レベルを示す信号です。
   wire                         AWREADY;      //AXIバス スレーブがライトアドレスを受信していることを示す信号です。
  // AXI-Lite write data bus and write response bus
   reg[`AXI4_WDATA_WIDTH-1:0]   WDATA;        //AXIバスライトデータ信号です。
   reg                          WVALID;       //AXIバスライトデータの値が有効であることを示す信号です。
   wire [1:0]                   BRESP;        //AXIバス スレーブのライト応答信号です。	
   wire                         BVALID;       //AXIバス スレーブのライト応答が有効であることを示す信号です。
   reg                          BREADY;       //AXIバスマスタが応答受信可能状態であることを示す信号です。
   wire                         WREADY;       //AXIバス スレーブがライトデータを受信していることを示す信号です。
  // AXI-Lite read address bus
   reg[`AXI4_ADDR_WIDTH-1:0]    ARADDR;       //AXIバスリードアドレス信号です。
   reg                          ARVALID;      //AXIバス ARADDRアドレスチャネルの値が有効であることを示す信号です。
   reg [2:0]                    ARPROT;       //AXIバスリードアクセスの保護レベルを示す信号です。
   wire                         ARREADY;      //AXIバス スレーブがリードアドレスを受信していることを示す信号です。
  // AXI-Lite read data bus   
   wire[`AXI4_RDATA_WIDTH-1:0]  RDATA;        //AXIバス スレーブからのリードデータ信号です。
   wire                         RVALID;       //AXIバス スレーブからのリード応答が有効であることを示す信号です。
   wire [1:0]                   RRESP;        //AXIバス スレーブからのリード応答信号です。
   reg                          RREADY;       //AXIバス マスタがリードデータ受信可能状態であることを示す信号です。

// APB master interface 入出力
   reg                          pclk;         //APBクロック信号
   reg                          prst_n;       //APBシステムリセット信号です。LOWアクティブです。
   reg                          pready;       //APBレディ信号です。
   reg                          pslverr;      //APB転送エラーが発生したことをマスタに伝える信号です。
   reg [`AXI4_RDATA_WIDTH-1:0]  prdata;       //APBリードデータです。
   wire[`AXI4_ADDR_WIDTH/2-1:0] paddr;        //APBアドレス信号です。
   wire                         pwrite;       //APBアクセス信号です。"1"のときはライト、"0"のときはリードです。
   wire                         psel;         //APBバスセレクト信号です。本セルはIOブロックへのアクセスを示します。
   wire                         penable;      //APB バス転送の2 番目以降のサイクルであることを示します。
   wire[`AXI4_WDATA_WIDTH-1:0]  pwdata;       //APBライトデータです。

   
   parameter CYC = 100;                       // 10MHZクロックを作成、 クロック周期： 1us
 /* ------DUT Instantiation------ */  
 axi2apb_top tb(
     .ACLK      (ACLK),
	 .ARESETn   (ARESETn),
	 .AWADDR    (AWADDR),
	 .AWVALID   (AWVALID),
	 .AWREADY   (AWREADY),
	 .AWPROT    (AWPROT),
	 .WDATA     (WDATA),
	 .WVALID    (WVALID),
	 .WREADY    (WREADY),
	 .BRESP     (BRESP),
	 .BVALID    (BVALID),
	 .BREADY    (BREADY),
	 .ARADDR    (ARADDR),
	 .ARVALID   (ARVALID),
	 .ARREADY   (ARREADY),
	 .ARPROT    (ARPROT),
	 .RDATA     (RDATA),
	 .RRESP     (RRESP),
	 .RVALID    (RVALID),
	 .RREADY    (RREADY),
	 .PCLK      (pclk),
	 .PRST_n    (prst_n),
	 .PADDR     (paddr),
	 .PWRITE    (pwrite),
	 .PSEL      (psel),
	 .PENABLE   (penable),
	 .PWDATA    (pwdata),
	 .PRDATA    (prdata),
	 .PREADY    (pready),
	 .PSLVERR   (pslverr)
 );
/* -------初期値セット--------- */
 initial begin
     ACLK   = 1'b0; ARESETn = 1'b0;pclk   = 1'b0; prst_n  = 1'b0;
	 AWADDR = 32'h0;AWVALID = 1'b0;AWPROT = 3'b000;
	 WDATA  = 32'h0;WVALID  = 1'b0;
	 BREADY = 1'b0;
	 ARADDR = 32'h0;ARVALID = 1'b0;ARPROT = 3'b000;RREADY = 1'b0;
	 pready = 1'b0; pslverr = 1'b0;prdata = 32'h00000000;
   end

/* -------10MHZクロックを作成-------- */
 initial begin
     forever #(CYC/2) 
	 ACLK =  ! ACLK;
   end   

  /* READ SUCCESS TASK   */

 task READ_DATA; 
 input [31:0]read_addr;
 input [31:0]pr_data;
 
   begin  
     $display("----- Read Access READ_DATA task -----");  
	 
     ARVALID = 1'b1;
	 ARADDR  = read_addr;
	 #(CYC*2)
	 ARVALID = 1'b0;
	 ARADDR  = 32'h00000000;  
     RREADY  = 1'b1;		 
     pready  = 1'b1;
	 prdata  = pr_data; 
	 #(CYC*1)
	 pready  = 1'b0;
	 prdata = 32'h00000000;
     #(CYC*1)
	 RREADY  = 1'b0;
   end
 endtask
 /* WRITE SUCCESS TASK   */
 task WRITE_DATA; 
 input [31:0]write_addr;
 input [31:0]write_data;
   begin
      $display("----- Read Access WRITE_DATA task -----");  
	  
	 WVALID  = 1'b1; 
	 WDATA   = write_data; 
	 AWVALID = 1'b1;
	 AWADDR  = write_addr; 
	 #(CYC*2)
	 
	 AWVALID = 1'b0;
	 AWADDR  = 32'h00000000; 
	 
	 WVALID  = 1'b0;
	 WDATA   = 32'h00000000;   	 

     BREADY  = 1'b1;	 
     pready  = 1'b1; 
	 #(CYC*1)
	 pready  = 1'b0; 
	 #(CYC*1)
	 BREADY  = 1'b0;
   end
 endtask
 /* READ priority when READ and WRITE in same time */
  task MIX_TRANSFER;
input [31:0]read_addr;
input [31:0]pr_data;
input [31:0]write_addr;
input [31:0]write_data;
   begin
     $display("----- Read Access MIX_TRANSFER task -----");  
     ARVALID = 1'b1;
	 ARADDR  = read_addr;
	 AWVALID = 1'b1;
	 AWADDR  = write_addr; 
	 WVALID  = 1'b1;
	 WDATA   = write_data; 
	 #(CYC*2)
	 ARVALID = 1'b0;
	 ARADDR  = 1'b0;
	 
	 AWVALID = 1'b0;
	 AWADDR  = 1'b0; 
	 WVALID  = 1'b0;
	 WDATA   = 1'b0;
     BREADY  = 1'b1; 
     RREADY  = 1'b1;	//#1	
	 
     pready  = 1'b1;
	 prdata  = pr_data; 
	 #(CYC*1)
	 pready  = 1'b0;  
     prdata = 32'h00000000;	 
	 #(CYC*1)
	 RREADY  = 1'b0;
	 BREADY  = 1'b0;
   end
 endtask
 /* READ wait transfer  */
  task READ_WAIT_TRANSFER;
  input [31:0]read_addr;
  input [31:0]pr_data;
   begin
     $display("----- Read Access READ_WAIT_TRANSFER task -----");  
	 
     ARVALID = 1'b1;
	 ARADDR  = read_addr; 
	 #(CYC*2)
	 ARVALID = 1'b0;
	 ARADDR  = 1'b0; 
     RREADY  = 1'b1;    
	 #(CYC*5)        // wait transfer in 5 cycles
	 
     pready  = 1'b1;
	 prdata  = pr_data; 
	 #(CYC*1)
	 pready  = 1'b0;   
     prdata = 32'h00000000;	 
	 #(CYC*1)
	 RREADY  = 1'b0;
   end
 endtask
 /* WRITE wait transfer  */
 task WRITE_WAIT_TRANSFER; 
 input [31:0]write_addr;
 input [31:0]write_data;
   begin
     $display("----- Read Access WRITE_WAIT_TRANSFER task -----");  
	 
     AWVALID = 1'b1;
	 AWADDR  = write_addr; 
	 WVALID  = 1'b1;
	 WDATA   = write_data; 
	 #(CYC*2)
	 AWVALID = 1'b0;
	 AWADDR  = 1'b0; 
	 WVALID  = 1'b0;
	 WDATA   = 1'b0;
     BREADY  = 1'b1; 
	 #(CYC*5)      // wait transfer in 5 cycles
	 
     pready  = 1'b1; 
	 #(CYC*1)
	 pready  = 1'b0; 
	 #(CYC*1)
	 BREADY  = 1'b0;
   end
 endtask
 /* READ TIMEOUT and SLVERR FAIL TASK    */
  task READ_DATA_FAIL; 
  input [31:0]read_addr_tout;
  input [31:0]read_addr_slverr;
   begin
     $display("----- Read Access READ_DATA_FAIL task -----");  
	 
     ARVALID = 1'b1;
	 ARADDR  = read_addr_tout; 
	 #(CYC*2)
	 
	 ARVALID = 1'b0;
	 ARADDR  = 1'b0; 
     RREADY  = 1'b1;  
	 #(CYC*15)                            // wait 15 cycles -> timeout is asserted
	 RREADY  = 1'b0;  
	 #(CYC*1)
	 
	 ARVALID = 1'b1;
	 ARADDR  = read_addr_slverr; 
	 #(CYC*2)	              // set ARADDR = B0011000 it have MSL = B001 # A001 so SLVERR_sign is asserted
	 ARVALID = 1'b0;
	 ARADDR  = 1'b0;
   end
 endtask
 /* WRITE TIMEOUT and SLVERR FAIL TASK    */
  task WRITE_DATA_FAIL; 
  input [31:0]write_addr_tout;
  input [31:0]write_data_tout;
  input [31:0]write_addr_slverr;
   begin
     $display("----- Read Access WRITE_DATA_FAIL task -----");  
	 
     AWVALID = 1'b1;
	 AWADDR  = write_addr_tout; 
	 WVALID  = 1'b1;
	 WDATA   = write_data_tout; 
	 #(CYC*2)
	 
	 AWVALID = 1'b0;
	 AWADDR  = 1'b0; 
	 WVALID  = 1'b0;
	 WDATA   = 1'b0;
     BREADY  = 1'b1; 
	 #(CYC*15)                            // wait 15 cycles -> timeout is asserted
	 BREADY  = 1'b0; 
	 #(CYC*1)

	 AWVALID = 1'b1;
	 AWADDR  = write_addr_slverr; 
	 #(CYC*2)	              // set AWADDR = C0011000 it have MSL = C001 # A001 so SLVERR_sign is asserted
	 AWVALID = 1'b0;
	 AWADDR  = 1'b0;
	 BREADY  = 1'b0;
   end
 endtask
   
 /*   -----------------------TEST PATTERN------------------------ */
initial begin
// insert on

$finish;     // Simulation STOP条件
end
endmodule
		
		 
