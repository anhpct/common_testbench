 /* ------------------------------------------------------------------------
日付　　： 2020/05/22
名前	: bridge_stm.v
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
module bridge_stm(
           ACLK,ARESETn,AWVALID,WVALID,ARVALID,PSEL,PREADY,PSLVERR,
	       AXI_next_state,AXI_present_state,APB_present_state,APB_next_state,
	       tout,SLVERR_sign,avalidend,dvalidend
);
   input                              ACLK;                    // バスクロック信号
   input                              ARESETn;                // リセット信号,LOWアクティブ
   input                              AWVALID;                //AXIバス AWADDRアドレスチャネルの値が有効であることを示す信号です。 
   input                              WVALID;                 //AXIバスライトデータの値が有効であることを示す信号です。 
   input                              ARVALID;                //AXIバス ARADDRアドレスチャネルの値が有効であることを示す信号です。 
   input                              PSEL; 
   input                              PREADY; 
   input                              PSLVERR; 
   input                              avalidend;              // address valid end flag
   input                              dvalidend;              // data valid end flag 
   input                              SLVERR_sign;   
   
// AXI state machine  
   output reg [2:0]                   AXI_present_state;      // APB state machine  
   output reg [2:0]                   AXI_next_state;         // APB state machine  
// APB state machine    
   output reg [2:0]                   APB_present_state;      // APB state machine  
   output reg [2:0]                   APB_next_state;         // APB state machine  
// タイムアウトと非搭載信号   
   output reg                         tout;                  //タイムアウト

   
   parameter UD             = 1;           // Unit delay
   parameter COUNTER        = 5;           // 5bits counter
   parameter COMP           = 9;           // compare value counter  
     
   
   reg [COUNTER-1:0]cnt;
   wire flag_cmp;
  
   assign flag_cmp = (cnt == COMP) ? 1 : 0;
//  timeout counter    
   always @(posedge ACLK or negedge ARESETn) begin
   if (!ARESETn)
     cnt <= #(UD)1'b0;
   else if (PREADY || flag_cmp )
     cnt <= #(UD)1'b0;	 
   else if (PSEL == 1'b1)
     cnt <= #(UD)cnt + 1'b1;
   else 
     cnt <= #(UD)cnt;
   end
   always @(posedge ACLK or negedge ARESETn) begin
   if (!ARESETn)
     tout <= #(UD)1'b0;
   else
     tout <= #(UD)(flag_cmp == 1'b1) ? 1 : 0;
   end
   
 always @(posedge ACLK or negedge ARESETn) 
  begin
    if(!ARESETn) 
	  begin
         AXI_present_state <= #(UD)`AXI_IDLE;
	     APB_present_state <= #(UD)`APB_IDLE; 
	  end
    else 
	  begin
         AXI_present_state <= #(UD)AXI_next_state;
         APB_present_state <= #(UD)APB_next_state;	
	  end
  end		
// 　　　AXI slaveステータスは状態遷移に従って変更される。 
  always @(AXI_present_state or AWVALID or WVALID or ARVALID or avalidend or dvalidend or PREADY or SLVERR_sign or tout or PSLVERR)  
   begin
    AXI_next_state = `AXI_IDLE;
    case(AXI_present_state)
   `AXI_IDLE:        //1
      begin
      if (ARVALID == 1'b1) 
        AXI_next_state = `SEND_RADDR;
      else if (!ARVALID && AWVALID || WVALID)
        AXI_next_state = `ADDR_WRITE_DATA;   
      else 
        AXI_next_state = `AXI_IDLE;
   end
   `SEND_RADDR:      //2
      begin 
//      if(ARVALID == 1'b1 && SLVERR_sign == 1'b1)
      if(SLVERR_sign == 1'b1)
	    AXI_next_state = `RDATA_TRANSFER;
      else
	    AXI_next_state = `RDATA_WAIT;
   end
  `RDATA_WAIT:      //3
   begin
      if (PREADY || tout || PSLVERR)
	    AXI_next_state = `RDATA_TRANSFER;
      else  
	    AXI_next_state = `RDATA_WAIT;
      end
   `RDATA_TRANSFER:  //4
    begin                                          
	    AXI_next_state = `AXI_IDLE;
    end	 
   `ADDR_WRITE_DATA: //5
    begin
	  if (avalidend && SLVERR_sign)
        AXI_next_state = `WRITE_END;	   
	  else if ((AWVALID & WVALID) || (avalidend & dvalidend ))  
 	    AXI_next_state = `WDATA_WAIT;
	  else 
	    AXI_next_state = `ADDR_WRITE_DATA;
    end
   `WDATA_WAIT:     //6
    begin  
      if (PREADY || tout || PSLVERR )
	    AXI_next_state = `WRITE_END; 
	  else 
	    AXI_next_state = `WDATA_WAIT; 
    end	 
   `WRITE_END:      //7
    begin 
	    AXI_next_state = `AXI_IDLE; 
    end 
  endcase
 end
 
//   APB masterステータスは状態遷移に従って変更される。  
  always @(APB_present_state or AWVALID or WVALID or ARVALID or PREADY or avalidend or dvalidend or SLVERR_sign or tout) 
   begin
     APB_next_state = `APB_IDLE;
   case(APB_present_state)
   `APB_IDLE:     //1
    begin
     if(SLVERR_sign == 1'b0)
	   if (ARVALID == 1'b1)
        APB_next_state = `APB_RSETUP;
	   else if ((ARVALID == 1'b0) && ((AWVALID & WVALID) || (avalidend & WVALID ) || (dvalidend & AWVALID)))
        APB_next_state = `APB_WSETUP; 
	   else 
        APB_next_state = `APB_IDLE;
	 else
	   APB_next_state = `APB_IDLE;
   end
   `APB_RSETUP:   //2
    begin
        APB_next_state = `APB_RACCESS; 
    end
   `APB_RACCESS:  //3
    begin
      if (PREADY || tout || PSLVERR)    
        APB_next_state = `APB_IDLE;    
	  else
	    APB_next_state = `APB_RACCESS;   
    end
   `APB_WSETUP:  //4  
    begin
        APB_next_state = `APB_WACCESS; 
    end
   `APB_WACCESS: //5 
    begin
      if (PREADY || tout || PSLVERR ) 
        APB_next_state = `APB_IDLE;       
	  else
	    APB_next_state = `APB_WACCESS;  
      end	 
   endcase
 end  

endmodule