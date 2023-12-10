-- -- Names:
-- -- John Baldwin
-- -- Emmett Kogan


-- library ieee;
-- use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;

-- use work.config_pkg.all;
-- use work.user_pkg.all;

-- entity address_gen is
--     port (
--         clk         : in std_logic;
--         rst         : in std_logic;

--         go          : in std_logic;
--         en          : in std_logic;
--         size        : in std_logic_vector(16 downto 0);
--         start_addr  : in std_logic_vector(14 downto 0);

--         addr        : out std_logic_vector(14 downto 0);
--         valid       : out std_logic;
--         done        : out std_logic
--     );
-- end address_gen;

-- architecture default of address_gen is
--     type StateType is (WaitGo, AddrCompute);
    
--     signal size_reg : std_logic_vector(size'range);

--     signal curState     : StateType := WaitGo;
--     signal nextState    : StateType;

--     signal addr_compute : std_logic_vector(size'range) := (others => '0');
--     signal next_addr    : std_logic_vector(size'range);
-- begin

--     -- process(clk, rst)
--     -- begin
--     --     if (rst = '1') then
--     --         curState <= WaitGo;
--     --         valid <= '0';
--     --         done <= '0';
--     --         addr <= (others => '0');
--     --     elsif (rising_edge(clk)) then

--     --         curState <= curState;
--     --         addr_compute <= (others => '0');
--     --         valid <= '0';
            
--     --         case curState is
--     --             when WaitGo =>
--     --                 addr <= (others => '0');
--     --                 if (go = '1') then
--     --                     size_reg <= std_logic_vector(unsigned(size) + unsigned(start_addr));
--     --                     addr_compute(start_addr'range) <= start_addr;
--     --                     curState <= AddrCompute;
--     --                     done <= '0';
--     --                 end if;
--     --             when AddrCompute =>
--     --                 addr_compute <= addr_compute;
--     --                 if (addr_compute = size_reg) then
--     --                     valid <= '0';
--     --                     addr_compute <= (others => '0');
--     --                     addr <= (others => '0');
--     --                     done <= '1';
--     --                     curState <= WaitEnd;
--     --                 elsif (en = '1') then
--     --                     addr <= addr_compute(addr'range);
--     --                     -- does overflow need to be accounted for?
--     --                     addr_compute <= std_logic_vector(unsigned(addr_compute) + 1);
--     --                     valid <= '1';
--     --                     done <= '0';
--     --                 end if;
--     --             when WaitEnd =>
--     --                 addr <= (others => '0');
--     --                 done <= '1';
--     --                 if (go = '0') then
--     --                     curState <= WaitGo;
--     --                 end if;
--     --         end case;
--     --     end if;
--     -- end process;

--     process(clk, rst)
--     begin
--         if (rst = '1') then
--             addr_compute    <= (others => '0');
--             curState        <= WaitGo;
--         elsif (rising_edge(clk)) then
--             addr_compute <= next_addr;
--             curState <= nextState;
--         end if;
--     end process;

--     process(go, en, size, start_addr, curState, addr_compute)
--     begin
--         addr        <= (others => '0');
--         next_addr   <= addr_compute;
--         nextState   <= curState;
--         valid  <= '0';

--         case curState is
--             when WaitGo =>
--                 next_addr(addr'range) <= start_addr;
--                 size_reg <= std_logic_vector(unsigned(size) + unsigned(start_addr));
--                 if (go = '1') then
--                     nextState <= AddrCompute;
--                 end if;
--             when AddrCompute =>
--                 addr <= addr_compute(addr'range);

--                 if (addr_compute = size_reg) then
--                     nextState <= WaitGo;
--                 elsif (en = '0') then
--                     next_addr <= addr_compute;
--                 else
--                     valid <= '1';
--                     next_addr <= std_logic_vector(unsigned(addr_compute) + 1);
--                 end if;
--             when others => null;
--         end case;
--     end process;

-- end default;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.config_pkg.all;
use work.user_pkg.all;

entity address_gen is
port (
    clk         : in std_logic;
    rst         : in std_logic;
    go          : in std_logic;
    en          : in std_logic;
    size        : in std_logic_vector(16 downto 0);
    start_addr  : in std_logic_vector(14 downto 0);

    addr        : out std_logic_vector(14 downto 0);
    valid       : out std_logic
);
end address_gen;

architecture address_gen_bhv of address_gen is

    type StateType is (WaitGo, AddrCompute, WaitEnd);
    signal curState : StateType;

    signal addr_compute : unsigned(addr'range);

begin
    
    addr <= std_logic_vector(addr_compute);

    process (clk, rst)
    begin
        if (rst = '1') then
            addr_compute <= (others => '0');
            curState <= WaitGo;
        elsif (rising_edge(clk)) then
            curState <= curState;
            case (curState) is
                when WaitGo =>
                    addr_compute <= unsigned(start_addr);
                    if (go = '1') then
                        curState <= AddrCompute;
                    end if;
                when AddrCompute =>
                    if (en = '1') then
                        if (addr_compute = (unsigned(size) + unsigned(start_addr) - 1)) then
                            curState <= WaitEnd;
                        else 
                            addr_compute <= addr_compute + 1;
                        end if;
                    end if;
                when WaitEnd =>
                    if (go = '0') then
                        curState <= WaitGo;
                    end if;
            end case;
        end if;

        -- Necessary asynchronus assignment of valid
        if (curState = AddrCompute AND en = '1') then
            valid <= '1';
        else
            valid <= '0';
        end if;

    end process;


end address_gen_bhv;