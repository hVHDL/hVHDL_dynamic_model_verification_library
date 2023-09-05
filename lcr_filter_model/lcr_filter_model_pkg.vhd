library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_pkg.all;
    use work.state_variable_pkg.all;
    use work.real_to_fixed_pkg.all;

package lcr_filter_model_pkg is

------------------------------------------------------------------------
    type lcr_model_record is record
        inductor_current  : state_variable_record;
        capacitor_voltage : state_variable_record;
        process_counter   : natural range 0 to 7;
        process_counter2  : natural range 0 to 7;

        current_state_equation : s_int;
        voltage_state_equation : s_int;

        inductor_current_delta      : s_int;
        inductor_series_resistance  : s_int;
        capacitor_series_resistance : s_int;

        lcr_filter_is_ready : boolean;
    end record;

    function init_lcr_filter return lcr_model_record;

    function init_lcr_filter (
        inductor, capacitor, resistor, time_step : real;
        radix : integer)
    return lcr_model_record;

    function init_lcr_filter ( 
        inductor_integrator_gain : signed; 
        capacitor_integrator_gain : signed)
        return lcr_model_record;

    function init_lcr_filter (
        inductor_integrator_gain : signed;
        capacitor_integrator_gain : signed;
        inductor_series_resistance : signed)
        return lcr_model_record;

    function set_integrator_gain (
        time_step : real;
        integrator_radix : integer;
        inductor_or_capacitor : real)
    return signed;

    function set_resistor_value (
        resistor : real;
        radix : integer)
    return signed;

------------------------------------------------------------------------
    procedure create_lcr_filter (
        signal self          : inout lcr_model_record;
        signal hw_multiplier : inout multiplier_record;
        load_current         : in int;
        u_in                 : in int);

    procedure create_lcr_filter (
        signal self          : inout lcr_model_record;
        signal hw_multiplier : inout multiplier_record;
        load_current         : in int;
        u_in                 : in int;
        integrator_radix     : integer);

------------------------------------------------------------------------
    function get_capacitor_voltage ( lcr_filter_object : lcr_model_record)
        return signed;

------------------------------------------------------------------------
    function get_inductor_current ( lcr_filter_object : lcr_model_record)
        return signed;
------------------------------------------------------------------------
    procedure request_lcr_filter_calculation (
        signal lcr_filter_object : out lcr_model_record);

------------------------------------------------------------------------
    function lcr_filter_calculation_is_ready ( lcr_filter_object : lcr_model_record)
        return boolean;

------------------------------------------------------------------------
    procedure calculate_lcr_filter (
        signal lcr_filter : inout lcr_model_record);

------------------------------------------------------------------------
    function init_lcr_model_integrator_gains (
        inductor_integrator_gain  : signed;
        capacitor_integrator_gain : signed)
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
            current_state_equation      => (others => '0')     ,
            voltage_state_equation      => (others => '0')     ,
            inductor_current_delta      => (others => '0')     ,
            inductor_series_resistance  => to_signed(625       , int_word_length) ,
            capacitor_series_resistance => (others => '0')     ,
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
        inductor, capacitor, resistor, time_step : real;
        radix : integer
    )
    return lcr_model_record
    is
    begin
        return init_lcr_filter(set_integrator_gain(time_step, radix, inductor),
                               set_integrator_gain(time_step, radix, capacitor),
                               to_fixed(resistor, radix, int_word_length));
    end init_lcr_filter;

    --
    function init_lcr_filter
    (
        inductor_integrator_gain : signed;
        capacitor_integrator_gain : signed
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
        inductor_integrator_gain : signed;
        capacitor_integrator_gain : signed;
        inductor_series_resistance : signed
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
        inductor_integrator_gain : signed;
        capacitor_integrator_gain : signed
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
    procedure create_lcr_filter
    (
        signal self          : inout lcr_model_record;
        signal hw_multiplier : inout multiplier_record;
        load_current         : in int;
        u_in                 : in int;
        integrator_radix     : integer
    ) is
        variable mpy_result : s_int;
    begin

        create_state_variable(self.inductor_current  , hw_multiplier, integrator_radix , self.current_state_equation);
        create_state_variable(self.capacitor_voltage , hw_multiplier, integrator_radix , self.voltage_state_equation);
        
        CASE self.process_counter is
            WHEN 0 => multiply_and_increment_counter(hw_multiplier , self.process_counter , get_state(self.inductor_current) , self.inductor_series_resistance);
                      self.current_state_equation <= to_signed(u_in, int_word_length) - self.capacitor_voltage;
            WHEN 1 => multiply_and_increment_counter(hw_multiplier , self.process_counter , get_state(self.inductor_current) , self.capacitor_series_resistance) ;
            WHEN 2 => multiply_and_increment_counter(hw_multiplier , self.process_counter , to_signed(load_current, int_word_length)                , self.capacitor_series_resistance) ;
            WHEN others =>  -- do nothing
        end CASE;

        CASE self.process_counter2 is
            WHEN 0 => 
                if multiplier_is_ready(hw_multiplier) then
                    mpy_result := get_multiplier_result(hw_multiplier, integrator_radix);
                    self.current_state_equation <= self.current_state_equation - mpy_result;
                    increment(self.process_counter2);
                end if;
            WHEN 1 => 
                if multiplier_is_ready(hw_multiplier) then
                    mpy_result := get_multiplier_result(hw_multiplier, integrator_radix);
                    self.current_state_equation <= self.current_state_equation - mpy_result;
                    increment(self.process_counter2);
                end if;
            WHEN 2 => 
                if multiplier_is_ready(hw_multiplier) then
                    mpy_result := get_multiplier_result(hw_multiplier, integrator_radix);
                    self.current_state_equation <= self.current_state_equation + mpy_result;
                    increment(self.process_counter2);
                end if;

            WHEN 3 => 
                request_state_variable_calculation(self.inductor_current);
                increment(self.process_counter2);
                      
            WHEN 4 => 
                if state_variable_calculation_is_ready(self.inductor_current) then
                    self.voltage_state_equation <= get_state(self.inductor_current) - load_current;
                    increment(self.process_counter2);
                end if;
            WHEN 5 => 
                    request_state_variable_calculation(self.capacitor_voltage);
                    increment(self.process_counter2);

            WHEN others =>  -- do nothing
        end CASE;

    end create_lcr_filter;

    procedure create_lcr_filter
    (
        signal self : inout lcr_model_record;
        signal hw_multiplier     : inout multiplier_record;
        load_current             : in int;
        u_in                     : in int
    ) is
    begin
        create_lcr_filter(self, hw_multiplier,  load_current, u_in, 15);
    end procedure create_lcr_filter;
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
    return signed
    is
    begin
        return get_state(lcr_filter_object.capacitor_voltage);
    end get_capacitor_voltage;

------------------------------------------------------------------------
    function get_inductor_current
    (
        lcr_filter_object : lcr_model_record
    )
    return signed
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
    function set_integrator_gain
    (
        time_step : real;
        integrator_radix : integer;
        inductor_or_capacitor : real
    )
    return signed
    is
    begin
        return to_fixed(time_step/inductor_or_capacitor,int_word_length, integrator_radix);
    end set_integrator_gain;
------------------------------------------------------------------------
    function set_resistor_value
    (
        resistor : real;
        radix : integer
    )
    return signed
    is
    begin
        return to_fixed(resistor, radix, int_word_length);
    end set_resistor_value;
------------------------------------------------------------------------
end package body lcr_filter_model_pkg; 
