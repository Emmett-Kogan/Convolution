-- Names:
-- John Baldwin
-- Emmett Kogan

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.config_pkg.all;
use work.user_pkg.all;

entity counter is
    port (
        clk         : in std_logic;
        rst         : in std_logic;

        go          : in std_logic;
        en          : in std_logic;
        size        : in std_logic_vector(16 downto 0);

        done        : out std_logic
    );
end counter;

architecture default of counter is
    type StateType is (WaitGo, ReadCount, WaitEnd);
    
    signal size_reg : std_logic_vector(size'range);
    signal done_reg : std_logic;

    signal curState  : StateType := WaitGo;

    signal count     : std_logic_vector(size'range) := (others => '0');

begin

    -- process(clk, rst)
    -- begin
    --     if (rst = '1') then
    --         curState    <= WaitGo;
    --         count       <= (others => '0');
    --         done        <= '0';
    --     elsif (rising_edge(clk)) then
    --         case curState is
    --             when WaitGo =>
    --                 done <= '0';
    --                 if (go = '1') then
    --                     size_reg <= size;
    --                     count <= (others => '0');
    --                     curState <= ReadCount;
    --                 end if;
    --             when ReadCount =>
    --                 count <= count;
    --                 if (unsigned(count) = unsigned(size_reg)) then
    --                     count <= (others => '0');
    --                     done <= '1';
    --                     curState <= WaitEnd;
    --                 elsif (en = '1') then
    --                     -- does overflow need to be accounted for?
    --                     count <= std_logic_vector(unsigned(count) + 1);
    --                     done <= '0';
    --                 end if;
    --             when WaitEnd =>
    --                 done <= '1';
    --                 if (go = '0') then
    --                     curState <= WaitGo;
    --                 end if;
    --         end case;
    --     end if;
    -- end process;

    process(clk, rst)
    begin
        if (rst = '1') then
            count       <= (others => '0');
            done_reg    <= '0';
            curState    <= WaitGo;
        elsif (rising_edge(clk)) then
            case (curState) is
                when WaitGo =>
                    count       <= (others => '0');
                    done_reg    <= '0';
                    curState    <= ReadCount;
                    -- size_reg    <= size;
                when ReadCount =>
                    if (en = '1') then
                        if (unsigned(count) = unsigned(size) - 1) then
                            done_reg <= '1';
                            curState <= WaitEnd;
                        else
                            count <= std_logic_vector(unsigned(count) + 1);
                        end if;
                    end if;
                when WaitEnd =>
                    count <= (others => '0');
                    done_reg  <= '1';
                    curState <= WaitGo;
            end case;
        end if;
    end process;
    done <= done_reg;

end default;