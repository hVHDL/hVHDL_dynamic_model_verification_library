library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_pkg.all;
    use work.state_variable_pkg.all;

package lcr_filter_model_pkg is

------------------------------------------------------------------------
    type lcr_model_record is record
        inductor_current  : state_variable_record;
        capacitor_voltage : state_variable_record;
        process_counter   : natural range 0 to 7;
        process_counter2  : natural range 0 to 7;

        current_state_equation : int;
        voltage_state_equation : int;

        inductor_current_delta      : int;
        inductor_series_resistance  : int;
        capacitor_series_resistance : int;

        lcr_filter_is_ready : boolean;
    end record;

    function init_lcr_filter return lcr_model_record;
    function init_lcr_filter ( 
        inductor_integrator_gain : integer; 
        capacitor_integrator_gain : integer)
        return lcr_model_record;
    function init_lcr_filter (
        inductor_integrator_gain : integer;
        capacitor_integrator_gain : integer;
        inductor_series_resistance : integer)
        return lcr_model_record;

------------------------------------------------------------------------
    procedure create_test_lcr_filter (
        signal hw_multiplier : inout multiplier_record;
        signal lcr_filter_object : inout lcr_model_record;
        load_current             : in int;
        u_in : in int);

------------------------------------------------------------------------
    function get_capacitor_voltage ( lcr_filter_object : lcr_model_record)
        return integer;

------------------------------------------------------------------------
    function get_inductor_current ( lcr_filter_object : lcr_model_record)
        return integer;
------------------------------------------------------------------------
    procedure request_lcr_filter_calculation (
        signal lcr_filter_object : out lcr_model_record);

------------------------------------------------------------------------
    function lcr_filter_calculation_is_ready ( lcr_filter_object : lcr_model_record)
        return boolean;

------------------------------------------------------------------------
    procedure create_lcr_filter (
        signal lcr_filter : inout lcr_model_record;
        signal multiplier : inout multiplier_record;
        inductor_current_state_equation : in integer;
        capacitor_voltage_state_equation : in integer );

    procedure create_lcr_filter (
        signal lcr_filter : inout lcr_model_record;
        signal multiplier : inout multiplier_record;
        inductor_current_state_equation : in integer;
        capacitor_voltage_state_equation : in state_variable_record );

------------------------------------------------------------------------
    procedure calculate_lcr_filter (
        signal lcr_filter : inout lcr_model_record);

------------------------------------------------------------------------
    function init_lcr_model_integrator_gains (
        inductor_integrator_gain : integer;
        capacitor_integrator_gain : integer)
        return lcr_model_record;

------------------------------------------------------------------------
end package lcr_filter_model_pkg;


package body lcr_filter_model_pkg is

------------------------------------------------------------------------
    constant defaut_values_for_lcr_filter : lcr_model_record := 
            (inductor_current           => init_state_variable ,
            capacitor_voltage           => init_state_variable ,
            process_counter             => 7                   ,
            process_counter2            => 7                   ,
            current_state_equation      => 0                   ,
            voltage_state_equation      => 0                   ,
            inductor_current_delta      => 0                   ,
            inductor_series_resistance  => 625                 ,
            capacitor_series_resistance => 0                ,
            lcr_filter_is_ready         => false);

    --
    function init_lcr_filter return lcr_model_record
    is
    begin

        return defaut_values_for_lcr_filter;
        
    end init_lcr_filter;

    --
    function init_lcr_filter
    (
        inductor_integrator_gain : integer;
        capacitor_integrator_gain : integer
    )
    return lcr_model_record
    is
        variable returned_value : lcr_model_record;
    begin
        returned_value := defaut_values_for_lcr_filter;
        returned_value.inductor_current := init_state_variable_gain(inductor_integrator_gain);
        returned_value.capacitor_voltage := init_state_variable_gain(capacitor_integrator_gain);

        return returned_value;

    end init_lcr_filter;

    function init_lcr_filter
    (
        inductor_integrator_gain : integer;
        capacitor_integrator_gain : integer;
        inductor_series_resistance : integer
    )
    return lcr_model_record
    is
        variable returned_value : lcr_model_record;
    begin
        returned_value := init_lcr_filter(inductor_integrator_gain, capacitor_integrator_gain);
        returned_value.inductor_series_resistance := inductor_series_resistance;

        return returned_value;

    end init_lcr_filter;

    --
    function init_lcr_model_integrator_gains
    (
        inductor_integrator_gain : integer;
        capacitor_integrator_gain : integer
    )
    return lcr_model_record
    is
        variable lcr_filter_init : lcr_model_record := init_lcr_filter;
    begin

        lcr_filter_init.inductor_current := init_state_variable_gain(inductor_integrator_gain);
        lcr_filter_init.capacitor_voltage := init_state_variable_gain(capacitor_integrator_gain);
        return lcr_filter_init;
        
    end init_lcr_model_integrator_gains;

------------------------------------------------------------------------

