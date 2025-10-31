library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mux4x4 is
    Port (
        clk       : in  std_logic;
        reset     : in  std_logic;
        monedas_U : in  std_logic_vector(6 downto 0);
        monedas_D : in  std_logic_vector(6 downto 0);
        teclado_U : in  std_logic_vector(6 downto 0);
        teclado_D : in  std_logic_vector(6 downto 0);
        cambio_U  : in  std_logic_vector(6 downto 0);
        cambio_D  : in  std_logic_vector(6 downto 0);
        error_U   : in  std_logic_vector(6 downto 0);
        error_D   : in  std_logic_vector(6 downto 0);
        saldo_U   : in  std_logic_vector(6 downto 0);
        saldo_D   : in  std_logic_vector(6 downto 0);
        sel       : in  std_logic_vector(2 downto 0);
        displayU  : out std_logic_vector(6 downto 0);
        displayD  : out std_logic_vector(6 downto 0);
        modo_out  : out std_logic_vector(2 downto 0)
    );
end mux4x4;

architecture Behavioral of mux4x4 is

    constant TIME_MONEDAS : unsigned(31 downto 0) := to_unsigned(50_000_000 * 3, 32); -- 3 s
    constant TIME_TECLADO : unsigned(31 downto 0) := to_unsigned(50_000_000 * 5, 32); -- 5 s
    constant TIME_CAMBIO  : unsigned(31 downto 0) := to_unsigned(50_000_000 * 4, 32); -- 4 s
    constant TIME_ERROR   : unsigned(31 downto 0) := to_unsigned(50_000_000 * 3, 32); -- 3 s
    constant TIME_SALDO   : unsigned(31 downto 0) := to_unsigned(50_000_000 * 3, 32); -- 3 s

    signal contador   : unsigned(31 downto 0) := (others => '0');
    signal sel_reg    : std_logic_vector(2 downto 0) := "000";
    signal timeout_ok : std_logic := '0';

begin

    modo_out <= sel_reg;

    process(clk, reset)
    begin
        if reset = '1' then
            contador   <= (others => '0');
            timeout_ok <= '0';
        elsif rising_edge(clk) then
            if sel /= sel_reg then
                contador   <= (others => '0');
                sel_reg    <= sel;
                timeout_ok <= '0';
            else
                case sel_reg is
                    when "000" => if contador < TIME_MONEDAS then contador <= contador + 1; else timeout_ok <= '1'; end if;
                    when "001" => if contador < TIME_TECLADO then contador <= contador + 1; else timeout_ok <= '1'; end if;
                    when "010" => if contador < TIME_CAMBIO  then contador <= contador + 1; else timeout_ok <= '1'; end if;
                    when "011" => if contador < TIME_ERROR   then contador <= contador + 1; else timeout_ok <= '1'; end if;
                    when "100" => if contador < TIME_SALDO   then contador <= contador + 1; else timeout_ok <= '1'; end if;
                    when others => contador <= (others => '0'); timeout_ok <= '0';
                end case;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            case sel_reg is
                when "000"  => displayU <= monedas_U; displayD <= monedas_D;
                when "001"  => displayU <= teclado_U; displayD <= teclado_D;
                when "010"  => displayU <= cambio_U;  displayD <= cambio_D;
                when "011"  => displayU <= error_U;   displayD <= error_D;
                when "100"  => displayU <= saldo_U;   displayD <= saldo_D;
                when others => displayU <= "1111111"; displayD <= "1111111";
            end case;
        end if;
    end process;

end Behavioral;