library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.config_pkg.all;
use work.user_pkg.all;
use work.math_custom.all;

entity user_app is
port (
	-- The basics
	clk		: in std_logic;
	rst		: in std_logic;
	
	-- Memory Map interface
	mmap_wr_en		: in std_logic;
	mmap_wr_addr	: in std_logic_vector(MMAP_ADDR_RANGE);
	mmap_wr_data	: in std_logic_vector(MMAP_DATA_RANGE);
	mmap_rd_en		: in std_logic;
	mmap_rd_addr	: in std_logic_vector(MMAP_ADDR_RANGE);
	mmap_rd_data	: out std_logic_vector(MMAP_DATA_RANGE);
	
	-- DMA Read interface
	ram0_rd_rd_en	: out std_logic;
	ram0_rd_go		: out std_logic;
	ram0_rd_valid	: in std_logic;
	ram0_rd_data	: in std_logic_vector(RAM0_RD_DATA_RANGE);
	ram0_rd_addr	: out std_logic_vector(RAM0_ADDR_RANGE);
	ram0_rd_size	: out std_logic_vector(RAM0_RD_SIZE_RANGE);
	ram0_rd_done	: in std_logic;
	
	-- debug signals
    debug_ram0_rd_count      : in std_logic_vector(RAM0_RD_SIZE_RANGE);
    debug_ram0_rd_start_addr : in std_logic_vector(RAM0_ADDR_RANGE);
    debug_ram0_rd_addr       : in std_logic_vector(RAM0_ADDR_RANGE);
    debug_ram0_rd_size       : in std_logic_vector(C_RAM0_ADDR_WIDTH downto 0);
    debug_ram0_rd_prog_full  : in std_logic;
    debug_ram0_rd_empty      : in std_logic;
	
	-- DMA Write interface
	ram1_wr_ready	: in std_logic;
	ram1_wr_go		: out std_logic;
	ram1_wr_valid	: out std_logic;
	ram1_wr_data	: out std_logic_vector(RAM1_WR_DATA_RANGE);
	ram1_wr_addr	: out std_logic_vector(RAM1_ADDR_RANGE);
	ram1_wr_size	: out std_logic_vector(RAM1_WR_SIZE_RANGE);
	ram1_wr_done	: in std_logic);
end entity;


architecture default of user_app is

	-- MMAP signals
	signal go			: std_logic;
	signal clear		: std_logic;
	signal sw_rst 		: std_logic;
	signal signal_size 	: std_logic_vector(RAM0_RD_SIZE_RANGE);
	signal kernel_data 	: std_logic_vector(KERNEL_WIDTH_RANGE);
	signal kernel_load 	: std_logic;
	signal kernel_ready : std_logic;
	signal done			: std_logic;
	
	-- Kernel Buffer related signals (output)
	signal kernel_buffer_empty	: std_logic;
	signal kernel_buffer_full	: std_logic;
	signal kernel_buffer_out	: std_logic_vector(C_KERNEL_SIZE*C_KERNEL_WIDTH-1 downto 0);
	
	-- Signal buffer related signals (output)
	signal signal_buffer_empty	: std_logic;
	signal signal_buffer_full	: std_logic;
	signal signal_buffer_out	: std_logic_vector(C_KERNEL_SIZE*C_SIGNAL_WIDTH-1 downto 0);
	
	-- Pipeline, clip and delay output signals
	signal pipeline_out		: std_logic_vector(clog2(C_KERNEL_SIZE)+C_KERNEL_WIDTH+C_SIGNAL_WIDTH-1 downto 0);
	signal clip_out			: std_logic_vector(C_SIGNAL_WIDTH-1 downto 0);
	signal valid_delay_out	: std_logic;
	
	-- Misc signals because VHDL doesn't like assignments that are equations
	signal kernel_buffer_wr_en		: std_logic;
	signal window_and_ram1_ready	: std_logic;
	signal rst_or_clear				: std_logic;
	
