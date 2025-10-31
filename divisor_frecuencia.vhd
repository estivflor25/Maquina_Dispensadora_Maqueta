library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity divisor_frecuencia is
    Port (
        clk_in  : in  STD_LOGIC;
        reset   : in  STD_LOGIC;
        clk_out : out STD_LOGIC
    );
end divisor_frecuencia;

architecture Behavioral of divisor_frecuencia is
    constant DIVISOR : integer := 25000; -- Para 50MHz -> ~1kHz multiplexacion

    signal contador : integer range 0 to DIVISOR-1 := 0;
    signal clk_out_sig : STD_LOGIC := '0';
begin
    process(clk_in, reset)
    begin
        if reset = '1' then
            contador <= 0;
            clk_out_sig <= '0';
        elsif rising_edge(clk_in) then
            if contador = DIVISOR-1 then
                contador <= 0;
                clk_out_sig <= not clk_out_sig;
            else
                contador <= contador + 1;
            end if;
        end if;
    end process;
    
    clk_out <= clk_out_sig;
end Behavioral;
