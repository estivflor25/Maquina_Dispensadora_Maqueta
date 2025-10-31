library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Cont_30 is
    Port ( 
        Enable : in STD_LOGIC;
        Reset  : in STD_LOGIC;
        Clk    : in STD_LOGIC;               -- Reloj de 1Hz para segundos reales
        Z      : out STD_LOGIC_VECTOR(4 downto 0);  -- Tiempo restante (30-0)
        Tiempo_Completado : out STD_LOGIC    -- '1' cuando termina los 30 segundos
    );
end Cont_30;

architecture Behavioral of Cont_30 is
    signal contador : unsigned(4 downto 0) := "11110";  -- Inicia en 30
begin

    process(Clk, Reset)
    begin
        if Reset = '1' then
            contador <= "11110";  -- 30 en binario
            Tiempo_Completado <= '0';
            
        elsif rising_edge(Clk) then
            if Enable = '1' then
                if contador > 0 then
                    contador <= contador - 1;
                    Tiempo_Completado <= '0';
                else
                    Tiempo_Completado <= '1';  -- Señal de finalización
                end if;
            else
                Tiempo_Completado <= '0';
            end if;
        end if;
    end process;

    Z <= std_logic_vector(contador);

end Behavioral;