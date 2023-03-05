library ieee;
    use ieee.std_logic_1164.all;
    use ieee.math_real.all;
    use std.textio.all;
    use ieee.numeric_std.all;

    use work.multiplier_pkg.int_word_length;
    use work.simulation_configuration_pkg.all;

package simulation_pkg is

    -- publish configurations from configuration package
    alias simulation_time_step is simulation_time_step;

    type real_array is array (integer range <>) of real;

    function real_voltage ( integer_voltage : integer)
        return real;

    function int_voltage ( real_volts : real)
        return integer;

    function int_current ( real_current : real)
        return integer;

    function inductance_is ( inductor_value : real)
        return integer;

    function capacitance_is ( capacitance_value : real)
        return integer;

    function resistance_is ( resistance : real)
        return integer;
    function resistance_is ( resistance : integer)
        return integer;

end package simulation_pkg;

package body simulation_pkg is

    constant word_length               : integer := int_word_length-1;
    constant voltage_transform_ratio   : real := max_voltage/2.0**word_length;
    constant real_to_int_voltage_ratio : real := 2.0**word_length/max_voltage;
    constant integrator_gain           : real := 2.0**work.simulation_configuration_pkg.integrator_radix;

    ----
    function real_voltage
    (
        integer_voltage : integer
    )
    return real is
    begin

        return real(integer_voltage) * voltage_transform_ratio;
    end real_voltage;

    ----
    function int_voltage
    (
        real_volts : real
    )
    return integer is
    begin
        return integer(real_volts*real_to_int_voltage_ratio);
    end int_voltage;

    function int_current
    (
        real_current : real
    )
    return integer is
    begin
        return integer(real_current*real_to_int_voltage_ratio);
    end int_current;

    ----
    function capacitance_is
    (
        capacitance_value : real
    )
    return integer
    is
    begin
        return integer(simulation_time_step*integrator_gain/capacitance_value);
    end capacitance_is;
    ----
    function inductance_is
    (
        inductor_value : real
    )
    return integer
    is
    begin
        return capacitance_is(inductor_value);
    end inductance_is;
    ----
    function resistance_is
    (
        resistance : real
    )
    return integer
    is
    begin
        return integer(resistance * integrator_gain);
    end resistance_is;

    function resistance_is
    (
        resistance : integer
    )
    return integer
    is
    begin
        return resistance_is(real(resistance));
    end resistance_is;
    ----
end package body simulation_pkg;
