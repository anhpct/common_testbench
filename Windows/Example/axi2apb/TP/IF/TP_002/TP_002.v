
	 ARESETn = 1'b0; #(CYC*1.5)
	 ARESETn = 1'b1; #1
	 
	 WRITE_WAIT_TRANSFER(32'hA0011014,32'h00001248); #(CYC*1)                             //READ wait transfer    : ADDRESS 32'hA0011014 & DATA 32'h00001248
	 READ_DATA_FAIL(32'hA0011018,32'hB0011000); #(CYC*1)                                  //READ  [timeout : ADDRESS 32'hA0011018] [SLVERR : ADDRESS32'hB0011000] 
	 WRITE_DATA_FAIL(32'hA001101C,32'h0000124C,32'hC0011000); #(CYC*1)    	              //WRITE [timeout : ADDRESS 32'hA001101C & DATA 32'h0000124C] [SLVERR : ADDRESS 32'hC0011000]
	 READ_DATA(32'hA0021000,32'h00001280); #(CYC*1)                                       //READ  transfer success: ADDRESS 32'hA0021000 & DATA 32'h00001280
	 WRITE_DATA(32'hC0021004,32'h00001284); #(CYC*6)                                      //WRITE transfer fail: ADDRESS 32'hA0021004 & DATA 32'h00001284	
	 	 
	 ARESETn = 1'b0; #(CYC*2)