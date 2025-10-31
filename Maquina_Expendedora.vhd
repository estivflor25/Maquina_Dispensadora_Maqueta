library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Maquina_Expendedora is
    Port (
        clk              : in  std_logic;
        reset            : in  std_logic;
        sensor1_raw      : in  std_logic;
        sensor2_raw      : in  std_logic;
        filas            : in  std_logic_vector(3 downto 0);
        columnas         : out std_logic_vector(3 downto 0);
        compra_btn       : in  std_logic;
        seg_decenas      : out std_logic_vector(6 downto 0);
        seg_unidades     : out std_logic_vector(6 downto 0);
        pwm_servo_entrega1: out std_logic;  -- MODIFICADO: Servo producto 1
        pwm_servo_entrega2: out std_logic;  -- AGREGADO: Servo producto 2
        pwm_servo_puerta : out std_logic;
        producto_retirado: in  std_logic
    );
end Maquina_Expendedora;

architecture Behavioral of Maquina_Expendedora is

    component almacen_sensor is
        port (
            clk            : in  std_logic;
            sensor1_raw    : in  std_logic;
            sensor2_raw    : in  std_logic;
            reset          : in  std_logic;
            clear          : in  std_logic;
            seg_decenas    : out std_logic_vector(6 downto 0);
            seg_unidades   : out std_logic_vector(6 downto 0);
            decenas_bin    : out std_logic_vector(3 downto 0);
            unidades_bin   : out std_logic_vector(3 downto 0)
        );
    end component;

    component Test_Teclado_Producto is
        Port (
            clk            : in  std_logic;
            reset          : in  std_logic;
            filas          : in  std_logic_vector(3 downto 0);
            columnas       : out std_logic_vector(3 downto 0);
            display_decena : out std_logic_vector(6 downto 0);
            display_unidad : out std_logic_vector(6 downto 0);
            stock_led      : out std_logic;
            led_valido     : out std_logic;
            selected_num   : out std_logic_vector(3 downto 0);
            compra_btn     : in  std_logic;
            precio_out     : out integer range 0 to 99
        );
    end component;

    component mux4x4 is
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
    end component;

    component Restador_cambio is
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            confirmar    : in  std_logic;
            credito_cent : in  integer range 0 to 999;
            precio_cent  : in  integer range 0 to 99;
            cambio_out   : out integer range -999 to 999
        );
    end component;

    component servo_pwm is
        Port (
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
            enable   : in  STD_LOGIC;
            servo    : out STD_LOGIC;
            done     : out STD_LOGIC
        );
    end component;

    component Servo_Controller is
        Port (
            clk      : in  STD_LOGIC;
            reset    : in  STD_LOGIC;
            sw_left  : in  STD_LOGIC;
            sw_right : in  STD_LOGIC;
            pwm_out  : out STD_LOGIC
        );
    end component;

    -- Señales internas
    signal decenas_bin_sens, unidades_bin_sens : std_logic_vector(3 downto 0);
    signal credito_cent : integer range 0 to 999 := 0;
    signal precio_cent : integer range 0 to 99 := 0;
    signal precio_latch : integer range 0 to 99 := 0;
    signal clear_monedas : std_logic := '0';  -- AGREGADO: Señal para limpiar contador

    signal teclado_display_decena, teclado_display_unidad : std_logic_vector(6 downto 0);
    signal led_tecla_valida, stock_led_teclado : std_logic;
    signal selected_num_teclado : std_logic_vector(3 downto 0);

    signal monedas_seg_dec, monedas_seg_uni : std_logic_vector(6 downto 0);
    signal cambio_seg_dec, cambio_seg_uni : std_logic_vector(6 downto 0);
    signal error_seg_dec, error_seg_uni : std_logic_vector(6 downto 0);
    signal saldo_seg_dec, saldo_seg_uni : std_logic_vector(6 downto 0);

    signal cambio_cent : integer range -999 to 999 := 0;

    -- Sincronización del botón
    signal compra_btn_sync : std_logic := '0';
    signal compra_btn_pulse : std_logic := '0';
    signal compra_btn_prev : std_logic := '0';

    -- Control de servos
    signal enable_servo_entrega1 : std_logic := '0';
    signal servo_entrega1_done : std_logic := '0';
    signal enable_servo_entrega2 : std_logic := '0';
    signal servo_entrega2_done : std_logic := '0';
    signal servo_entrega_done : std_logic := '0';
    signal sw_left_puerta : std_logic := '0';
    signal sw_right_puerta : std_logic := '0';

    -- Temporizador de puerta (3 segundos a 50 MHz)
    signal contador_puerta : integer range 0 to 149_999_999 := 0;
    signal tiempo_puerta_ok : std_logic := '0';

    -- Temporizador de timeout en confirmación (10 segundos)
    signal contador_timeout : integer range 0 to 499_999_999 := 0;
    signal timeout_confirmacion : std_logic := '0';
    
    -- Temporizador para mostrar cambio (2 segundos)
    signal contador_mostrar_cambio : integer range 0 to 99_999_999 := 0;
    signal tiempo_cambio_ok : std_logic := '0';
    
    -- Temporizador para mostrar error (2 segundos) - NUEVO
    signal contador_mostrar_error : integer range 0 to 99_999_999 := 0;
    signal tiempo_error_ok : std_logic := '0';

    -- Máquina de estados
    type estado_type is (
        INGRESO_MONEDAS,
        SELECCION_PRODUCTO,
        CONFIRMACION,
        ERROR_SALDO,
        ENTREGA_360,
        MOSTRAR_CAMBIO,
        ABRIR_PUERTA,
        ESPERAR_RETIRO,
        CERRAR_PUERTA,
        REINICIO
    );
    signal estado, estado_next : estado_type := INGRESO_MONEDAS;

    signal sel_display : std_logic_vector(2 downto 0) := "000";
    signal confirmar_sig : std_logic;
    
    -- Señales para generar pulso de enable (MOVIDO AQUÍ)
    signal estado_prev : estado_type := INGRESO_MONEDAS;
    signal pulso_inicio_entrega : std_logic := '0';

    -- Función para convertir entero a 7 segmentos
    function int_to_7seg(digit : integer range 0 to 9) return std_logic_vector is
    begin
         case digit is
            when 0 => return not "1111110";
            when 1 => return not "0110000";
            when 2 => return  not "1101101";
            when 3 => return not "1111001";
            when 4 => return not "0110011";
            when 5 => return not "1011011";
            when 6 => return not "1011111";
            when 7 => return not "1110000";
            when 8 => return not "1111111";
            when 9 => return not "1111011";
            when others => return  not "0000000";
        end case;
    end function;

