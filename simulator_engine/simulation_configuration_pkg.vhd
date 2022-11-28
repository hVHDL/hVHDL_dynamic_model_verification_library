library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package simulation_configuration_pkg is

    constant simulation_time_step : real    := 0.3e-6;
    constant max_voltage          : real    := 50.0;
    constant integrator_radix     : integer := 15;

end package simulation_configuration_pkg;
