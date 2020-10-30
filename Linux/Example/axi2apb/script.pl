#---------------------------------------------------------------------------------------------------
#hierarchy folder
# TP________IF       : TP_001, TP_002, TP_00x...
#           |_____FUNC: TP_100, TP_101, TP_10x...
#           |_____ILL     : TP_200, TP_201, TP_20x...
#---------------------------------------------------------------------------------------------------

#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use POSIX qw(strftime);
use File::Find;
use File::Copy;
use Tie::File;
use Term::ANSIColor qw(:constants);
use Cwd qw(cwd);


# ********************************************* NEED TO CHANGE *******************************************#
# ------- Before running make sure that you already changed your testbench and top module name ------------#
# ------- Declare the testbench and top module name here!
my $tb_name    = "axi2apb_tb.v";                                                    #testbench name                                               
my $top_module = "axi2apb_tb";                                                      #top module in testbench





# ******************************************** DO NOT CHANGE ANYTHING BELOW ******************************#
# -------Ref: https://www.tutorialspoint.com/perl/perl_date_time.htm -------------------------------------#
# -------Print localtime
my $wTime = localtime();
print "Local date and time $wTime\n";

# -------All flag and counter write here!
my $err_cnt = 0;                                                                     #error count
my $insert_flag = 0;                                                                 #'// insert on' flag
my $count = 0;                                                                       #testpattern counter 

# ------- Declare covered tool here!
my $merge_name = "total_cov";
my @data_files = ();

# ------- Body code here!
my $dir = cwd;
my @tp_list = ();
open(my $fh, "<", "tp_list.txt") or die "Failed to open file: $!\n";       #read data in tp_list.txt file
    while(my $line = <$fh>) { 
       chomp $line; 
    if (substr($line,0,1) ne "#" ) {                                                 #symbol '#' skip line
	   push @tp_list, $line;} }
close $fh;
my $name;
foreach $name (@tp_list){                                                            #reach one by one from list
#--------Ref: https://www.geeksforgeeks.org/perl-removing-leading-and-trailing-white-spaces-trim/ ---------#
#--------Applying left trim to $name 
$name=~ s/^\s+//; 
print GREEN, "Run: $name\n", RESET;
my @files = ();                                                                      #create @files array to save all test pattern dir

#--------Ref: http://koikikukan.com/archives/2013/01/21-003333.php ----------------------------------------#
#--------Get file name from path in Perl
if (basename($name) eq "*"){                                                         #running all file in folder if '*' symbol found
    print GREEN,"Run all files in $name folder\n",RESET; 
	substr($name, -1, 1, "");
    my $sub_dir = join '', $dir, '/TP/',$name;                                       #print "make new dir: $dir\n";
#--------Ref: https://www.theunixschool.com/2014/09/perl-find-files-using-filefind.html -------------------#
#--------Find command
      find(sub {                                                                     #search test pattern file in the entire TP/ path
           push @files,$File::Find::name if (-f $File::Find::name and /.v$/);        #put all results into @files array
      }, $sub_dir);
   }
else {
	  my $tp_name = basename($name);                                                 #get test pattern name 
      find(sub {                                                                     #search test pattern file in the entire DIR path                
           push @files,$File::Find::name if (-f $File::Find::name and /$tp_name$/);  #put all results into @files array
      }, $dir);
   }
   
    $count = scalar (@files);                                                        #counts the number of elements in the @file
      if  ($count == 0){                                                             #
		  $err_cnt++;
	      print RED, "Error: Could not find the $name file\n", RESET;
		  print "----------------------------------------------------------------------------\n";}
      else {
		foreach my $getpath (@files){
		  print "From: $getpath\n";                                                  #where's file running
		  $name = basename($getpath);                                                #find and replace ending words to create new testbench file	  	 
          $name =~ s/.v/_tb.v/;		                                                 #find and replace ending words to create new testbench file
          copy($tb_name,$name) or die "copy failed: $!";                             #copy origin file and run on temporary file	  
		  open my $info, $getpath or die  "Could not find $getpath: $!";             #open test pattern
	  
#--------Ref: https://stackoverflow.com/questions/4732937/how-do-i-read-a-file-line-by-line-while-modifying-lines-as-needed -#	  		  
      tie my @lines, 'Tie::File', $name or die "Can't tie file: $!\n";  #open and read line by line 
	  my $sr = "// insert on";
      my $vcd_name = $name;
	        $vcd_name =~ s/.v/.vcd/;	                                                             #dumpfile name
	  my $vcd_file  = '$dumpfile ("dumpfile_name");';                                                #
	        $vcd_file =~ s/dumpfile_name/$vcd_name/;	                                             #make dumpfile command 

      for (@lines) {
         if ($_ =~ /$sr/){                                                                           #find "// insert on"
			  $_ .= "\n $vcd_file \n";                                                               #write dumpfile command 
			  $_ .= " \$dumpvars(0,$top_module); \n";                                                #write dumpvars command
          while (my $row = <$info>){                                                                 #
              $_ .= "$row ";}                                                                        #write test pattern into testbench
			  $insert_flag = 1; }                                                                    #
	  }
  close $info;                                                                                       #close 
  untie @lines;                                                                                      #close 

     if ($insert_flag eq 1){
		print GREEN, "Inserted successfully!    -> Create $name\n", RESET;
		print "Run Iverilog tool:\n";                   #
		print GREEN, "Run Iverilog: $name", RESET;                   #
# ------Please put the necessary modules into iverilog folder -------------------------------------------------------#	
# ------iverilog folder: "top_module.v + sub_module.v"
        my $iverilog_dir = join '', $dir, '/iverilog/';   
        my @iverilog = ();		
		find(sub {                                                                                   #search the modules file in the entire iverilog folder
           push @iverilog,$File::Find::name if (-f $File::Find::name and /.v$/);                     #put all results into @iverilog array
      }, $iverilog_dir);
		system("iverilog @iverilog $name");                                                       
			
# ------make dumpfile and logfile 
        my $log_name = $name;
		      $log_name =~ s/.v/.log/;
		system("vvp a.out >$log_name");                                                              #
		print GREEN," -> Create $log_name\n",RESET;   
# ------Add date and time in top of logfile---------------------------------------------------------------------------#
		open(my $filename,"<",$log_name);
        my @newfile = <$filename>;
        close($filename);
# ------Ref: https://perldoc.perl.org/perlunifaq.html ----------------------------------------------------------------#		
		open($filename,">",$log_name);                  
        print $filename "$wTime\n";
        print $filename @newfile;
        close($filename); 
		
# ----- https://caveofprogramming.com/perl-tutorial/perl-mkdir-how-to-create-directories-in-perl.html ----------------#
# ----- Create a log folder if the directory does not exist
		unless(-e "log" or mkdir "log"){
			die "Unable to create log folder\n";}
		my $log_dir = join '', $dir, '/log/';                                                        #create log folder
		move $log_name, $log_dir;                                                                    #move file into log folder
		

# ----- Make covered database files-----------------------------------------------------------------------------------#
		print"Make covered database file:\n";      	
        my $run_file = $name;
		$run_file =~ s/.v//;	
        print GREEN, "Run Covered: $run_file\n", RESET;

		my  @module_file = join(' -v ', @iverilog);                                                  #@module_file = top_module.v -v sub_module.v
		system("covered score -t $top_module -v $run_file.v -v @module_file -vcd $vcd_name -o $run_file.cdd -Wignore "); 	
		push (@data_files,"$run_file.cdd");
		
# ----- https://caveofprogramming.com/perl-tutorial/perl-mkdir-how-to-create-directories-in-perl.html ----------------#		
# ----- Create a log folder if the directory does not exist
		unless(-e "testbench" or mkdir "testbench"){
			die "Unable to create testbench folder\n";}
		my $tb_dir = join '', $dir, '/testbench/';                                                   #create testbench folder
		move $name, $tb_dir;                                                                         #move testbench file into testbench folder	
		move "a.out", $tb_dir; 
		print "----------------------------------------------------------------------------\n";
    }       
     elsif ($insert_flag ==0 and $count >=1){
		  $err_cnt++;
	      print RED, "Error: Could not find [// insertion], Please check in testbench file!\n", RESET;
		  print "----------------------------------------------------------------------------\n";}
     else{ 
		  print RED, "$name Fail!\n", RESET; 
		  print "----------------------------------------------------------------------------\n";}
   } } }
  
