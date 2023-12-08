-- Emmett Kogan
-- John Baldwin

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.math_custom.all;

entity clip_tb is
end clip_tb;

architecture TB of clip_tb is

	signal input  : std_logic_vector(38 downto 0);
	signal output : std_logic_vector(15 downto 0);

begin

	UUT : entity work.clip
		generic map(
			num_inputs => 128,
			input1_width => 16,
			input2_width => 16,
			output_width => 16
		)
		port map(
			input  => input,
			output => output
		);

		process
		
			function clip_check(n : unsigned) return unsigned is
				variable temp : unsigned(38 downto 0);
			
			begin
				if (n > to_unsigned((2**16)-1, n'length)) then
					return to_unsigned((2**16)-1, 16);
				else
					return n;
				end if;
			end function;
		
		
		begin
			
			-- Drive the input
			for i in 0 to (2**20)-1 loop
				input <= std_logic_vector(to_unsigned(i, input'length));
				wait for 5 ns;	

				assert(unsigned(output) = clip_check(to_unsigned(i, input'length)))
					report "Output incorrect: " &
					integer'image(to_integer(unsigned(output))) & " != " &
					integer'image(to_integer(clip_check(to_unsigned(i, input'length)))) &
					" w/ input == " & integer'image(i)
					severity warning;
			end loop;
			
			assert false report "test1: " & integer'image( (((2+1)*16)-1) ) severity warning;
			assert false report "test2: " & integer'image( (2+1)*16-1 ) severity warning;
			
			assert false report "SIMULATION FINISHED" severity failure;
			-- wait;
		
		
		end process;
end TB;