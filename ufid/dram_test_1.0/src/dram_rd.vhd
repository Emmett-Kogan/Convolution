library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dram_rd is 
    port (
        dram_clk             : in  std_logic;
        user_clk             : in  std_logic;
        dram_rst             : in  std_logic;
        user_rst             : in  std_logic;
        --user clock domain
        go                   : in  std_logic;
        rd_en                : in  std_logic;
        stall                : in  std_logic;
        start_addr           : in  std_logic_vector (14 downto 0);
        size                 : in  std_logic_vector (16 downto 0);
        valid                : out std_logic;
        data                 : out std_logic_vector (15 downto 0);
        done                 : out std_logic;
        --dram clock domain
        dram_ready           : in  std_logic;
        dram_rd_en           : out std_logic;
        dram_rd_addr         : out std_logic_vector (14 downto 0);
        dram_rd_data         : in  std_logic_vector (31 downto 0);
        dram_rd_valid        : in  std_logic;
        --debug
        debug_count          : out std_logic_vector (16 downto 0);
        debug_dma_size       : out std_logic_vector (15 downto 0);
        debug_dma_start_addr : out std_logic_vector (14 downto 0);
        debug_dma_addr       : out std_logic_vector (14 downto 0);
        debug_dma_prog_full  : out std_logic;
        debug_dma_empty      : out std_logic
        );
end dram_rd;

architecture str of dram_rd is
    signal rcv : std_logic;
    signal programmable_full : std_logic;
    signal done_and_rst : std_logic;
    signal ff2 : std_logic;
    signal FIFO_rst : std_logic;
    signal FIFO_empty : std_logic;
    signal converted_size : std_logic_vector (16 downto 0);
    signal FIFO_rd_en : std_logic;
    signal addr_valid : std_logic;
    signal FIFO_full : std_logic;
    signal addr_gen_en : std_logic;
    signal FIFO_wr : std_logic;
    signal counter_rst : std_logic;
    signal FIFO_in : std_logic_vector (31 downto 0);
    signal counter_done_r : std_logic;


    component fifo_generator_0
        port (
        rst : IN STD_LOGIC;
        wr_clk : IN STD_LOGIC;
        rd_clk : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        full : OUT STD_LOGIC;
        prog_full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC
        );
    end component;


    signal fifo_data_out : std_logic_vector(15 downto 0) := (others => '0');
    signal fifo_data_out_prev : std_logic_vector(15 downto 0) := (others => '0');

   begin

    addr_gen_en <= dram_ready and not programmable_full;
    U_ADDR_GEN:  entity work.address_gen
        port map (
            clk         => dram_clk,
            rst         => dram_rst,
            go          => rcv,
            en          => addr_gen_en,
            size        => converted_size,
            start_addr  => start_addr,
            addr        => dram_rd_addr,
            valid       => addr_valid
    );
    dram_rd_en <= addr_valid and not programmable_full;


    FIFO_in <= dram_rd_data(15 downto 0) & dram_rd_data(31 downto 16);
    U_DMA_FIFO : fifo_generator_0
        PORT MAP (
            rst => FIFO_rst,
            wr_clk => dram_clk,
            rd_clk => user_clk,
            din => FIFO_in,
            wr_en => dram_rd_valid,
            rd_en => FIFO_rd_en,
            dout => fifo_data_out,
            full => FIFO_full,
            prog_full => programmable_full,
            empty => FIFO_empty
    ); 
    FIFO_rd_en <= rd_en and not FIFO_empty;
    valid <= not FIFO_empty;

    
    U_COUNTER : entity work.counter
        port map (
            rst =>  user_rst,
            clk =>  user_clk,
            en =>  FIFO_rd_en,
            size =>  size,
            done => done_and_rst,
            go => go
    );
    done <= done_and_rst;

    U_FF0 : entity work.reg
    generic map (
        width => 1
    )
    port map (
        clk =>  user_clk,
        rst =>  user_rst,
        d(0) =>  done_and_rst,
        q(0) =>  counter_done_r
    );

    U_FF1 : entity work.reg
        generic map (
            width => 1
        )
        port map (
            clk =>  dram_clk,
            rst =>  dram_rst,
            d(0) =>  counter_done_r,
            q(0) =>  ff2
    );
    
    U_FF2 : entity work.reg
        generic map (
            width => 1
        )
        port map (
            clk =>  dram_clk,
            rst =>  dram_rst,
            d(0) =>  ff2,
            q(0) =>  FIFO_rst
    );
    
    U_HS_SYNC : entity work.handshake
        port map (
            clk_src =>  user_clk,
            clk_dest =>  dram_clk,
            rst =>  user_rst,
            go =>  go,
            rcv =>  rcv,
            delay_ack => '0',
            ack => open
    );
    
    process(size)
    begin
        if (size(0) = '1') then
            converted_size <= '0' & std_logic_vector(unsigned(size(16 downto 1)) + 1);
        else
            converted_size <= '0' & size(16 downto 1);
        end if;
    end process;
    
    data <= fifo_data_out;
    process(user_clk)
    begin
        if (rising_edge(user_clk)) then
            if (unsigned(fifo_data_out) /= 0) then
                assert (unsigned(fifo_data_out) = unsigned(fifo_data_out_prev) + 1) report "FIFO read error" severity warning;
                fifo_data_out_prev <= fifo_data_out;
            elsif (done_and_rst = '1') then
                fifo_data_out_prev <= (others => '0');
            end if;
        end if;
    end process;



end str;
    
    



