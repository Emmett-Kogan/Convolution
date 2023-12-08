-- Emmett Kogan
-- John Baldwin

-- smart_buffer tb

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.math_custom.all;

use work.config_pkg.all;
use work.user_pkg.all;

entity smart_buffer_tb is
end smart_buffer_tb;

architecture TB of smart_buffer_tb is
	
	constant WINDOW_SIZE 	: integer := 4;
	constant WORD_SIZE		: integer := 16;
	
	signal clk		: std_logic := '0';
	signal rst		: std_logic;
	signal wr_data	: std_logic_vector(15 downto 0);
	signal rd_en	: std_logic;
	signal wr_en	: std_logic;
	signal empty	: std_logic;
	signal full		: std_logic;
	signal rd_data 	: std_logic_vector(16*4-1 downto 0);
	
	signal test_data : window(WINDOW_SIZE-1 downto 0);
	
begin

	UUT : entity work.smart_buffer
		generic map(
			WINDOW_SIZE		=> 4,
			WORD_SIZE		=> 16,
			REVERSE_WINDOW	=> false
		)
		port map(
			clk		=> clk,
			rst		=> rst,
			wr_data	=> wr_data,
			rd_en	=> rd_en,
			wr_en	=> wr_en,	
			empty	=> empty,
			full	=> full,
			rd_data	=> rd_data
		);

	clk <= not clk after 5 ns;
		
	process
	begin
	
		-- reset the smart buffer
		rst <= '1';
		wait for 20 ns;
		rst <= '0';
	
		-- load the smart buffer with the initial fill, so it will be all 0s
		for i in 0 to WINDOW_SIZE-1 loop
		
			wr_data <= (others => '0');
			wr_en   <= '1';
			wait until rising_edge(clk);
			
			test_data(i) <= (others => '0');
		
		end loop;	-- i
		
		-- load other data into the smart buffer, then check the read data every time
		
		-- Testing writing (so shifting and writing stuff to the top)
		for i in 0 to 20 loop
			
			-- load a number
			wr_data <= std_logic_vector(to_unsigned(i, WORD_SIZE));
			wr_en <= '1';
			wait until rising_edge(clk);
			wr_en <= '0';
			
			-- update key
			for j in 1 to WINDOW_SIZE-1 loop
				test_data(j-1) <= test_data(j);
			end loop;
			test_data(3) <= std_logic_vector(to_unsigned(i, WORD_SIZE));
			
			-- assertions
			for j in 0 to WINDOW_SIZE-1 loop
				assert(rd_data((j+1)*WORD_SIZE-1 downto j*WORD_SIZE) = test_data(j))
					report "rd_data incorrect: " & 
					integer'image(to_integer(unsigned(rd_data((j+1)*WORD_SIZE-1 downto j*WORD_SIZE)))) & " != " &
					integer'image(to_integer(unsigned(test_data(j))))
					severity warning;
				
			end loop;
		end loop;	-- i

		assert false report "SIM FINISHED" severity failure;
		
	end process;
end TB;