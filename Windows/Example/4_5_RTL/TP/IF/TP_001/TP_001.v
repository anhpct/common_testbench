// default stage: startstop = 8'h99,timer1 = 8'h99, timer2 = 8'h99
     rst_n = 1'b0;
     READ_DATA(2'b00);     // checking read data in startstop register
     READ_DATA(2'b01);    // checking read data in timer1 register
     READ_DATA(2'b10);    // checking read data in timer2 register 
     WRITE_DATA(2'b00,8'h80);WRITE_DATA(2'b00,8'h1);WRITE_DATA(2'b01,8'h49);WRITE_DATA(2'b10,8'h9);#(CYC*20) 