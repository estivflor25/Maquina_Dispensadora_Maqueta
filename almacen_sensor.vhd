library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity almacen_sensor is
    port (
        clk           : in std_logic;
        sensor1_raw   : in std_logic;
        sensor2_raw   : in std_logic;
        reset         : in std_logic;
        clear         : in std_logic;  -- AGREGADO: Limpia el contador
        seg_decenas   : out std_logic_vector(6 downto 0);
        seg_unidades  : out std_logic_vector(6 downto 0);
        sensor1_active : out std_logic;
        sensor2_active : out std_logic;
        
        -- NUEVAS salidas para los bits BCD de decenas y unidades
        decenas_bin   : out std_logic_vector(3 downto 0);
        unidades_bin  : out std_logic_vector(3 downto 0)
    );
end entity;

architecture top_arch of almacen_sensor is

    component sistema_sensores is
        Port(
            sensor1  : in std_logic;
            sensor2  : in std_logic;
            clk      : in std_logic;
            display1 : out std_logic_vector(6 downto 0);
            display2 : out std_logic_vector(6 downto 0);
            FF1_Q    : out std_logic;
            FF2_Q    : out std_logic
        );
    end component;

    component Deco7seg is
        port(
            A       : in std_logic;
            B       : in std_logic;
            C       : in std_logic;
            D       : in std_logic;
            display : out std_logic_vector(6 downto 0)
        );
    end component;

    signal input_sensor1 : std_logic;
    signal input_sensor2 : std_logic;
    
    signal display1_temp : std_logic_vector(6 downto 0);
    signal display2_temp : std_logic_vector(6 downto 0);

    signal deb_count1 : integer range 0 to 50000 := 0; 
    signal deb_count2 : integer range 0 to 50000 := 0; 

    signal sensor1_ff : std_logic := '0';
    signal sensor2_ff : std_logic := '0';

    signal contador : integer range 0 to 99 := 0;
    signal sensor1_ant, sensor2_ant : std_logic := '0';

    constant VALOR_SOLO_UNO : integer := 5;
    constant VALOR_AMBOS    : integer := 10;

    signal decenas_bin_int  : std_logic_vector(3 downto 0);
    signal unidades_bin_int : std_logic_vector(3 downto 0);

begin

    U_sistema_sensores: sistema_sensores
        port map(
            sensor1  => sensor1_raw,
            sensor2  => sensor2_raw,
            clk      => clk,
            display1 => display1_temp,
            display2 => display2_temp,
            FF1_Q    => input_sensor1,
            FF2_Q    => input_sensor2
        );

    process(clk)
    begin
        if rising_edge(clk) then
            if input_sensor1 = '1' then
                if deb_count1 < 50000 then
                    deb_count1 <= deb_count1 + 1;
                end if;
            else
                deb_count1 <= 0;
            end if;

            if deb_count1 = 50000 then
                sensor1_ff <= '1';
            else
                sensor1_ff <= '0';
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if input_sensor2 = '1' then
                if deb_count2 < 50000 then
                    deb_count2 <= deb_count2 + 1;
                end if;
            else
                deb_count2 <= 0;
            end if;

            if deb_count2 = 50000 then
                sensor2_ff <= '1';
            else
                sensor2_ff <= '0';
            end if;
        end if;
    end process;

    -- MODIFICADO: Agregada lógica de clear
    process(clk)
        variable siguiente : integer;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                contador <= 0;
                sensor1_ant <= '0';
                sensor2_ant <= '0';
            elsif clear = '1' then  -- AGREGADO
                contador <= 0;      -- AGREGADO
                sensor1_ant <= '0'; -- AGREGADO
                sensor2_ant <= '0'; -- AGREGADO
            else
                siguiente := contador;
                if (sensor1_ff = '1' and sensor1_ant = '0') and (sensor2_ff = '1' and sensor2_ant = '0') then
                    siguiente := siguiente + VALOR_AMBOS;
                elsif (sensor1_ff = '1' and sensor1_ant = '0') then
                    siguiente := siguiente + VALOR_SOLO_UNO;
                elsif (sensor2_ff = '1' and sensor2_ant = '0') then
                    siguiente := siguiente + VALOR_SOLO_UNO;
                end if;
                contador <= siguiente mod 100;
                sensor1_ant <= sensor1_ff;
                sensor2_ant <= sensor2_ff;
            end if;
        end if;
    end process;

    decenas_bin_int  <= std_logic_vector(to_unsigned(contador / 10, 4));
    unidades_bin_int <= std_logic_vector(to_unsigned(contador mod 10, 4));

    dec_d: Deco7seg
        port map(
            A => decenas_bin_int(3),
            B => decenas_bin_int(2),
            C => decenas_bin_int(1),
            D => decenas_bin_int(0),
            display => seg_decenas
        );

    dec_u: Deco7seg
        port map(
            A => unidades_bin_int(3),
            B => unidades_bin_int(2),
            C => unidades_bin_int(1),
            D => unidades_bin_int(0),
            display => seg_unidades
        );
    
    -- Asignar salidas para control de servo
    sensor1_active <= sensor1_ff;
    sensor2_active <= sensor2_ff;

    -- Salidas de decenas_bin y unidades_bin para módulo externo
    decenas_bin <= decenas_bin_int;
    unidades_bin <= unidades_bin_int;

end architecture;