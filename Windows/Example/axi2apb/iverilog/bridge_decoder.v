/* ------------------------------------------------------------------------
日付　　： 2020/05/28
名前	: bridge_decoder.v
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
module bridge_decoder (
           ACLK,ARESETn,AWADDR,ARADDR,x_valid,SLVERR_sign
);
   input                              ACLK; 
   input                              ARESETn; 
   input                              x_valid;       //read address valid end flag 
   input[`AXI4_ADDR_WIDTH-1:0]        AWADDR;        //AXIバスライトアドレス信号です。
   input[`AXI4_ADDR_WIDTH-1:0]        ARADDR;        //AXIバスリードアドレス信号です。  
   output wire                        SLVERR_sign;   //非搭載の信号
   
   
   wire [15:0]AW_MSB; 
   wire [15:0]AR_MSB; 
      //  受信アドレスを16bits分ける 
   assign AW_MSB =  AWADDR[`AXI4_ADDR_WIDTH-1:16];   
   assign AR_MSB =  ARADDR[`AXI4_ADDR_WIDTH-1:16];   
//   アドレス空間のデコー：　非搭載したら SLVERR_sign = 1    

   wire [3:0] psel_result;
   wire pselx;
   reg sign;
   
   //  wire [3:0] r_pselx,w_pselx;   
   // assign r_pselx = psel_select(AR_MSB);                                 //　Select psel for read transfer
   // assign w_pselx = psel_select(AW_MSB);                                 //　Select psel for write transfer
   
   assign  psel_result = psel_select(AR_MSB) | psel_select(AW_MSB);  
   assign pselx = ((psel_result == 4'b0000) && ((ARADDR != 0) || (AWADDR != 0))) ? 1 : 0 ;   //非搭載のとき pselx = 1以外は = 0
   
  always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)
	  sign <= 1'b0;
	else if(x_valid)
	  sign <= 1'b0;
    else if (pselx)
      sign <= 1'b1;	 
    end
  
  assign SLVERR_sign = pselx || sign;	                                     // 非搭載のとき　x_valid信号までハイを保持します。
	
   function [3:0]psel_select;
   input [15:0]address;
     begin
	   case(address)
	    // 16'hA000: psel_select = 4'b0001;    // psel_select = 1の結果 psel0 が選ばれる
	    16'hA001: psel_select = 4'b0010;   // psel_select = 2の結果 psel1 が選ばれる
	    // 16'hA002: psel_select = 4'b0100;    // psel_select = 4の結果 psel2 が選ばれる
        // 16'hA003: psel_select = 4'b1000;    // psel_select = 8の結果 psel3 が選ばれる
	   default    psel_select = 4'b0000;   // psel_select = 8の結果 アドレバス空間非搭載　SLVERR_sign = 1
	   endcase
	end
   endfunction
  endmodule
  