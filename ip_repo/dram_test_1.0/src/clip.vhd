-- Emmett Kogan
-- John Baldwin

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.math_custom.all;

entity clip is
	generic (
		num_inputs   : positive;
		input1_width : positive;
		input2_width : positive;
		output_width : positive);
	port (
		input  : in std_logic_vector(input1_width+input2_width+clog2(num_inputs)-1 downto 0);
		output : out std_logic_vector(output_width-1 downto 0)
	);
end clip;

architecture BHV of clip is

begin
	output <= input(output'range) when (unsigned(input) <= to_unsigned((2**output_width) - 1, input'length)) else
			  (others => '1');
end BHV;