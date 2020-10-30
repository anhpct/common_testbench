
//クロック切替　tout_100出力は3回行う when tout_100 = 100us
sel = 1'b1;
WRITE_DATA(2'b00,8'h80);#(CYC*10)                            // start_flag=0 and cntclr_flag =0 => clear counter
WRITE_DATA(2'b00,8'h1);#(CYC*500)                            // start_flag=1 => start counter
READ_DATA(2'b00);#(CYC*1)     // checking read data in startstop register
READ_DATA(2'b01);#(CYC*1)     // checking read data in timer1 register
READ_DATA(2'b10);#(CYC*1)     // checking read data in timer2 register  
sel = 1'b0; #(CYC*150) 

//if press reset, circuit become default stage: startstop = 8'h99,timer1 = 8'h99, timer2 = 8'h99
rst_n = 1'b0;#(CYC*20)  

// write data from CPU into register timer1 = 8'h49, timer2 = 8'h4 => tout_10 = 10us and tout_100 = 50us
rst_n = 1'b1;
WRITE_DATA(2'b00,8'h01);WRITE_DATA(2'b01,8'h49);WRITE_DATA(2'b10,8'h4);#(CYC*150)  
READ_DATA(2'b00);#(CYC*1)     // checking read data in startstop register
READ_DATA(2'b01);#(CYC*1)     // checking read data in timer1 register
READ_DATA(2'b10);#(CYC*1)     // checking read data in timer2 register

//クロック切替　tout_100出力は3回行う when tout_100 = 50us
sel = 1'b1;
WRITE_DATA(2'b00,8'h80);#(CYC*10)                            // start_flag=0 and cntclr_flag =0 => clear counter
WRITE_DATA(2'b00,8'h1);#(CYC*200)                            // start_flag=1 => start counter
READ_DATA(2'b00);#(CYC*1)     // checking read data in startstop register
READ_DATA(2'b01);#(CYC*1)     // checking read data in timer1 register
READ_DATA(2'b10);#(CYC*1)     // checking read data in timer2 register  

sel = 1'b0;
WRITE_DATA(2'b00,8'h81);#(CYC*50)
WRITE_DATA(2'b00,8'h01);
#(CYC*150) 