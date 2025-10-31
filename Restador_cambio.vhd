library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Restador_cambio is
    Port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        confirmar    : in  std_logic;
        credito_cent : in  integer range 0 to 999;
        precio_cent  : in  integer range 0 to 99;
        cambio_out   : out integer range -999 to 999
    );
end Restador_cambio;

architecture Behavioral of Restador_cambio is

    component Precio is
        port (
            addr     : in  std_logic_vector(3 downto 0);
            data_out : out std_logic_vector(13 downto 0)
        );
    end component;

    signal precio_rom     : integer range 0 to 9999;
    signal precio_final   : integer range 0 to 999;
    signal cambio_reg     : integer range -999 to 999 := 0;
    signal prod_code_fake : std_logic_vector(3 downto 0) := "0001";
    signal precio_vec     : std_logic_vector(13 downto 0); -- <-- NUEVO

begin

    -- Instanciar ROM
    rom_precio : Precio
        port map(
            addr     => prod_code_fake,
            data_out => precio_vec
        );

    -- Convertir ROM a entero
    precio_rom <= to_integer(unsigned(precio_vec));

    -- Seleccionar precio: preferente el que viene por puerto
    precio_final <= precio_cent when precio_cent > 0 else precio_rom / 100;

    ------------------------------------------------------------------
    -- Resta sincronizada
    ------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            cambio_reg <= 0;
        elsif rising_edge(clk) then
            if confirmar = '1' then
                cambio_reg <= credito_cent - precio_final;
            end if;
        end if;
    end process;

    cambio_out <= cambio_reg;

end Behavioral;