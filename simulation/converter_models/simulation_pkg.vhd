library ieee;
    use ieee.std_logic_1164.all;

    use work.multiplier_pkg.all;

package simulation_pkg is

    constant number_of_calculation_cycles : integer := 3000;
    constant stoptime             : real := 10.0e-3;
    constant simulation_time_step : real := stoptime/3000.0;

    constant max_voltage         : real    := 1500.0;
    constant word_length_in_bits : integer := int_word_length;
    constant word_length         : integer := word_length_in_bits-1;
    --
    constant voltage_transform_ratio   : real := (max_voltage/2.0**word_length);
    constant real_to_int_voltage_ratio : real := (2.0**word_length/max_voltage);

    constant integrator_radix     : integer := 15;
    constant integrator_gain      : real := 2.0**integrator_radix;

    function real_voltage ( integer_voltage : integer)
        return real;

    function int_voltage ( real_volts : real)
        return integer;

    function capacitance_is ( capacitance_value : real)
        return integer;

    function inductance_is ( inductor_value : real)
        return integer;

    function resistance_is ( resistance : real)
        return integer;

    function resistance_is ( resistance : integer)
        return integer;

    function int_current ( real_current : real)
        return integer;

end package simulation_pkg;

package body simulation_pkg is

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
        return integer(1.0/capacitance_value*simulation_time_step*integrator_gain);
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

