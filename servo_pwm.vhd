library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity servo_pwm is
    Port (
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        enable   : in  STD_LOGIC;
        servo    : out STD_LOGIC;
        done     : out STD_LOGIC
    );
end servo_pwm;

architecture Behavioral of servo_pwm is
    constant CLK_FREQ     : integer := 50000000;
    constant PWM_FREQ     : integer := 50;
    constant PERIOD_COUNT : integer := CLK_FREQ / PWM_FREQ;
    constant PULSE_FWD    : integer := (CLK_FREQ * 1) / 1000;   -- 1 ms (rotación)
    constant PULSE_STOP   : integer := (CLK_FREQ * 15) / 10000; -- 1.5 ms (parado)
    constant TURN_TIME    : integer := 115_000_000;             -- 2.30 s (2 vueltas)
    
    signal counter      : integer range 0 to PERIOD_COUNT := 0;
    signal pulse        : integer := PULSE_STOP;
    signal time_counter : integer range 0 to TURN_TIME := 0;
    signal done_i       : STD_LOGIC := '0';
    signal running      : STD_LOGIC := '0';
    
    -- Sincronizador de enable para detectar flancos
    signal enable_prev  : STD_LOGIC := '0';
    signal enable_pulse : STD_LOGIC := '0';

begin
    done <= done_i;

    -- Detector de flanco de enable
    process(clk, reset)
    begin
        if reset = '1' then
            enable_prev <= '0';
            enable_pulse <= '0';
        elsif rising_edge(clk) then
            enable_prev <= enable;
            enable_pulse <= enable and not enable_prev;
        end if;
    end process;

    -- Control principal del servo
    process(clk, reset)
    begin
        if reset = '1' then
            counter      <= 0;
            pulse        <= PULSE_STOP;
            time_counter <= 0;
            done_i       <= '0';
            running      <= '0';
            
        elsif rising_edge(clk) then
            -- Generador PWM 50 Hz (siempre activo)
            if counter < PERIOD_COUNT - 1 then
                counter <= counter + 1;
            else
                counter <= 0;
            end if;
            
            if counter < pulse then
                servo <= '1';
            else
                servo <= '0';
            end if;
            
            -- Máquina de estados del movimiento
            if enable_pulse = '1' and running = '0' then
                -- Inicio del movimiento
                running      <= '1';
                done_i       <= '0';
                time_counter <= 0;
                pulse        <= PULSE_FWD;
                
            elsif running = '1' then
                -- En movimiento
                if time_counter < TURN_TIME - 1 then
                    time_counter <= time_counter + 1;
                    pulse        <= PULSE_FWD;
                else
                    -- Fin del movimiento
                    pulse        <= PULSE_STOP;
                    done_i       <= '1';
                    running      <= '0';
                end if;
            else
                -- Estado de reposo
                pulse   <= PULSE_STOP;
                done_i  <= '0';
            end if;
        end if;
    end process;

end Behavioral;