# ----- Make merge all database files---------------------------------------------------------------------------------#
         print"Make covered merge file:\n";     	 
	if ($err_cnt  == 0 ) {
	    print GREEN,"Run covered merge:\n",RESET;     
		if (scalar(@data_files) gt 1){
			system("covered merge -o $merge_name.cdd @data_files ");}	     
	    else{
		    copy(@data_files,"$merge_name.cdd") or die "copy failed num2: $!"; }
# ----- Make covered report file -------------------------------------------------------------------------------------#			 
		system("covered report -d d -o $merge_name.rpt $merge_name.cdd");}

	else {
		print RED, "Error: Covered merge is not executed!\n",RESET;
		print RED, "An error occurred in the above implementation, please recheck!\n", RESET;	}
		
# ----- Create a covered folder if the directory does not exist
		unless(-e "covered" or mkdir "covered"){
		die "Unable to create covered folder\n";}	
		my $covered_dir = join '', $dir, '/covered/';	
		my @covered_files = ();
		find(sub {                                                                                      #search test pattern file in the entire TP/ path
           push @covered_files,$File::Find::name if (-f $File::Find::name and /\.(vcd|cdd|rpt)$/);      #put all results into @files array
      }, $dir);
		foreach my $move_file (@covered_files){
			move $move_file, $covered_dir;
		}
		
# -----Results board--------------------------------------------------------------------------------------------------#
	print "****************************************************************************\n";
    print"Results board:\n";
        if ($insert_flag == 0 ){	
		      print RED, "Error: Please check the insertion file or the insertion again!  $err_cnt error\n", RESET;
			  print YELLOW,"Warning: Covered is not finished!\n",RESET;}
		elsif ($err_cnt > 0){
              print YELLOW, "ALL RUNNING COMPLETED!  $err_cnt error\n", RESET;
			  print YELLOW,"Warning: Covered is not finished!\n",RESET;}	  
		else{
              print GREEN, "ALL RUNNING COMPLETED!   $err_cnt error\n", RESET;}
	print "****************************************************************************\n";	
