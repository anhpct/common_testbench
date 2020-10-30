/* ------------------------------------------------------------------------
日付　　： 2020/05/28
名前	: bridge_status.v
機能	: AXI-Lite to APB bridge
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
module bridge_status(
           ACLK,ARESETn,AWVALID,WVALID,AWREADY, WREADY,BVALID,ARVALID,ARREADY,RVALID,RDATA,BRESP,RRESP,
           PWRITE,PSEL,PENABLE,PWDATA,PADDR,PSLVERR,AXI_next_state,APB_next_state,
	       avalidend,dvalidend,x_valid,tout,SLVERR_sign,AWADDR,ARADDR,WDATA,PREADY,PRDATA
);
   output reg                         AWREADY;       //AXIバス スレーブがライトアドレスを受信していることを示す信号です。
   output reg                         WREADY;        //AXIバス スレーブがライトデータを受信していることを示す信号です。  
   output reg                         BVALID;        //AXIバス スレーブのライト応答が有効であることを示す信号です。
   output reg                         ARREADY;       //AXIバス スレーブがリードアドレスを受信していることを示す信号です。
   output reg [`AXI4_RDATA_WIDTH-1:0] RDATA;         //AXIバス スレーブからのリードデータ信号です。
   output reg                         RVALID;        //AXIバス スレーブからのリード応答が有効であることを示す信号です。
   output reg [1:0]                   BRESP;         //AXIバス スレーブのライト応答信号です。	
   output reg [1:0]                   RRESP;         //AXIバス スレーブからのリード応答信号です。  
   
   output reg                         PWRITE;        //APBアクセス信号です。"1"のときはライト、"0"のときはリードです。
   output reg                         PSEL;          //APBバスセレクト信号です。本セルはIOブロックへのアクセスを示します。
   output reg                         PENABLE;       //APB バス転送の2 番目以降のサイクルであることを示します。
   output reg [`AXI4_WDATA_WIDTH-1:0] PWDATA;        //APBライトデータです。
   output reg [`AXI4_ADDR_WIDTH/2-1:0]PADDR;         //APBアドレス信号です。
   
   output reg                         avalidend;     //write address valid end flag
   output reg                         dvalidend;     //write data valid end flag
   output reg                         x_valid;       //read address valid end flag 
   
   input                              ACLK;
   input                              ARESETn;
   input[`AXI4_ADDR_WIDTH-1:0]        AWADDR;        //AXIバスライトアドレス信号です。
   input[`AXI4_ADDR_WIDTH-1:0]        ARADDR;        //AXIバスリードアドレス信号です。
   input[`AXI4_WDATA_WIDTH-1:0]       WDATA;         //AXIバスライトデータ信号です。  
   input                              ARVALID;       //AXIバス ARADDRアドレスチャネルの値が有効であることを示す信号です。
   input                              AWVALID; 
   input                              WVALID; 
   
   input                              PREADY;        //APBレディ信号です。   
   input                              PSLVERR;
   input[`AXI4_RDATA_WIDTH-1:0]       PRDATA;        //APBリードデータです

   input                              tout; 
   input                              SLVERR_sign;   //非搭載の信号
   input [2:0]                        AXI_next_state;    
   input [2:0]                        APB_next_state;      
 
   wire [15:0]                        AW_LSB; 
   wire [15:0]                        AR_LSB;   
   reg  [15:0]                        w_addr;
   reg  [`AXI4_WDATA_WIDTH-1:0]       w_data; 

   assign AW_LSB =  AWADDR[15:0];  
   assign AR_LSB =  ARADDR[15:0];     
   
   parameter UD             = 1;           // Unit delay
//   　AXIスレーブステータス状態
 always @(posedge ACLK or negedge ARESETn) begin
   if (ARESETn == 1'b0) 
	  begin
        AWREADY <= #(UD)1'b0;WREADY <= #(UD)1'b0;BVALID <= #(UD)1'b0;
		ARREADY <= #(UD)1'b0;RVALID <= #(UD)1'b0;RDATA <= #(UD)32'h00000000;
		avalidend <= #(UD)1'b0; dvalidend <= #(UD)1'b0; w_data <= #(UD)32'h00000000;
		w_addr <= #(UD)16'h0000;x_valid <= #(UD)1'b0; 
	  end
   case(AXI_next_state)
   `AXI_IDLE:         //1　　　　  　// Default state
      begin
	    AWREADY <= #(UD)1'b0;WREADY <= #(UD)1'b0;BVALID <= #(UD)1'b0;
		ARREADY <= #(UD)1'b0;RVALID <= #(UD)1'b0;RDATA <= #(UD)32'h00000000;
		avalidend <= #(UD)1'b0;dvalidend <= #(UD)1'b0; w_data <= #(UD)32'h00000000;
		w_addr <= #(UD)16'h0000;x_valid <= #(UD)1'b0;
      end
   `SEND_RADDR:        //2      // Ready for receive address
      begin
 	    ARREADY <= #(UD)1'b1; RVALID <= #(UD)1'b0; end
   `RDATA_WAIT:        //3      // Wait pready = 1 of APB
      begin
	    ARREADY <= #(UD)1'b0; RVALID <= #(UD)1'b0; 
      end
   `RDATA_TRANSFER:    //4      // Finished read transfer 
      begin
        ARREADY <= #(UD)1'b0; RVALID <= #(UD)1'b1; x_valid <= #(UD)1'b1;
      end
   `ADDR_WRITE_DATA:   //5
      begin
      if (AWVALID == 1'b1) begin 
		AWREADY <= #(UD)1'b1; avalidend <= #(UD)1'b1; w_addr <= #(UD) AW_LSB; end
	  if (avalidend) begin  
	    AWREADY <= #(UD)1'b0; avalidend <= #(UD)1'b1; end 
	  if (WDATA) begin 
	    WREADY <= #(UD)1'b1; dvalidend <= #(UD)1'b1; w_data <= #(UD)WDATA; end
	  if (dvalidend) begin 
	    WREADY <= #(UD)1'b0;  dvalidend <= #(UD)1'b1; end
	  end  
   `WDATA_WAIT:        //6      // Wait to pready of APB
      begin
        AWREADY <= #(UD)1'b0; WREADY <= #(UD)1'b0; BVALID <= #(UD)1'b0;
      end
   `WRITE_END:                  // Finished write transfer
      begin
        AWREADY <= #(UD)1'b0; WREADY <= #(UD)1'b0; BVALID <= #(UD)1'b1;x_valid <= #(UD)1'b1;
      end
   endcase
  end
// APB master state  
 always @(posedge ACLK or negedge ARESETn) begin  
   if (ARESETn == 1'b0) 
      begin
        PSEL <= #(UD)1'b0;PENABLE <= #(UD)1'b0;PWRITE <= #(UD) 1'b0;
	    PWDATA <= #(UD)32'h00000000; PADDR <= #(UD)16'h0000; 
      end
//  case(APB_present_state)
  case(APB_next_state)
  `APB_IDLE:       //1         // Default state       
      begin
        PSEL <= #(UD)1'b0;PENABLE <= #(UD)1'b0;//PWRITE <= #(UD)1'b0; 
	    PWDATA <= #(UD)32'h00000000;PADDR <= #(UD)16'h0000;	 
      end
  `APB_RSETUP:     //2         // Read transfer
      begin
        PSEL <= #(UD)1'b1; PENABLE <= #(UD)1'b0; PWRITE <= #(UD)1'b0;        // read enable
      end
  `APB_RACCESS:	   //3 
      begin
        PSEL <= #(UD)1'b1; PENABLE <= #(UD)1'b1; PWRITE <= #(UD)1'b0;
      end
  `APB_WSETUP:     //4         // Write transfer
      begin
        PSEL <= #(UD)1'b1; PENABLE <= #(UD)1'b0; PWRITE <= #(UD)1'b1;        // write enable
      end
  `APB_WACCESS:    //5
      begin
        PSEL <= #(UD)1'b1; PENABLE <= #(UD)1'b1; PWRITE <= #(UD)1'b1;
      end	 
  endcase
 end

  //  Write transfer send address and data from AXI to APB
 always @(posedge ACLK) 
   begin
	if((AXI_next_state == `ADDR_WRITE_DATA) && (SLVERR_sign == 1'b0)) begin
//	if(AXI_next_state == `ADDR_WRITE_DATA) begin
	   if(AWVALID & WVALID) 
	    begin
        PADDR  <= #(UD) AW_LSB;                                              // 16bits LSB write address
	    PWDATA <= #(UD) WDATA;                                               // 32bits data
	    end
	   else if (avalidend & WVALID ) 
	    begin
        PADDR  <= #(UD) w_addr;                                              // 16bits LSB write address
	    PWDATA <= #(UD) WDATA;                                               // 32bits data
	    end
	   else if(dvalidend & AWVALID)
	    begin
        PADDR  <= #(UD) AW_LSB;                                              // 16bits LSB write address
	    PWDATA <= #(UD) w_data;                                              // 32bits data
	    end		
	  end
    end
//  Found error in write transfer and feedback to AXI
 always @(posedge ACLK or negedge ARESETn) 
   begin
      if (!ARESETn)
	    BRESP <= #(UD) `OKAY;
      else if ((AWVALID == 1'b1) && (SLVERR_sign == 1'b1))                    // アドレバス空間非搭載の理由
	    BRESP <= #(UD) `SLVERR;
      else if ((AXI_next_state == `WRITE_END ) && (tout || PSLVERR))          // タイムアウトとスレーブエラーの理由
	    BRESP <= #(UD) `SLVERR; 
      else
	    BRESP <= #(UD) `OKAY;
   end 
   
//  Read transfer send address from AXI to APB
 always @(posedge ACLK) 
   begin
	  if ((AXI_next_state == `SEND_RADDR) && (SLVERR_sign == 1'b0))
        PADDR <= #(UD) AR_LSB;                                                // 16bits LSB read address
      end
//  Receive data from APB
 always @(posedge ACLK) 
   begin
      if((AXI_next_state == `RDATA_TRANSFER) && (PREADY == 1'b1)) 
	    RDATA <= #(UD) PRDATA;                                                // 32bits data
   end
//  Found error in read transfer and feedback to AXI
 always @ (posedge ACLK or negedge ARESETn) 
   begin
      if (!ARESETn)
	    RRESP <= #(UD) `OKAY;
      //else if(ARVALID == 1'b1 && SLVERR_sign == 1'b1)                         // アドレバス空間非搭載の理由
	  else if(AXI_next_state == `RDATA_TRANSFER && SLVERR_sign == 1'b1)   
	    RRESP <= #(UD) `SLVERR;
      else if ((AXI_next_state == `RDATA_TRANSFER ) && (tout || PSLVERR))     // タイムアウトとスレーブエラーの理由
	    RRESP <= #(UD) `SLVERR;
      else 
	    RRESP <= #(UD) `OKAY; 
   end   
endmodule