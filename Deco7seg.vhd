library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Deco7seg is
    Port (
        A, B, C, D : in  std_logic;
        display    : out std_logic_vector(6 downto 0)
    );
end Deco7seg;

architecture Behavioral of Deco7seg is
    signal bin_in : std_logic_vector(3 downto 0);
begin
    bin_in <= A & B & C & D;

    process(bin_in)
    begin
        case bin_in is
            when "0000" => display <= not "1111110";
            when "0001" => display <= not "0110000";
            when "0010" => display <= not "1101101";
            when "0011" => display <= not "1111001";
            when "0100" => display <= not "0110011";
            when "0101" => display <= not "1011011";
            when "0110" => display <= not "1011111";
            when "0111" => display <= not "1110000";
            when "1000" => display <= not "1111111";
            when "1001" => display <= not "1111011";
            when others => display <= not "0000000";
        end case;
    end process;

end Behavioral;
