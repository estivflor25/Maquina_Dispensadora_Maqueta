library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity flip_flop_D is
    Port (
        D   : in STD_LOGIC;
        clk : in STD_LOGIC;
        Q   : out STD_LOGIC
    );
end flip_flop_D;

architecture Behavioral of flip_flop_D is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            Q <= D;
        end if;
    end process;
end Behavioral;
