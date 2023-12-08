-- Emmett Kogan
-- John Baldwin

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.math_custom.all;

use work.config_pkg.all;
use work.user_pkg.all;

entity smart_buffer is
	generic (
		WINDOW_SIZE		: positive	:= 128;
		WORD_SIZE		: positive	:= 16;
		REVERSE_WINDOW	: boolean	:= false
	);
	port (
		clk : in std_logic;
		rst : in std_logic;
	
		-- data in
		wr_data	: in std_logic_vector(WORD_SIZE-1 downto 0);
		
		-- input control signals
		rd_en 	: in std_logic;
		wr_en 	: in std_logic;
		
		-- output control signals
		empty 	: out std_logic;
		full 	: out std_logic;
		
		-- data out
		rd_data	: out std_logic_vector(WINDOW_SIZE*WORD_SIZE-1 downto 0)
	);


end smart_buffer;

architecture BHV of smart_buffer is

	signal buffer_r : window(WINDOW_SIZE-1 downto 0);
	signal count_r 	: unsigned(clog2(WINDOW_SIZE) downto 0)	:= to_unsigned(0, clog2(WINDOW_SIZE)+1);
	
begin

	-- copy the window registers to the std_logic_vector output
	process(buffer_r)
	begin
		for i in 0 to WINDOW_SIZE-1 loop
		
			if (REVERSE_WINDOW) then
				rd_data((i+1)*WORD_SIZE-1 downto i*WORD_SIZE) <= buffer_r(WINDOW_SIZE - i - 1);
			else
				rd_data((i+1)*WORD_SIZE-1 downto i*WORD_SIZE) <= buffer_r(i);
			end if;
		end loop;
	end process;
		
	-- Reads/writes
	process(clk, rst)
	begin
		if (rst = '1') then
			-- reset count and full register
			count_r <= (others => '0');	
			
			for i in 0 to WINDOW_SIZE-1 loop
				buffer_r(i) <= (others => '0');
			
			end loop;
			
			
		elsif (rising_edge(clk)) then
			-- on a read
			if (rd_en = '1' and count_r > 0) then
				-- decrement the count
				count_r <= count_r - 1;

			end if;
			
			-- on a write
			if (wr_en = '1') then
				-- shift the buffer down
				for i in 1 to WINDOW_SIZE-1 loop
					buffer_r(i-1) <= buffer_r(i);
				end loop;
				
				-- write the new data at the highest index
				buffer_r(WINDOW_SIZE-1) <= wr_data;
				
				-- increment the count
				if (not (count_r >= WINDOW_SIZE)) then
					count_r <= count_r + 1;
				end if;
			end if;	
		end if;
	end process;
	
	-- Full/empty logic
	full  <= '1' when (count_r >= WINDOW_SIZE) and not (rd_en = '1') else '0';
	empty <= '1' when (count_r < WINDOW_SIZE) else '0';
	
end architecture;