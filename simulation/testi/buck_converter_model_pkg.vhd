library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

package buck_converter_model_pkg is

    type buck_converter_record is record
        current                 : real ;
        voltage                 : real ;
        dc_link_voltage         : real ;
        current_integrator_gain : real ;
        voltage_integrator_gain : real ;
        load_resistance         : real ;
    end record;

    procedure create_buck_converter (
        signal buck_converter_object : inout buck_converter_record;
        dc_link_voltage : in real;
        pwm : in std_logic);
------------------------------------------------------------------------
    function get_voltage ( buck_converter_object : buck_converter_record)
        return real;
------------------------------------------------------------------------
    function get_current ( buck_converter_object : buck_converter_record)
        return real;
------------------------------------------------------------------------
    function init_buck_converter (
        inductance                      : real;
        capacitance                     : real;
        simulation_time_step_in_seconds : real)
    return buck_converter_record;
------------------------------------------------------------------------

end package buck_converter_model_pkg;


package body buck_converter_model_pkg is

    function init_buck_converter
    (
        inductance : real;
        capacitance : real;
        simulation_time_step_in_seconds : real
    )
    return buck_converter_record
    is
        constant init_buck_converter : buck_converter_record := ( 0.0 , 0.0 , 100.0 , simulation_time_step_in_seconds/inductance , simulation_time_step_in_seconds/capacitance , 10.0);
    begin
        return init_buck_converter;
    end init_buck_converter;
------------------------------------------------------------------------
    procedure create_buck_converter
    (
        signal buck_converter_object : inout buck_converter_record;
        dc_link_voltage : in real;
        pwm : in std_logic
    ) is
        alias m is buck_converter_object;
    begin
        if pwm = '1' then
            m.current <= m.current + (dc_link_voltage - m.voltage)*m.current_integrator_gain;
        else
            m.current <= m.current - m.voltage*m.current_integrator_gain;
        end if;

        m.voltage <= m.voltage + (m.current - m.voltage/m.load_resistance)*m.voltage_integrator_gain;
        
    end create_buck_converter;

    function get_voltage
    (
        buck_converter_object : buck_converter_record
    )
    return real
    is
    begin
        return buck_converter_object.voltage;
    end get_voltage;

    function get_current
    (
        buck_converter_object : buck_converter_record
    )
    return real
    is
    begin
        return buck_converter_object.current;
    end get_current;

end package body buck_converter_model_pkg;
