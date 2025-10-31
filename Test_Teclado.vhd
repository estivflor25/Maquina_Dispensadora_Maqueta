library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Test_Teclado is
port(
    clk          : in  std_logic;
    filas        : in  std_logic_vector(3 downto 0);
    columnas     : out std_logic_vector(3 downto 0);
    displayU     : out std_logic_vector(6 downto 0);
    displayD     : out std_logic_vector(6 downto 0);
    led_valido   : out std_logic;
    selected_num : out std_logic_vector(3 downto 0)  -- Nueva salida
);
end Test_Teclado;

architecture rtl of Test_Teclado is

    -- Decodificador 7 segmentos (común cátodo)
    component Deco7seg is
    port(
        A,B,C,D : in  std_logic;
        display : out std_logic_vector(6 downto 0)
    );
    end component;

    -- Escaneo
    signal col_cnt      : integer range 0 to 3 := 0;
    signal scan_tic     : integer range 0 to 499999 := 0;  -- 10 ms @ 50 MHz
    signal cols         : std_logic_vector(3 downto 0) := "1110";

    -- Tecla
    signal key_val      : integer range 0 to 15 := 0;
    signal key_strobe   : std_logic := '0';

    -- Display
    signal decenas      : integer range 0 to 9 := 0;
    signal unidades     : integer range 0 to 9 := 0;
    signal binD, binU   : std_logic_vector(3 downto 0);

begin

    ------------------------------------------------------------------
    -- 1) Escaneo de columnas (10 ms por columna)
    ------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if scan_tic = 499999 then
                scan_tic <= 0;
                col_cnt  <= (col_cnt + 1) mod 4;
                case col_cnt is
                    when 0 => cols <= "1110";
                    when 1 => cols <= "1101";
                    when 2 => cols <= "1011";
                    when 3 => cols <= "0111";
                end case;
            else
                scan_tic <= scan_tic + 1;
            end if;
        end if;
    end process;

    columnas <= cols;

    ------------------------------------------------------------------
    -- 2) Decodificación de la tecla pulsada
    ------------------------------------------------------------------
    process(clk)
        variable k : integer range 0 to 15;
    begin
        if rising_edge(clk) then
            key_strobe <= '0';
            k := 15;                       -- default: ninguna

            case cols is
                when "1110" =>          -- COL 0
                    case filas is
                        when "1110" => k := 1;   -- 1
                        when "1101" => k := 4;   -- 4
                        when "1011" => k := 7;   -- 7
                        when "0111" => k := 14;  -- *
                        when others => null;
                    end case;

                when "1101" =>          -- COL 1
                    case filas is
                        when "1110" => k := 2;   -- 2
                        when "1101" => k := 5;   -- 5
                        when "1011" => k := 8;   -- 8
                        when "0111" => k := 0;   -- 0
                        when others => null;
                    end case;

                when "1011" =>          -- COL 2
                    case filas is
                        when "1110" => k := 3;   -- 3
                        when "1101" => k := 6;   -- 6
                        when "1011" => k := 9;   -- 9
                        when "0111" => k := 15;  -- #
                        when others => null;
                    end case;

                when "0111" =>          -- COL 3  (A,B,C,D)
                    case filas is
                        when "1110" => k := 10;  -- A
                        when "1101" => k := 11;  -- B
                        when "1011" => k := 12;  -- C
                        when "0111" => k := 13;  -- D
                        when others => null;
                    end case;

                when others => null;
            end case;

            -- Si es una tecla válida (0-15) generamos strobe
            if k /= 15 then
                key_val    <= k;
                key_strobe <= '1';
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- 3) Pasar el valor a los displays
    ------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if key_strobe = '1' then
                if key_val > 9 then
                    decenas  <= 1;
                    unidades <= key_val - 10;
                else
                    decenas  <= 0;
                    unidades <= key_val;
                end if;
            end if;
        end if;
    end process;

    binD <= std_logic_vector(to_unsigned(decenas , 4));
    binU <= std_logic_vector(to_unsigned(unidades, 4));

    ------------------------------------------------------------------
    -- 4) Instancias del decodificador
    ------------------------------------------------------------------
    U_DEC_D: Deco7seg
    port map(A=>binD(3), B=>binD(2), C=>binD(1), D=>binD(0), display=>displayD);

    U_DEC_U: Deco7seg
    port map(A=>binU(3), B=>binU(2), C=>binU(1), D=>binU(0), display=>displayU);

    ------------------------------------------------------------------
    -- 5) LED indicador
    ------------------------------------------------------------------
    led_valido <= key_strobe;

    ------------------------------------------------------------------
    -- 6) Salida del número seleccionado
    ------------------------------------------------------------------
    selected_num <= std_logic_vector(to_unsigned(key_val, 4));

end rtl;
