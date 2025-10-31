library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Test_Teclado_Producto is
    Port (
        clk            : in  STD_LOGIC;
        reset          : in  STD_LOGIC;
        filas          : in  STD_LOGIC_VECTOR(3 downto 0);
        columnas       : out STD_LOGIC_VECTOR(3 downto 0);
        display_decena : out STD_LOGIC_VECTOR(6 downto 0);
        display_unidad : out STD_LOGIC_VECTOR(6 downto 0);
        stock_led      : out STD_LOGIC;
        led_valido     : out STD_LOGIC;
        selected_num   : out STD_LOGIC_VECTOR(3 downto 0);
        compra_btn     : in  STD_LOGIC;
        precio_out     : out integer range 0 to 99  -- <-- NUEVO
    );
end Test_Teclado_Producto;

architecture Behavioral of Test_Teclado_Producto is

    -- Señales internas
    signal tecla_valida       : std_logic := '0';
    signal producto_sel_int   : unsigned(3 downto 0) := (others => '0');
    signal stock_ok_sig       : std_logic := '1';
    signal stock_count_sig    : integer range 0 to 255 := 0;
    signal precio_sig         : integer range 0 to 9500 := 0;

    signal selected_num_sig   : std_logic_vector(3 downto 0) := (others => '0');

    signal compra_btn_sync_0  : std_logic := '0';
    signal compra_btn_sync_1  : std_logic := '0';
    signal compra_btn_rising  : std_logic := '0';

    signal displayU_int : std_logic_vector(6 downto 0);
    signal displayD_int : std_logic_vector(6 downto 0);

    component Test_Teclado is
        port(
            clk          : in  std_logic;
            filas        : in  std_logic_vector(3 downto 0);
            columnas     : out std_logic_vector(3 downto 0);
            displayU     : out std_logic_vector(6 downto 0);
            displayD     : out std_logic_vector(6 downto 0);
            led_valido   : out std_logic;
            selected_num : out std_logic_vector(3 downto 0)
        );
    end component;

    component Producto is
        port (
            clk             : in  std_logic;
            reset           : in  std_logic;
            producto_sel    : in  unsigned(3 downto 0);
            decrementar     : in  std_logic;
            stock_ok        : out std_logic;
            stock_count     : out integer range 0 to 255;
            precio_producto : out integer range 0 to 9500
        );
    end component;

begin

    -- Instancia teclado
    U0_Teclado: Test_Teclado
        port map(
            clk          => clk,
            filas        => filas,
            columnas     => columnas,
            displayU     => displayU_int,
            displayD     => displayD_int,
            led_valido   => tecla_valida,
            selected_num => selected_num_sig
        );

    display_unidad <= displayU_int;
    display_decena <= displayD_int;
    led_valido     <= tecla_valida;
    selected_num   <= selected_num_sig;

    -- Sincronizador y detector de flanco
    process(clk)
    begin
        if rising_edge(clk) then
            compra_btn_sync_0 <= compra_btn;
            compra_btn_sync_1 <= compra_btn_sync_0;
            compra_btn_rising <= compra_btn_sync_0 and not compra_btn_sync_1;
        end if;
    end process;

    -- Instancia Producto
    U1_Producto: Producto
        port map(
            clk             => clk,
            reset           => reset,
            producto_sel    => producto_sel_int,
            decrementar     => compra_btn_rising,
            stock_ok        => stock_ok_sig,
            stock_count     => stock_count_sig,
            precio_producto => precio_sig
        );

    -- Asignación de precio a la salida (escalado a 0–99)
    precio_out <= precio_sig / 100 when precio_sig <= 9500 else 99;

    -- Indicador de stock
    stock_led <= not stock_ok_sig;

    -- Registro de producto seleccionado
    process(clk)
    begin
        if rising_edge(clk) then
            if tecla_valida = '1' then
                producto_sel_int <= unsigned(selected_num_sig);
            end if;
        end if;
    end process;

end Behavioral;