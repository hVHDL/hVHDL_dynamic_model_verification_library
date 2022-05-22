library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_pkg.all;
    use work.state_variable_pkg.all;
    use work.lcr_filter_model_pkg.all;

package inverter_model_pkg is

    type inverter_model_record is record
        inverter_multiplier : multiplier_record;
        inverter_lc_filter  : lcr_model_record;
        dc_link_voltage     : state_variable_record;

        duty_ratio                  : int;
        dc_link_current             : int;
        load_current                : int;
        load_resistor_current       : int;
        input_voltage               : int;
        grid_inverter_state_counter : natural range 0 to 7;
    end record;

    constant init_inverter_model : inverter_model_record := (multiplier_init_values, init_lcr_model_integrator_gains(5e3, 1000), init_state_variable_gain(500), 0, 0, 0, 0, 0, 4);

------------------------------------------------------------------------
    function init_inverter_state_variable_gains (
            inductor_integrator_gain     : int;
            ac_capacitor_integrator_gain : int;
            dc_link_integrator_gain      : int)
        return inverter_model_record;
------------------------------------------------------------------------
    function init_inverter_state_and_gains (
            dc_link_voltage_init         : int;
            inductor_integrator_gain     : int;
            ac_capacitor_integrator_gain : int;
            dc_link_integrator_gain      : int)
        return inverter_model_record;
------------------------------------------------------------------------
    function get_inverter_inductor_current ( inverter_model : inverter_model_record)
        return int;
------------------------------------------------------------------------
    procedure set_dc_link_voltage (
        signal inverter_model : out inverter_model_record;
        set_value_for_dc_link : int);
------------------------------------------------------------------------
    function get_dc_link_voltage ( inverter_model : inverter_model_record)
        return int;
------------------------------------------------------------------------
    function get_inverter_capacitor_voltage ( inverter_model : inverter_model_record)
        return int;
------------------------------------------------------------------------
    procedure create_inverter_model (
        signal inverter_model : inout inverter_model_record;
        dc_link_load_current : in int;
        load_current : in int);
------------------------------------------------------------------------
    procedure request_inverter_calculation (
        signal inverter_model : out inverter_model_record;
        duty_ratio : in int);

------------------------------------------------------------------------
end package inverter_model_pkg;

package body inverter_model_pkg is

------------------------------------------------------------------------
    procedure create_inverter_model
    (
        signal inverter_model : inout inverter_model_record;
        dc_link_load_current : in int;
        load_current : in int
    ) is
        alias inverter_multiplier is inverter_model.inverter_multiplier;
        alias dc_link_voltage is inverter_model.dc_link_voltage;
        alias dc_link_current is inverter_model.dc_link_current;
        alias inverter_lc_filter is inverter_model.inverter_lc_filter;
        alias input_voltage is inverter_model.input_voltage;
        alias grid_inverter_state_counter is inverter_model.grid_inverter_state_counter;
        alias duty_ratio is inverter_model.duty_ratio;

    --------------------------------------------------

    begin
        create_multiplier(inverter_multiplier);
        create_state_variable(dc_link_voltage, inverter_multiplier, -dc_link_current - dc_link_load_current); 
        create_lcr_filter(inverter_lc_filter, inverter_multiplier, input_voltage - inverter_lc_filter.capacitor_voltage, inverter_lc_filter.inductor_current.state + load_current);

        CASE grid_inverter_state_counter is
            WHEN 0 =>
                multiply(inverter_multiplier, dc_link_voltage.state, duty_ratio);
                grid_inverter_state_counter <= grid_inverter_state_counter + 1;
            WHEN 1 =>
                multiply(inverter_multiplier, inverter_lc_filter.inductor_current.state, duty_ratio);
                grid_inverter_state_counter <= grid_inverter_state_counter + 1;
            WHEN 2 =>
                if multiplier_is_ready(inverter_multiplier) then
                    input_voltage <= get_multiplier_result(inverter_multiplier, 15);
                    grid_inverter_state_counter <= grid_inverter_state_counter + 1;
                end if;
            WHEN 3 =>
                calculate(dc_link_voltage);
                dc_link_current <= get_multiplier_result(inverter_multiplier, 15);
                grid_inverter_state_counter <= grid_inverter_state_counter + 1;
            WHEN 4 =>
                increment_counter_when_ready(inverter_multiplier, grid_inverter_state_counter);
            WHEN 5 =>
                calculate_lcr_filter(inverter_lc_filter);
                grid_inverter_state_counter <= grid_inverter_state_counter + 1;
            WHEN others => -- wait for restart
        end CASE;
        
    end create_inverter_model;

------------------------------------------------------------------------
    procedure request_inverter_calculation
    (
        signal inverter_model : out inverter_model_record;
        duty_ratio : in int
    ) is
    begin
        inverter_model.grid_inverter_state_counter <= 0;
        inverter_model.duty_ratio <= duty_ratio;
    end  request_inverter_calculation;
------------------------------------------------------------------------
    function get_inverter_inductor_current
    (
        inverter_model : inverter_model_record
    )
    return int
    is
    begin
        return inverter_model.inverter_lc_filter.inductor_current.state;
    end get_inverter_inductor_current;
------------------------------------------------------------------------
    function get_dc_link_voltage
    (
        inverter_model : inverter_model_record
    )
    return int
    is
    begin
        return inverter_model.dc_link_voltage.state;
    end get_dc_link_voltage;
------------------------------------------------------------------------
    function get_inverter_capacitor_voltage
    (
        inverter_model : inverter_model_record
    )
    return int
    is
    begin
        return inverter_model.inverter_lc_filter.capacitor_voltage.state;
    end get_inverter_capacitor_voltage;
------------------------------------------------------------------------
    function init_inverter_state_variable_gains
    (
        inductor_integrator_gain : int;
        ac_capacitor_integrator_gain : int;
        dc_link_integrator_gain : int
    )
    return inverter_model_record
    is
        variable initial_model_gains : inverter_model_record := init_inverter_model;
    begin
        initial_model_gains.inverter_lc_filter := init_lcr_model_integrator_gains(inductor_integrator_gain, ac_capacitor_integrator_gain);
        initial_model_gains.dc_link_voltage    := init_state_variable_gain(dc_link_integrator_gain);
        return initial_model_gains;
    end init_inverter_state_variable_gains;
------------------------------------------------------------------------
    function init_inverter_state_and_gains
    (
        dc_link_voltage_init : int;
        inductor_integrator_gain : int;
        ac_capacitor_integrator_gain : int;
        dc_link_integrator_gain : int
    )
    return inverter_model_record
    is
        variable initial_model : inverter_model_record := init_inverter_state_variable_gains(inductor_integrator_gain, ac_capacitor_integrator_gain, dc_link_integrator_gain);
    begin
        initial_model.dc_link_voltage.state := dc_link_voltage_init;
        return initial_model;
        
    end init_inverter_state_and_gains;
------------------------------------------------------------------------
    procedure set_dc_link_voltage
    (
        signal inverter_model : out inverter_model_record;
        set_value_for_dc_link : int
    ) is
    begin
        inverter_model.dc_link_voltage.state <= set_value_for_dc_link;
        
    end set_dc_link_voltage;

------------------------------------------------------------------------
end package body inverter_model_pkg; 
