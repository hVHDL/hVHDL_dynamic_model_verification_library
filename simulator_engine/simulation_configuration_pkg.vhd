library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_pkg.all;

package simulation_configuration_pkg is

    constant simulation_time_step : real := 1.0e-6;

    constant max_voltage         : real    := 50.0;
    constant word_length         : integer := int_word_length-1;
    --
    constant voltage_transform_ratio   : real := (max_voltage/2.0**word_length);
    constant real_to_int_voltage_ratio : real := (2.0**word_length/max_voltage);

    constant integrator_radix     : integer := 15;
    constant integrator_gain      : real := 2.0**integrator_radix;

end package simulation_configuration_pkg;
