library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Precio is
    port
    (
        addr      : in  std_logic_vector(3 downto 0);  -- Dirección (0–15)
        data_out  : out std_logic_vector(13 downto 0)  -- Precio codificado en binario (hasta 9500 ≈ 14 bits)
    );
end Precio;

architecture arch_Precio_ROM of Precio is

    -- ROM con 16 posiciones, cada una un precio de producto
	type ROM_type is array (0 to 15) of std_logic_vector(13 downto 0);
	constant ROM : ROM_type := (
		 0  => std_logic_vector(to_unsigned(500, 14)),    -- 500
		 1  => std_logic_vector(to_unsigned(1000, 14)),   -- 1000
		 2  => std_logic_vector(to_unsigned(1500, 14)),   -- 1500
		 3  => std_logic_vector(to_unsigned(2000, 14)),   -- 2000
		 4  => std_logic_vector(to_unsigned(2500, 14)),   -- 2500
		 5  => std_logic_vector(to_unsigned(3000, 14)),   -- 3000
		 6  => std_logic_vector(to_unsigned(3500, 14)),   -- 3500
		 7  => std_logic_vector(to_unsigned(4000, 14)),   -- 4000
		 8  => std_logic_vector(to_unsigned(4500, 14)),   -- 4500
		 9  => std_logic_vector(to_unsigned(5000, 14)),   -- 5000
		 10 => std_logic_vector(to_unsigned(5500, 14)),   -- 5500
		 11 => std_logic_vector(to_unsigned(6000, 14)),   -- 6000
		 12 => std_logic_vector(to_unsigned(6500, 14)),   -- 6500
		 13 => std_logic_vector(to_unsigned(7000, 14)),   -- 7000
		 14 => std_logic_vector(to_unsigned(7500, 14)),   -- 7500
		 15 => std_logic_vector(to_unsigned(8000, 14))    -- 8000
	);

begin

    data_out <= ROM(to_integer(unsigned(addr)));

end arch_Precio_ROM;
