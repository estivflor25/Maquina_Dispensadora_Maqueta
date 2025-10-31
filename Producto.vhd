library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Producto is
    Port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        producto_sel    : in  unsigned(3 downto 0);
        decrementar     : in  std_logic;
        stock_ok        : out std_logic;
        stock_count     : out integer range 0 to 255;
        precio_producto : out integer range 0 to 9500
    );
end Producto;

architecture Behavioral of Producto is
    -- Tipo y señal para almacenar stock de cada producto
    type stock_array is array (0 to 15) of integer range 0 to 255;
    signal stock_reg : stock_array := (others => 3); -- Stock inicial 3 unidades por producto

    -- Señal para recibir precio desde ROM
    signal precio_rom : std_logic_vector(13 downto 0);

    -- Instancia del módulo Precio (ROM)
    component Precio
        port (
            addr     : in  std_logic_vector(3 downto 0);
            data_out : out std_logic_vector(13 downto 0)
        );
    end component;

begin

    ROM_inst : Precio
        port map (
            addr     => std_logic_vector(producto_sel),
            data_out => precio_rom
        );

    process(clk, reset)
        variable index : integer;
    begin
        if reset = '1' then
            stock_reg <= (others => 5);
            stock_ok <= '0';
            stock_count <= 0;
            precio_producto <= 0;
        elsif rising_edge(clk) then
            index := to_integer(producto_sel);
            if decrementar = '1' and stock_reg(index) > 0 then
                stock_reg(index) <= stock_reg(index) - 1;
            end if;

            precio_producto <= to_integer(unsigned(precio_rom));
            stock_count <= stock_reg(index);

            if stock_reg(index) > 0 then
                stock_ok <= '1';
            else
                stock_ok <= '0';
            end if;
        end if;
    end process;

end Behavioral;
