
	 ARESETn = 1'b0; #(CYC*1.5)
	 ARESETn = 1'b1; #1

     READ_DATA(32'hA0011000,32'h0000123A);
	 READ_DATA(32'hA0011000,32'h0000123A); #(CYC*1)                                       //READ  transfer success: ADDRESS 32'hA0011000 & DATA 32'h0000123A	 
	 WRITE_DATA(32'hA0011004,32'h0000123B); #(CYC*1)                                      //WRITE transfer success: ADDRESS 32'hA0011004 & DATA 32'h0000123B
	 MIX_TRANSFER(32'hA0011008,32'h0000123C,32'hA001100C,32'h00001240); #(CYC*1)          //READ priority         : ADDRESS 32'hA0011008 & DATA 32'h0000123C
	 READ_WAIT_TRANSFER(32'hA0011010,32'h00001244); #(CYC*1)                              //READ wait transfer    : ADDRESS 32'hA0011010 & DATA 32'h00001244

	 ARESETn = 1'b0; #(CYC*2)