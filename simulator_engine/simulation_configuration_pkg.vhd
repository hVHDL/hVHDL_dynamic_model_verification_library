library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_base_types_pkg.all;

package simulation_configuration_pkg is

    constant simulation_time_step : real    := 0.3e-6;
    constant integrator_radix     : integer := number_of_input_bits-3;
    constant applied_scaling      : real    := 150.0;

    constant max_voltage          : real    := applied_scaling;

end package simulation_configuration_pkg;
