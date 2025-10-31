library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sistema_sensores is
    Port(
        sensor1 : in STD_LOGIC;
        sensor2 : in STD_LOGIC;
        clk     : in STD_LOGIC;
        display1 : out STD_LOGIC_VECTOR(6 downto 0);
        display2 : out STD_LOGIC_VECTOR(6 downto 0);
        FF1_Q   : out std_logic;  -- Salida procesada del sensor 1
        FF2_Q   : out std_logic   -- Salida procesada del sensor 2
    );
end sistema_sensores;

architecture Structural of sistema_sensores is
    -- Declaración de componentes
    component flip_flop_D is
        port(
            D   : in STD_LOGIC;
            clk : in STD_LOGIC;
            Q   : out STD_LOGIC
        );
    end component;
    
    component Deco7seg is
        port(
            A       : in STD_LOGIC;
            B       : in STD_LOGIC;
            C       : in STD_LOGIC;
            D       : in STD_LOGIC;
            display : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;
    
    signal FF1_int, FF2_int : STD_LOGIC;
    signal unidades : STD_LOGIC_VECTOR(3 downto 0);
    signal decenas : STD_LOGIC_VECTOR(3 downto 0);
    
begin
    -- Flip flops D que procesan señales sensor1 y sensor2 (invierten la señal entrante)
    FF1: flip_flop_D port map(D => not sensor1, clk => clk, Q => FF1_int);
    FF2: flip_flop_D port map(D => not sensor2, clk => clk, Q => FF2_int);
    
    -- Asignar las señales internas a las salidas para uso externo
    FF1_Q <= FF1_int;
    FF2_Q <= FF2_int;
    
    -- Lógica original para decenas y unidades según combinación de FF1_int y FF2_int
    process(FF1_int, FF2_int)
    begin
        if (FF1_int = '1' and FF2_int = '1') then
            decenas <= "0001";  -- 1
            unidades <= "0000"; -- 0
        elsif (FF1_int = '1' or FF2_int = '1') then
            decenas <= "0000";  -- 0
            unidades <= "0101"; -- 5
        else
            decenas <= "0000";  -- 0
            unidades <= "0000"; -- 0
        end if;
    end process;
    
    -- Instancias decodificador para displays
    DisplayDriver1: Deco7seg
        port map(A => decenas(3), B => decenas(2), C => decenas(1), D => decenas(0), display => display1);
        
    DisplayDriver2: Deco7seg
        port map(A => unidades(3), B => unidades(2), C => unidades(1), D => unidades(0), display => display2);
        
end Structural;