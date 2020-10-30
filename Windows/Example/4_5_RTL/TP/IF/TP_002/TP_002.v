// write data from CPU into register timer1 = 8'h49, timer2 = 8'h9 => tout_10 = 10us and tout_100 = 100us
     rst_n = 1'b1;#(CYC*20) 
     WRITE_DATA(2'b00,8'h80); // start_flag=0 and cntclr_flag =1 => clear counter
     WRITE_DATA(2'b00,8'h1); // start_flag=1 => start counter
     WRITE_DATA(2'b01,8'h49);WRITE_DATA(2'b10,8'h9);
     READ_DATA(2'b00);     // checking read data in startstop register
     READ_DATA(2'b01);     // checking read data in timer1 register
     READ_DATA(2'b10);     // checking read data in timer2 register 
     #(CYC*350)