begin

    ------------------------------------------------------------------
    -- Sincronizador y detector de flanco del botón
    ------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            compra_btn_prev <= '0';
            compra_btn_sync <= '0';
            compra_btn_pulse <= '0';
        elsif rising_edge(clk) then
            compra_btn_sync <= compra_btn;
            compra_btn_prev <= compra_btn_sync;
            compra_btn_pulse <= compra_btn_sync and not compra_btn_prev;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Control de señal clear_monedas (AGREGADO)
    ------------------------------------------------------------------
    process(estado)
    begin
        if estado = REINICIO then
            clear_monedas <= '1';
        else
            clear_monedas <= '0';
        end if;
    end process;

    ------------------------------------------------------------------
    -- Señal confirmar
    ------------------------------------------------------------------
    confirmar_sig <= '1' when estado = CONFIRMACION else '0';

    ------------------------------------------------------------------
    -- Crédito en céntimos
    ------------------------------------------------------------------
    credito_cent <= to_integer(unsigned(decenas_bin_sens)) * 10 +
                    to_integer(unsigned(unidades_bin_sens));

    ------------------------------------------------------------------
    -- Instancia sensor de monedas (MODIFICADO: agregado clear)
    ------------------------------------------------------------------
    sensores_inst : almacen_sensor
        port map(
            clk            => clk,
            sensor1_raw    => sensor1_raw,
            sensor2_raw    => sensor2_raw,
            reset          => reset,
            clear          => clear_monedas,  -- AGREGADO
            seg_decenas    => monedas_seg_dec,
            seg_unidades   => monedas_seg_uni,
            decenas_bin    => decenas_bin_sens,
            unidades_bin   => unidades_bin_sens
        );

    ------------------------------------------------------------------
    -- Instancia teclado
    ------------------------------------------------------------------
    teclado_inst : Test_Teclado_Producto
        port map(
            clk            => clk,
            reset          => reset,
            filas          => filas,
            columnas       => columnas,
            display_decena => teclado_display_decena,
            display_unidad => teclado_display_unidad,
            stock_led      => stock_led_teclado,
            led_valido     => led_tecla_valida,
            selected_num   => selected_num_teclado,
            compra_btn     => compra_btn_sync,
            precio_out     => precio_cent
        );

    ------------------------------------------------------------------
    -- Latch del precio mejorado
    ------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            precio_latch <= 0;
        elsif rising_edge(clk) then
            if estado = SELECCION_PRODUCTO and led_tecla_valida = '1' then
                precio_latch <= precio_cent;
            elsif estado = REINICIO or estado = INGRESO_MONEDAS then
                precio_latch <= 0;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Restador de cambio
    ------------------------------------------------------------------
    restador_inst : Restador_cambio
        port map(
            clk          => clk,
            reset        => reset,
            confirmar    => confirmar_sig,
            credito_cent => credito_cent,
            precio_cent  => precio_latch,
            cambio_out   => cambio_cent
        );

    ------------------------------------------------------------------
    -- Conversión de cambio a 7 segmentos (usando función)
    -- Muestra "00" si cambio <= 0
    ------------------------------------------------------------------
    process(cambio_cent)
        variable cambio_abs : integer range 0 to 999;
    begin
        if cambio_cent <= 0 then
            cambio_seg_dec <= int_to_7seg(0);
            cambio_seg_uni <= int_to_7seg(0);
        else
            cambio_abs := abs(cambio_cent);
            cambio_seg_dec <= int_to_7seg(cambio_abs / 10);
            cambio_seg_uni <= int_to_7seg(cambio_abs mod 10);
        end if;
    end process;

    ------------------------------------------------------------------
    -- Displays de error (muestra "Er")
    ------------------------------------------------------------------
    error_seg_dec <= not "1111001";  -- E (corregido)
    error_seg_uni <= not "1111001";  -- E (corregido)

    ------------------------------------------------------------------
    -- Saldo restante a 7 segmentos (usando función)
    ------------------------------------------------------------------
    process(credito_cent, precio_latch)
        variable saldo : integer range 0 to 999;
    begin
        saldo := credito_cent - precio_latch;
        if saldo < 0 then 
            saldo := 0; 
        end if;
        saldo_seg_dec <= int_to_7seg(saldo / 10);
        saldo_seg_uni <= int_to_7seg(saldo mod 10);
    end process;

    ------------------------------------------------------------------
    -- Multiplexor de displays
    ------------------------------------------------------------------
    mux_inst : mux4x4
        port map(
            clk       => clk,
            reset     => reset,
            monedas_U => monedas_seg_uni,
            monedas_D => monedas_seg_dec,
            teclado_U => teclado_display_unidad,
            teclado_D => teclado_display_decena,
            cambio_U  => cambio_seg_uni,
            cambio_D  => cambio_seg_dec,
            error_U   => error_seg_uni,
            error_D   => error_seg_dec,
            saldo_U   => saldo_seg_uni,
            saldo_D   => saldo_seg_dec,
            sel       => sel_display,
            displayU  => seg_unidades,
            displayD  => seg_decenas,
            modo_out  => open
        );

    ------------------------------------------------------------------
    -- Detector de entrada al estado ENTREGA_360 (AGREGADO)
    ------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            estado_prev <= INGRESO_MONEDAS;
            pulso_inicio_entrega <= '0';
        elsif rising_edge(clk) then
            estado_prev <= estado;
            -- Genera pulso cuando entra a ENTREGA_360
            if estado = ENTREGA_360 and estado_prev /= ENTREGA_360 then
                pulso_inicio_entrega <= '1';
            else
                pulso_inicio_entrega <= '0';
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Control de servos (MODIFICADO: Usa pulso de inicio)
    ------------------------------------------------------------------
    process(pulso_inicio_entrega, selected_num_teclado, estado)
    begin
        enable_servo_entrega1 <= '0';
        enable_servo_entrega2 <= '0';
        sw_right_puerta       <= '0';
        sw_left_puerta        <= '0';

        -- Solo genera pulso al ENTRAR al estado ENTREGA_360
        if pulso_inicio_entrega = '1' then
            case selected_num_teclado is
                when "0001" =>  -- Producto 1
                    enable_servo_entrega1 <= '1';
                when "0010" =>  -- Producto 2
                    enable_servo_entrega2 <= '1';
                when others =>
                    enable_servo_entrega1 <= '1';
            end case;
        end if;

        -- Control de puerta
        if estado = ABRIR_PUERTA or estado = ESPERAR_RETIRO then
            sw_right_puerta <= '1';
        elsif estado = CERRAR_PUERTA then
            sw_left_puerta <= '1';
        end if;
    end process;

    -- Combina las señales done de ambos servos
    servo_entrega_done <= servo_entrega1_done or servo_entrega2_done;

    ------------------------------------------------------------------
    -- Temporizador puerta 3 segundos
    ------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            contador_puerta  <= 0;
            tiempo_puerta_ok <= '0';
        elsif rising_edge(clk) then
            if estado = ESPERAR_RETIRO then
                if producto_retirado = '1' then
                    contador_puerta  <= 0;
                    tiempo_puerta_ok <= '1';
                elsif contador_puerta >= 149_999_999 then
                    tiempo_puerta_ok <= '1';
                else
                    contador_puerta <= contador_puerta + 1;
                    tiempo_puerta_ok <= '0';
                end if;
            else
                contador_puerta  <= 0;
                tiempo_puerta_ok <= '0';
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Temporizador timeout confirmación 10 segundos
    ------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            contador_timeout <= 0;
            timeout_confirmacion <= '0';
        elsif rising_edge(clk) then
            if estado = CONFIRMACION then
                if contador_timeout >= 499_999_999 then
                    timeout_confirmacion <= '1';
                else
                    contador_timeout <= contador_timeout + 1;
                    timeout_confirmacion <= '0';
                end if;
            else
                contador_timeout <= 0;
                timeout_confirmacion <= '0';
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Temporizador para mostrar cambio 2 segundos
    ------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            contador_mostrar_cambio <= 0;
            tiempo_cambio_ok <= '0';
        elsif rising_edge(clk) then
            if estado = MOSTRAR_CAMBIO then
                if contador_mostrar_cambio >= 99_999_999 then
                    tiempo_cambio_ok <= '1';
                else
                    contador_mostrar_cambio <= contador_mostrar_cambio + 1;
                    tiempo_cambio_ok <= '0';
                end if;
            else
                contador_mostrar_cambio <= 0;
                tiempo_cambio_ok <= '0';
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Temporizador para mostrar error 2 segundos (NUEVO)
    ------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            contador_mostrar_error <= 0;
            tiempo_error_ok <= '0';
        elsif rising_edge(clk) then
            if estado = ERROR_SALDO then
                if contador_mostrar_error >= 99_999_999 then  -- 2 segundos
                    tiempo_error_ok <= '1';
                else
                    contador_mostrar_error <= contador_mostrar_error + 1;
                    tiempo_error_ok <= '0';
                end if;
            else
                contador_mostrar_error <= 0;
                tiempo_error_ok <= '0';
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- FSM síncrona
    ------------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            estado <= INGRESO_MONEDAS;
        elsif rising_edge(clk) then
            estado <= estado_next;
        end if;
    end process;

    ------------------------------------------------------------------
    -- FSM combinacional con selección de visualización (MODIFICADO)
    ------------------------------------------------------------------
    process(estado, credito_cent, precio_latch, led_tecla_valida,
            stock_led_teclado, compra_btn_pulse, servo_entrega_done,
            tiempo_puerta_ok, timeout_confirmacion, tiempo_cambio_ok, 
            cambio_cent, tiempo_error_ok)
    begin
        estado_next <= estado;

        case estado is
            when INGRESO_MONEDAS =>
                sel_display <= "000";  -- monedas
                -- Cambia cuando presiona una tecla del producto
                if led_tecla_valida = '1' then
                    estado_next <= SELECCION_PRODUCTO;
                end if;

            when SELECCION_PRODUCTO =>
                sel_display <= "000";  -- Sigue mostrando monedas
                -- CORREGIDO: Valida INMEDIATAMENTE después de capturar precio
                if precio_latch > 0 then
                    if credito_cent >= precio_latch and stock_led_teclado = '0' then
                        estado_next <= CONFIRMACION;
                    else
                        estado_next <= ERROR_SALDO;
                    end if;
                end if;

            when ERROR_SALDO =>
                sel_display <= "011";  -- error "Er"
                -- MODIFICADO: Vuelve automáticamente después de 2 segundos
                if tiempo_error_ok = '1' then
                    estado_next <= INGRESO_MONEDAS;
                -- O si presiona el botón antes
                elsif compra_btn_pulse = '1' then
                    estado_next <= INGRESO_MONEDAS;
                end if;

            when CONFIRMACION =>
                sel_display <= "001";  -- teclado (producto seleccionado)
                -- AGREGADO: Doble validación antes de confirmar compra
                if compra_btn_pulse = '1' then
                    if credito_cent >= precio_latch and stock_led_teclado = '0' then
                        estado_next <= ENTREGA_360;
                    else
                        estado_next <= ERROR_SALDO;
                    end if;
                elsif timeout_confirmacion = '1' then
                    estado_next <= INGRESO_MONEDAS;  -- Timeout vuelve a inicio
                end if;

            when ENTREGA_360 =>
                sel_display <= "010";  -- cambio
                if servo_entrega_done = '1' then
                    estado_next <= MOSTRAR_CAMBIO;
                end if;

            when MOSTRAR_CAMBIO =>
                sel_display <= "010";  -- cambio (o "00" si no hay)
                if tiempo_cambio_ok = '1' then
                    if cambio_cent > 0 then
                        estado_next <= ABRIR_PUERTA;
                    else
                        estado_next <= REINICIO;
                    end if;
                end if;

            when ABRIR_PUERTA =>
                sel_display <= "010";  -- cambio
                estado_next <= ESPERAR_RETIRO;

            when ESPERAR_RETIRO =>
                sel_display <= "010";  -- cambio
                if tiempo_puerta_ok = '1' then
                    estado_next <= CERRAR_PUERTA;
                end if;

            when CERRAR_PUERTA =>
                sel_display <= "010";  -- sigue mostrando cambio
                estado_next <= REINICIO;

            when REINICIO =>
                sel_display <= "000";  -- monedas (se limpiará a "00")
                estado_next <= INGRESO_MONEDAS;

            when others =>
                estado_next <= INGRESO_MONEDAS;

        end case;
    end process;

    ------------------------------------------------------------------
    -- Instancia Servo ENTREGA 1 (360° - Producto 1)
    ------------------------------------------------------------------
    servo_entrega1_inst : servo_pwm
        port map(
            clk      => clk,
            reset    => reset,
            enable   => enable_servo_entrega1,
            servo    => pwm_servo_entrega1,
            done     => servo_entrega1_done
        );

    ------------------------------------------------------------------
    -- Instancia Servo ENTREGA 2 (360° - Producto 2)
    ------------------------------------------------------------------
    servo_entrega2_inst : servo_pwm
        port map(
            clk      => clk,
            reset    => reset,
            enable   => enable_servo_entrega2,
            servo    => pwm_servo_entrega2,
            done     => servo_entrega2_done
        );

    ------------------------------------------------------------------
    -- Instancia Servo PUERTA (90°)
    ------------------------------------------------------------------
    servo_puerta_inst : Servo_Controller
        port map(
            clk      => clk,
            reset    => reset,
            sw_left  => sw_left_puerta,
            sw_right => sw_right_puerta,
            pwm_out  => pwm_servo_puerta
        );

end Behavioral;