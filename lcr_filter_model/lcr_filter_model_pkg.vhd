library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_pkg.all;
    use work.state_variable_pkg.all;

package lcr_filter_model_pkg is

------------------------------------------------------------------------
    type lcr_model_record is record
        inductor_current   : state_variable_record;
        capacitor_voltage  : state_variable_record;
        multiplier_counter : natural range 0 to 7;
        process_counter    : natural range 0 to 7;

        current_state_equation : int;
        voltage_state_equation : int;

        inductor_current_delta     : int;
        inductor_series_resistance : int;

        lcr_filter_is_ready : boolean;
    end record;

    constant init_lcr_filter : lcr_model_record := 
            (inductor_current          => init_state_variable ,
            capacitor_voltage          => init_state_variable ,
            process_counter            => 7                   ,
            multiplier_counter         => 7                   ,
            current_state_equation     => 0                   ,
            voltage_state_equation     => 0                   ,
            inductor_current_delta     => 0                   ,
            inductor_series_resistance => 4000                 ,
            lcr_filter_is_ready => false);
------------------------------------------------------------------------
    procedure create_test_lcr_filter (
        signal hw_multiplier     : inout multiplier_record;
        signal lcr_filter_object : inout lcr_model_record;
        u_in                     : in int);

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
    procedure create_test_lcr_filter
    (
        signal hw_multiplier : inout multiplier_record;
        signal lcr_filter_object : inout lcr_model_record;
        load_current             : in int;
        u_in : in int
    ) is
        alias inductor_current        is lcr_filter_object.inductor_current           ;
        alias capacitor_voltage       is lcr_filter_object.capacitor_voltage          ;
        alias process_counter         is lcr_filter_object.process_counter            ;
        alias process_counter2        is lcr_filter_object.multiplier_counter         ;
        alias current_state_equation  is lcr_filter_object.current_state_equation     ;
        alias voltage_state_equation  is lcr_filter_object.voltage_state_equation     ;
        alias R_inductor              is lcr_filter_object.inductor_series_resistance ;

        alias lcr_filter_is_ready is lcr_filter_object.lcr_filter_is_ready;
    begin

        -- this does not, uses aliases for inductor_current and capacitor_voltage
        create_state_variable(inductor_current  , hw_multiplier , current_state_equation);
        create_state_variable(capacitor_voltage , hw_multiplier , voltage_state_equation);
        
        lcr_filter_is_ready <= false;
        CASE process_counter is
            WHEN 0 => multiply_and_increment_counter(hw_multiplier , process_counter , get_state(inductor_current) , 4000) ;
            WHEN others =>  -- do nothing
        end CASE;

        CASE process_counter2 is
            WHEN 0 => 
                if multiplier_is_ready(hw_multiplier) then
                    current_state_equation <= get_multiplier_result(hw_multiplier, 15);
                    voltage_state_equation <= get_state(inductor_current) - load_current;
                    increment(process_counter2);
                end if;

            WHEN 1 => 
                current_state_equation <= -current_state_equation - capacitor_voltage + u_in;
                increment(process_counter2);

            WHEN 2 => 
                request_state_variable_calculation(inductor_current);
                increment(process_counter2);
                      
            WHEN 3 => 
                if state_variable_calculation_is_ready(inductor_current) then
                    request_state_variable_calculation(capacitor_voltage);
                    increment(process_counter2);
                end if;
            WHEN 4 => 
                if state_variable_calculation_is_ready(capacitor_voltage) then
                    lcr_filter_is_ready <= true;
                    increment(process_counter2);
                end if;

            WHEN others =>  -- do nothing
        end CASE;

    end create_test_lcr_filter;
------------------------------------------------------------------------
    procedure create_test_lcr_filter
    (
        signal hw_multiplier     : inout multiplier_record;
        signal lcr_filter_object : inout lcr_model_record;
        u_in                     : in int
    ) is
    begin
        create_test_lcr_filter (
            hw_multiplier     ,
            lcr_filter_object ,
            200               ,
            u_in);
        
    end create_test_lcr_filter;
------------------------------------------------------------------------
    procedure create_lcr_filter
    (
        signal lcr_filter : inout lcr_model_record;
        signal multiplier : inout multiplier_record;
        inductor_current_state_equation : in integer;
        capacitor_voltage_state_equation : in integer

    ) is
        alias hw_multiplier               is multiplier;
        alias process_counter             is lcr_filter.process_counter;
        alias multiplier_counter          is lcr_filter.process_counter;
        alias inductor_current_delta      is lcr_filter.inductor_current_delta;
        alias inductor_series_resistance  is lcr_filter.inductor_series_resistance;
        alias inductor_current            is lcr_filter.inductor_current;
        alias capacitor_voltage           is lcr_filter.capacitor_voltage;
    --------------------------------------------------
    begin
        CASE process_counter is 
            WHEN 0 => 
                sequential_multiply(hw_multiplier, inductor_series_resistance, inductor_current.state);
                increment_counter_when_ready(hw_multiplier, process_counter);

            WHEN 1 => 
                integrate_state(inductor_current, hw_multiplier, 15, inductor_current_state_equation - inductor_current_delta);
                increment_counter_when_ready(hw_multiplier, process_counter);

            WHEN 2 =>
                integrate_state(capacitor_voltage, hw_multiplier, 15, capacitor_voltage_state_equation);
                increment_counter_when_ready(hw_multiplier, process_counter);
            WHEN others => -- do nothing

        end CASE; 
    end create_lcr_filter;

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
        lcr_filter_object.multiplier_counter <= 0;
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
        return lcr_filter_object.lcr_filter_is_ready;
    end lcr_filter_calculation_is_ready;
------------------------------------------------------------------------
end package body lcr_filter_model_pkg; 