begin
	-- Memory Map
	U_MMAP : entity work.memory_map
		port map (
			clk			 => clk,
			rst			 => rst,
			
			wr_en		 => mmap_wr_en,
			wr_addr		 => mmap_wr_addr,
			wr_data		 => mmap_wr_data,
			rd_en		 => mmap_rd_en,
			rd_addr		 => mmap_rd_addr,
			rd_data		 => mmap_rd_data,
			
			go			 => go,
			clear		 => clear, 
			sw_rst		 => sw_rst,
			signal_size	 => signal_size,
			kernel_data	 => kernel_data,
			kernel_load	 => kernel_load,
			kernel_ready => kernel_ready,
			done		 => ram1_wr_done
		);

	-- TODO: Note that when this is merged with DMA ideally that the ramn_rd_addr signals need to be assigned something else I think

	-- RAM0 Signals
	ram0_rd_go		<= go;
	ram0_rd_rd_en	<= (not signal_buffer_full) and ram0_rd_valid;
	ram0_rd_size	<= std_logic_vector(unsigned(signal_size) + (2*(C_KERNEL_SIZE - 1)));
	ram0_rd_addr	<= (others => '0');
	
	-- RAM1 Signals
	ram1_wr_go		<= go;
	ram1_wr_valid	<= valid_delay_out;
	ram1_wr_size	<= std_logic_vector(unsigned(signal_size) + (C_KERNEL_SIZE - 1));
	ram1_wr_data	<= clip_out;
	ram1_wr_addr	<= (others => '0');
	
	-- Misc signals because VHDL doesn't like assignments that are equations
	kernel_buffer_wr_en		<= kernel_load and (not kernel_buffer_full);
	window_and_ram1_ready	<= not signal_buffer_empty and ram1_wr_ready;
	rst_or_clear			<= rst or clear;
	
	-- Currently swapping between BHV and BHV2 to test on the board rn
	
	-- Smart Buffers:
	U_KERNEL_BUFFER : entity work.smart_buffer(BHV)
		generic map (
			WINDOW_SIZE		=> C_KERNEL_SIZE,
			WORD_SIZE		=> C_SIGNAL_WIDTH,
			REVERSE_WINDOW	=> true
		)
		port map (
			clk 		=> clk,
			rst			=> rst_or_clear,
			wr_en 		=> kernel_buffer_wr_en,
			rd_en 		=> '0',
			wr_data 	=> kernel_data,
			
			empty 		=> kernel_buffer_empty,
			full 		=> kernel_buffer_full,
			rd_data 	=> kernel_buffer_out
			
		);

	U_SIGNAL_BUFFER : entity work.smart_buffer(BHV)
		generic map (
			WINDOW_SIZE		=> C_KERNEL_SIZE,
			WORD_SIZE		=> C_SIGNAL_WIDTH,
			REVERSE_WINDOW	=> false
		)
		port map (
			clk 		=> clk,
			rst			=> rst_or_clear,
			wr_en 		=> ram0_rd_valid,
			rd_en 		=> window_and_ram1_ready,
			wr_data 	=> ram0_rd_data,
			
			empty 		=> signal_buffer_empty,
			full 		=> signal_buffer_full,
			rd_data		=> signal_buffer_out
		);
		
	-- Output of convolution is 39 bits, output is only in 16 bits
	U_PIPELINE : entity work.mult_add_tree(unsigned_arch)
		generic map (
			num_inputs		=> C_KERNEL_SIZE,
			input1_width	=> C_KERNEL_WIDTH,
			input2_width	=> C_SIGNAL_WIDTH
		)
		port map (
			clk				=> clk,
			rst				=> rst_or_clear,
			en				=> ram1_wr_ready,
			input1			=> kernel_buffer_out,
			input2			=> signal_buffer_out,
			output			=> pipeline_out
		);
	
	-- Convolution postprocessing
    U_CLIP : entity work.clip
        generic map (
            num_inputs   => C_KERNEL_SIZE,
            input1_width => C_KERNEL_WIDTH,
            input2_width => C_SIGNAL_WIDTH,
            output_width => C_SIGNAL_WIDTH
        )
        port map (
            input  => pipeline_out,
            output => clip_out
        );
	
	U_DELAY : entity work.delay
		generic map (
			cycles	=> clog2(C_KERNEL_SIZE)+1,
			width	=> 1
		)
		port map (
			clk		=> clk,
			rst		=> rst_or_clear,
			en		=> ram1_wr_ready,
			input(0) => window_and_ram1_ready,
			output(0) => valid_delay_out
		);
			
end default;