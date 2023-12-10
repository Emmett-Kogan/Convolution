## DRAM_RD

John Baldwin
While working on the DRAM_RD I encountered 2 primary VHDL errors and many many errors due to Vivado oddities. My first major VHDL error stemmed from a combination of the Address Generator and combinational logic used for the reading of the FIFO. In this situation the FIFO was only reading 9978 out of 10000 values in the 3rd test. This was ultimately caused by the dram_rd_en signal going low before the last address was able to get out. By making my address generator a 2 process state machine and adding some additional combinational logic around the state machine I was able to fix this error. Part of what helped me fix this error was the following block of non-synthesizable test bench code that I embedded within the DRAM_RD architecture to allow me to see what values were being skipped during reads. 

    data <= fifo_data_out;
    process(user_clk)
    begin
	    if (rising_edge(user_clk)) then
		    if (unsigned(fifo_data_out) /= 0) then
			    assert (unsigned(fifo_data_out) = unsigned(fifo_data_out_prev) + 1) report  "FIFO read error"  severity  warning;
			    fifo_data_out_prev <= fifo_data_out;
		    elsif (done_and_rst = '1') then
			    fifo_data_out_prev <= (others => '0');
		    end  if;
	    end  if;
    end  process;

My second major issue arose from the counter and address generator being out of sync. This caused a done not asserted error and was ultimately fixed by making the assignment of address valid to be asynchronous and adjusting the start conditions for the counter. The combination of these two things fixed my timing issues and allowed me to move on to adding in timing constraints on the device. To help verify that my counter and address generator were working I wrote a short testbench that allowed me to visualize the signals and test specific properties where desired. 

Successful DRAM_RD testbench execution:

Successful DRAM_RD board run without timing constraints:

Successful DRAM_RD board run with timing constraints:

