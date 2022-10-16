library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_pkg.all;

package simulation_configuration_pkg is

    constant number_of_calculation_cycles : real := 3000.0;
    constant stoptime_in_seconds          : real := 10.0e-3;
    constant simulation_time_step         : real := stoptime_in_seconds/number_of_calculation_cycles;

    constant max_voltage         : real    := 1500.0;
    constant word_length_in_bits : integer := int_word_length;
    constant word_length         : integer := word_length_in_bits-1;
    --
    constant voltage_transform_ratio   : real := (max_voltage/2.0**word_length);
    constant real_to_int_voltage_ratio : real := (2.0**word_length/max_voltage);

    constant integrator_radix     : integer := 15;
    constant integrator_gain      : real := 2.0**integrator_radix;

end package simulation_configuration_pkg;
