library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Teclado_Matricial is
    Port (
        filas    : in  STD_LOGIC_VECTOR(3 downto 0);
        columnas : out STD_LOGIC_VECTOR(3 downto 0);
        tecla    : out unsigned(3 downto 0);
        valid    : out STD_LOGIC;
        clk      : in  STD_LOGIC
    );
end Teclado_Matricial;

architecture Behavioral of Teclado_Matricial is
    signal col_index : integer range 0 to 3 := 0;
    signal counter : integer range 0 to 49999 := 0;
    signal columnas_reg : STD_LOGIC_VECTOR(3 downto 0) := "1110";
    signal debounce_count : integer range 0 to 4999 := 0;
    signal last_filas : STD_LOGIC_VECTOR(3 downto 0) := "1111";
begin

    process(clk)
    begin
        if rising_edge(clk) then
            -- Divisor de frecuencia para escaneo lento (~1ms)
            if counter = 49999 then
                counter <= 0;
                
                -- Ciclo de columnas
                case col_index is
                    when 0 => columnas_reg <= "1110";
                    when 1 => columnas_reg <= "1101";
                    when 2 => columnas_reg <= "1011";
                    when 3 => columnas_reg <= "0111";
                end case;
                
                columnas <= columnas_reg;
                
                -- Antirrebote simple
                if filas /= last_filas then
                    debounce_count <= 0;
                    last_filas <= filas;
                elsif debounce_count < 4999 then
                    debounce_count <= debounce_count + 1;
                else
                    -- Detección estable de tecla
                    if filas /= "1111" then
                        valid <= '1';
                        case col_index is
                            when 0 =>
                                case filas is
                                    when "1110" => tecla <= "0001"; -- 1
                                    when "1101" => tecla <= "0100"; -- 4
                                    when "1011" => tecla <= "0111"; -- 7
                                    when "0111" => tecla <= "1110"; -- * (14)
                                    when others => tecla <= "1111"; valid <= '0';
                                end case;
                            when 1 =>
                                case filas is
                                    when "1110" => tecla <= "0010"; -- 2
                                    when "1101" => tecla <= "0101"; -- 5
                                    when "1011" => tecla <= "1000"; -- 8
                                    when "0111" => tecla <= "0000"; -- 0
                                    when others => tecla <= "1111"; valid <= '0';
                                end case;
                            when 2 =>
                                case filas is
                                    when "1110" => tecla <= "0011"; -- 3
                                    when "1101" => tecla <= "0110"; -- 6
                                    when "1011" => tecla <= "1001"; -- 9
                                    when "0111" => tecla <= "1111"; -- # (15)
                                    when others => tecla <= "1111"; valid <= '0';
                                end case;
                            when 3 =>
                                case filas is
                                    when "1110" => tecla <= "1010"; -- A (10)
                                    when "1101" => tecla <= "1011"; -- B (11)
                                    when "1011" => tecla <= "1100"; -- C (12)
                                    when "0111" => tecla <= "1101"; -- D (13)
                                    when others => tecla <= "1111"; valid <= '0';
                                end case;
                        end case;
                    else
                        valid <= '0';
                        tecla <= "1111";
                    end if;
                end if;
                
                -- Avanza a siguiente columna
                if col_index = 3 then
                    col_index <= 0;
                else
                    col_index <= col_index + 1;
                end if;
                
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

end Behavioral;