------------------------------------------------------------------------
    procedure create_test_lcr_filter
    (
        signal hw_multiplier : inout multiplier_record;
        signal lcr_filter_object : inout lcr_model_record;
        load_current             : in int;
        u_in : in int
    ) is
        alias m is lcr_filter_object;
    begin

        create_state_variable(m.inductor_current  , hw_multiplier , m.current_state_equation);
        create_state_variable(m.capacitor_voltage , hw_multiplier , m.voltage_state_equation);
        
        CASE m.process_counter is
            WHEN 0 => multiply_and_increment_counter(hw_multiplier , m.process_counter , get_state(m.inductor_current) , m.inductor_series_resistance);
                      m.current_state_equation <= u_in - m.capacitor_voltage;
            WHEN 1 => multiply_and_increment_counter(hw_multiplier , m.process_counter , get_state(m.inductor_current) , m.capacitor_series_resistance) ;
            WHEN 2 => multiply_and_increment_counter(hw_multiplier , m.process_counter , load_current                , m.capacitor_series_resistance) ;
            WHEN others =>  -- do nothing
        end CASE;

        CASE m.process_counter2 is
            WHEN 0 => 
                if multiplier_is_ready(hw_multiplier) then
                    m.current_state_equation <= m.current_state_equation - get_multiplier_result(hw_multiplier, 15);
                    increment(m.process_counter2);
                end if;
            WHEN 1 => 
                if multiplier_is_ready(hw_multiplier) then
                    m.current_state_equation <= m.current_state_equation - get_multiplier_result(hw_multiplier, 15);
                    increment(m.process_counter2);
                end if;
            WHEN 2 => 
                if multiplier_is_ready(hw_multiplier) then
                    m.current_state_equation <= m.current_state_equation + get_multiplier_result(hw_multiplier, 15);
                    increment(m.process_counter2);
                end if;

            WHEN 3 => 
                request_state_variable_calculation(m.inductor_current);
                increment(m.process_counter2);
                      
            WHEN 4 => 
                if state_variable_calculation_is_ready(m.inductor_current) then
                    m.voltage_state_equation <= get_state(m.inductor_current) - load_current;
                    increment(m.process_counter2);
                end if;
            WHEN 5 => 
                    request_state_variable_calculation(m.capacitor_voltage);
                    increment(m.process_counter2);

            WHEN others =>  -- do nothing
        end CASE;

    end create_test_lcr_filter;
------------------------------------------------------------------------
    procedure create_lcr_filter
    (
        signal lcr_filter : inout lcr_model_record;
        signal multiplier : inout multiplier_record;
        inductor_current_state_equation : in integer;
        capacitor_voltage_state_equation : in integer

    ) is
        alias hw_multiplier is multiplier;
        alias m is lcr_filter;
    --------------------------------------------------
    begin
        CASE m.process_counter is 
            WHEN 0 => 
                sequential_multiply(hw_multiplier, m.inductor_series_resistance, m.inductor_current.state);
                increment_counter_when_ready(hw_multiplier, m.process_counter);

            WHEN 1 => 
                integrate_state(m.inductor_current, hw_multiplier, 15, inductor_current_state_equation - m.inductor_current_delta);
                increment_counter_when_ready(hw_multiplier, m.process_counter);

            WHEN 2 =>
                integrate_state(m.capacitor_voltage, hw_multiplier, 15, capacitor_voltage_state_equation);
                increment_counter_when_ready(hw_multiplier, m.process_counter);
            WHEN others => -- do nothing

        end CASE; 
    end create_lcr_filter;

    ----
    procedure create_lcr_filter
    (
        signal lcr_filter : inout lcr_model_record;
        signal multiplier : inout multiplier_record;
        inductor_current_state_equation : in integer;
        capacitor_voltage_state_equation : in state_variable_record

    ) is
    begin
        create_lcr_filter( lcr_filter, multiplier, inductor_current_state_equation, capacitor_voltage_state_equation.state);
    end create_lcr_filter; 

------------------------------------------------------------------------
    procedure request_lcr_filter_calculation
    (
        signal lcr_filter_object : out lcr_model_record
    ) is
    begin
        lcr_filter_object.process_counter <= 0;
        lcr_filter_object.process_counter2 <= 0;
    end request_lcr_filter_calculation;
------------------------------------------------------------------------
    procedure calculate_lcr_filter
    (
        signal lcr_filter : inout lcr_model_record
    ) is
    begin
        request_lcr_filter_calculation(lcr_filter);
    end calculate_lcr_filter;

------------------------------------------------------------------------
    function get_capacitor_voltage
    (
        lcr_filter_object : lcr_model_record
    )
    return integer
    is
    begin
        return get_state(lcr_filter_object.capacitor_voltage);
    end get_capacitor_voltage;

------------------------------------------------------------------------
    function get_inductor_current
    (
        lcr_filter_object : lcr_model_record
    )
    return integer
    is
    begin
        return get_state(lcr_filter_object.inductor_current);
    end get_inductor_current;
------------------------------------------------------------------------
    function lcr_filter_calculation_is_ready
    (
        lcr_filter_object : lcr_model_record
    )
    return boolean
    is
    begin
        return state_variable_calculation_is_ready(lcr_filter_object.capacitor_voltage);
    end lcr_filter_calculation_is_ready;
------------------------------------------------------------------------
end package body lcr_filter_model_pkg; 
