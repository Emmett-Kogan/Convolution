library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.config_pkg.all;
use work.user_pkg.all;
use work.math_custom.all;

entity smart_buffer is
	generic (
		WINDOW_SIZE		: positive	:= 128;
		WORD_SIZE		: positive	:= 16;
		REVERSE_WINDOW	: boolean	:= false
	);
	port (
		clk		: in std_logic;
		rst		: in std_logic;
		wr_en	: in std_logic;
		rd_en	: in std_logic;
		wr_data	: in std_logic_vector(WORD_SIZE-1 downto 0);
		
		empty   : out std_logic;
		full    : out std_logic;
		rd_data	: out std_logic_vector(WINDOW_SIZE*WORD_SIZE-1 downto 0)
	);
end smart_buffer;

architecture BHV of smart_buffer is

	signal buffer_r : std_logic_vector(WINDOW_SIZE*WORD_SIZE-1 downto 0);
	
begin

		
	-- Reads/writes
	process(clk, rst)
		variable count : unsigned(clog2(WINDOW_SIZE) downto 0) := to_unsigned(0, clog2(WINDOW_SIZE)+1);
	begin
		if (rst = '1') then
			-- reset empty/full, count var, and buffer register
			buffer_r <= (others => '0');			
			empty <= '1';
			full <= '0';
			count := (others => '0');	
			
		elsif (rising_edge(clk)) then
			-- on a read
			if (rd_en = '1' and count > 0) then
				count := count - 1;
			end if;
			
			-- on a write
			if (wr_en = '1' and count < WINDOW_SIZE) then
				count := count + 1;
				
				-- Depending on reverse or not shift towards one end and append at the other 
				-- This is kind of arbitrary but appenidng at the highest spot and shifting towards the lowest is the default way
				if (REVERSE_WINDOW) then
					buffer_r <= buffer_r((WINDOW_SIZE-1)*WORD_SIZE-1 downto 0) & wr_data;
				else
					buffer_r <= wr_data & buffer_r((WINDOW_SIZE*WORD_SIZE)-1 downto WORD_SIZE);
				end if;
			end if;	
		end if;
		
		-- Update status outputs
		-- Has to be here since scope of variable, I could not for the life of me get this 
		-- to work with a signal so I could do concurrent assignments outside the process, 
		-- too brain fried to try a bunch of stuff rn
		if (count < WINDOW_SIZE) then
			empty <= '1';
			full <= '0';
		else
			empty <= '0';
			full  <= not rd_en;
		end if;
	end process;
	
	rd_data <= buffer_r;
	
end architecture;