library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity servo_clasificador_180 is
    Port (
        clk           : in  STD_LOGIC;
        reset         : in  STD_LOGIC;
        sensor1       : in  STD_LOGIC;  -- Sensor 1
        sensor2       : in  STD_LOGIC;  -- Sensor 2
        servo_pwm     : out STD_LOGIC;
        clasificando  : out STD_LOGIC
    );
end servo_clasificador_180;

architecture Behavioral of servo_clasificador_180 is
    constant CLK_FREQ     : integer := 50000000;  -- 50 MHz
    constant PWM_FREQ     : integer := 50;        -- 50 Hz
    constant PERIOD_COUNT : integer := CLK_FREQ / PWM_FREQ;
    
    -- Posiciones del servo (ancho de pulso en ciclos de reloj)
    constant POS_CENTRO   : integer := (CLK_FREQ * 15) / 10000;  -- 1.5 ms (90°)
    constant POS_IZQ      : integer := (CLK_FREQ * 10) / 10000;  -- 1.0 ms (0°)
    constant POS_DER      : integer := (CLK_FREQ * 20) / 10000;  -- 2.0 ms (180°)
    
    -- Tiempos de movimiento
    constant TIEMPO_GIRO  : integer := 25_000_000;  -- 0.5 segundos
    constant TIEMPO_PAUSA : integer := 25_000_000;  -- 0.5 segundos
    
    signal counter      : integer range 0 to PERIOD_COUNT := 0;
    signal pulse_width  : integer := POS_CENTRO;
    signal time_counter : integer range 0 to TIEMPO_GIRO + TIEMPO_PAUSA := 0;
    
    -- Máquina de estados
    type estado_clasificador is (
        REPOSO,
        GIRAR_IZQ,
        PAUSA_IZQ,
        VOLVER_IZQ,
        GIRAR_DER,
        PAUSA_DER,
        VOLVER_DER
    );
    signal estado : estado_clasificador := REPOSO;
    
    -- Detección de monedas
    signal sensor1_prev, sensor2_prev : std_logic := '0';
    signal detectar_moneda_500  : std_logic := '0';
    signal detectar_moneda_1000 : std_logic := '0';

begin

    -- Detector de tipo de moneda
    process(clk, reset)
    begin
        if reset = '1' then
            sensor1_prev <= '0';
            sensor2_prev <= '0';
            detectar_moneda_500 <= '0';
            detectar_moneda_1000 <= '0';
        elsif rising_edge(clk) then
            sensor1_prev <= sensor1;
            sensor2_prev <= sensor2;
            
            -- Detecta flanco ascendente
            if (sensor1 = '1' and sensor1_prev = '0') or (sensor2 = '1' and sensor2_prev = '0') then
                -- Moneda de 1000: Ambos sensores activos simultáneamente
                if sensor1 = '1' and sensor2 = '1' then
                    detectar_moneda_1000 <= '1';
                    detectar_moneda_500 <= '0';
                -- Moneda de 500: Solo un sensor activo
                else
                    detectar_moneda_500 <= '1';
                    detectar_moneda_1000 <= '0';
                end if;
            else
                detectar_moneda_500 <= '0';
                detectar_moneda_1000 <= '0';
            end if;
        end if;
    end process;

    -- Generador PWM 50 Hz
    process(clk, reset)
    begin
        if reset = '1' then
            counter <= 0;
        elsif rising_edge(clk) then
            if counter < PERIOD_COUNT - 1 then
                counter <= counter + 1;
            else
                counter <= 0;
            end if;
            
            if counter < pulse_width then
                servo_pwm <= '1';
            else
                servo_pwm <= '0';
            end if;
        end if;
    end process;

    -- Máquina de estados del clasificador
    process(clk, reset)
    begin
        if reset = '1' then
            estado <= REPOSO;
            pulse_width <= POS_CENTRO;
            time_counter <= 0;
            clasificando <= '0';
            
        elsif rising_edge(clk) then
            case estado is
                when REPOSO =>
                    pulse_width <= POS_CENTRO;
                    time_counter <= 0;
                    clasificando <= '0';
                    
                    -- Detecta moneda de 500 (gira a la izquierda)
                    if detectar_moneda_500 = '1' then
                        estado <= GIRAR_IZQ;
                        clasificando <= '1';
                    -- Detecta moneda de 1000 (gira a la derecha)
                    elsif detectar_moneda_1000 = '1' then
                        estado <= GIRAR_DER;
                        clasificando <= '1';
                    end if;
                
                -- ===== SECUENCIA PARA MONEDA DE 500 (IZQUIERDA) =====
                when GIRAR_IZQ =>
                    pulse_width <= POS_IZQ;
                    clasificando <= '1';
                    
                    if time_counter < TIEMPO_GIRO then
                        time_counter <= time_counter + 1;
                    else
                        time_counter <= 0;
                        estado <= PAUSA_IZQ;
                    end if;
                
                when PAUSA_IZQ =>
                    pulse_width <= POS_IZQ;
                    clasificando <= '1';
                    
                    if time_counter < TIEMPO_PAUSA then
                        time_counter <= time_counter + 1;
                    else
                        time_counter <= 0;
                        estado <= VOLVER_IZQ;
                    end if;
                
                when VOLVER_IZQ =>
                    pulse_width <= POS_CENTRO;
                    clasificando <= '1';
                    
                    if time_counter < TIEMPO_GIRO then
                        time_counter <= time_counter + 1;
                    else
                        time_counter <= 0;
                        estado <= REPOSO;
                    end if;
                
                -- ===== SECUENCIA PARA MONEDA DE 1000 (DERECHA) =====
                when GIRAR_DER =>
                    pulse_width <= POS_DER;
                    clasificando <= '1';
                    
                    if time_counter < TIEMPO_GIRO then
                        time_counter <= time_counter + 1;
                    else
                        time_counter <= 0;
                        estado <= PAUSA_DER;
                    end if;
                
                when PAUSA_DER =>
                    pulse_width <= POS_DER;
                    clasificando <= '1';
                    
                    if time_counter < TIEMPO_PAUSA then
                        time_counter <= time_counter + 1;
                    else
                        time_counter <= 0;
                        estado <= VOLVER_DER;
                    end if;
                
                when VOLVER_DER =>
                    pulse_width <= POS_CENTRO;
                    clasificando <= '1';
                    
                    if time_counter < TIEMPO_GIRO then
                        time_counter <= time_counter + 1;
                    else
                        time_counter <= 0;
                        estado <= REPOSO;
                    end if;
                
                when others =>
                    estado <= REPOSO;
                    
            end case;
        end if;
    end process;

end Behavioral;