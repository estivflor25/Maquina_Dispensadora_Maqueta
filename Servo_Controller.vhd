library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Servo_Controller is
  Port (
    clk       : in  STD_LOGIC;       -- Clock 50 MHz
    reset     : in  STD_LOGIC;       -- Reset síncrono
    sw_left   : in  STD_LOGIC;       -- Switch mover a izquierda
    sw_right  : in  STD_LOGIC;       -- Switch mover a derecha
    pwm_out   : out STD_LOGIC        -- Señal PWM para servo
  );
end Servo_Controller;

architecture Behavioral of Servo_Controller is

  constant CLOCK_FREQ        : integer := 50000000; -- 50 MHz
  constant PWM_PERIOD_MS     : integer := 20;       -- Periodo PWM 20 ms
  constant PWM_PERIOD_COUNT  : integer := CLOCK_FREQ / 1000 * PWM_PERIOD_MS; -- 1,000,000
  
  type pulse_array is array (0 to 4) of integer;
  constant PULSE_WIDTH_US    : pulse_array := (1000, 1250, 1500, 1750, 2000); -- pulso para 0°, 45°, 90°, 135°, 180°
  
  signal count              : integer range 0 to PWM_PERIOD_COUNT := 0;
  signal pulse_width_calc   : integer := 0;
  
  signal angle_index        : integer range 0 to 4 := 2; -- Posición inicial 90°

begin

  -- Control de ángulo basado en switches y reset
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        angle_index <= 2; -- volver a posición central 90°
      else
        if sw_right = '1' then
          if angle_index < 4 then
            angle_index <= angle_index + 1;
          end if;
        elsif sw_left = '1' then
          if angle_index > 0 then
            angle_index <= angle_index - 1;
          end if;
        else
          angle_index <= 2; -- si ambos switches 0, regresamos a 90°
        end if;
      end if;
    end if;
  end process;

  -- Convertir ángulo a ancho de pulso en cuentas de reloj
  pulse_width_calc <= (PULSE_WIDTH_US(angle_index) * (CLOCK_FREQ / 1000000));

  -- Generador PWM para la señal del servo
  process(clk)
  begin
    if rising_edge(clk) then
      if count < PWM_PERIOD_COUNT then
        count <= count + 1;
      else
        count <= 0;
      end if;

      if count < pulse_width_calc then
        pwm_out <= '1';
      else
        pwm_out <= '0';
      end if;
    end if;
  end process;

end Behavioral;
