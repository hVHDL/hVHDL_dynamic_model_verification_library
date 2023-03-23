library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_pkg.all;
    use work.lcr_filter_model_pkg.all;
    use work.real_to_fixed_pkg.all;

package filtered_buck_model_pkg is

    type half_bridge_record is record
        dc_link_current : int;
        output_voltage  : int;
        duty_counter    : integer range 0 to 3;
        result_counter  : integer range 0 to 3;
    end record;

    constant init_half_bridge : half_bridge_record := (0,0,0,0);

    type filtered_buck_record is record
        input_lc1    : lcr_model_record;
        input_lc2    : lcr_model_record;
        primary_lc   : lcr_model_record;
        output_lc1   : lcr_model_record;
        output_lc2   : lcr_model_record;
        multiplier_1 : multiplier_record;
        multiplier_2 : multiplier_record;
        multiplier_3 : multiplier_record;
        multiplier_4 : multiplier_record;
        multiplier_5 : multiplier_record;
        multiplier_6 : multiplier_record;
        half_bridge  : half_bridge_record;
    end record;

    function init_filtered_buck return filtered_buck_record;

    procedure create_filtered_buck (
        signal self   : inout filtered_buck_record;
        duty_ratio    : in integer;
        input_voltage : integer;
        load_current  : integer);

    procedure request_filtered_buck_calculation (
        signal filtered_buck : out filtered_buck_record);

    function get_dc_link_current ( filtered_buck : filtered_buck_record)
        return int;

end package filtered_buck_model_pkg;


package body filtered_buck_model_pkg is
------------------------------------------------------------------------
    procedure create_half_bridge
    (
        signal self : inout half_bridge_record;
        signal multiplier : inout multiplier_record;
        output_current : in int;
        input_voltage : in int;
        duty_ratio : in int;
        radix : in natural
    ) is
    begin
        case self.duty_counter is
            WHEN 0 => multiply_and_increment_counter(multiplier , self.duty_counter , output_current , duty_ratio);
            WHEN 1 => multiply_and_increment_counter(multiplier , self.duty_counter , input_voltage  , duty_ratio);
            WHEN others => --do nothing
        end CASE;

        if multiplier_is_ready(multiplier) then
            self.result_counter <= self.result_counter + 1;
            case self.result_counter is
                WHEN 0 => self.dc_link_current <= get_multiplier_result(multiplier, radix);
                WHEN 1 => self.output_voltage  <= get_multiplier_result(multiplier, radix);
                WHEN others => -- do nothing
            end CASE;
        end if;
    end create_half_bridge;
------------------------------
    procedure request_half_bridge
    (
        signal half_bridge_object : out half_bridge_record
    ) is
    begin
        half_bridge_object.duty_counter   <= 0;
        half_bridge_object.result_counter <= 0;
    end request_half_bridge;
------------------------------

    function get_half_bridge_current
    (
        half_bridge_object : half_bridge_record
    )
    return int
    is
    begin

        return half_bridge_object.dc_link_current;
        
    end get_half_bridge_current;

------------------------------
    function get_half_bridge_voltage
    (
        half_bridge_object  : half_bridge_record
    )
    return int
    is
    begin
        return half_bridge_object.output_voltage;
    end get_half_bridge_voltage;

------------------------------------------------------------------------
    constant L1_inductance : real := 1.0e-3;
    constant L2_inductance : real := 10.0e-6;
    constant L3_inductance : real := 100.0e-6;
    constant L4_inductance : real := 10.0e-6;
    constant L5_inductance : real := 10.0e-6;

    constant C1_capacitance : real := 20.0e-6;
    constant C2_capacitance : real := 10.0e-6;
    constant C3_capacitance : real := 100.0e-6;
    constant C4_capacitance : real := 2.2e-6;
    constant C5_capacitance : real := 20.0e-6;

    constant int_radix            : integer := int_word_length-1;
    constant simulation_time_step : real := 2.0e-6;

    constant filtered_buck_init_values : filtered_buck_record :=(
        init_lcr_filter(L2_inductance , C2_capacitance , 10.0e-3  , simulation_time_step , int_radix),
        init_lcr_filter(L3_inductance , C3_capacitance , 0.01     , simulation_time_step , int_radix),
        init_lcr_filter(L1_inductance , C1_capacitance , 300.0e-3 , simulation_time_step , int_radix),
        init_lcr_filter(L4_inductance , C4_capacitance , 0.01      , simulation_time_step , int_radix),
        init_lcr_filter(L5_inductance , C5_capacitance , 0.01      , simulation_time_step , int_radix),
        init_multiplier,
        init_multiplier,
        init_multiplier,
        init_multiplier,
        init_multiplier,
        init_multiplier,
        init_half_bridge);

    function init_filtered_buck return filtered_buck_record
    is
    begin
        return filtered_buck_init_values;
    end init_filtered_buck;


    procedure create_filtered_buck
    (
        signal self : inout filtered_buck_record;
        duty_ratio : in integer;
        input_voltage : integer;
        load_current : integer
    ) is
    begin
        create_multiplier(self.multiplier_1);
        create_multiplier(self.multiplier_2);
        create_multiplier(self.multiplier_3);
        create_multiplier(self.multiplier_4);
        create_multiplier(self.multiplier_5);
        create_multiplier(self.multiplier_6);

        create_lcr_filter(self.input_lc1  , self.multiplier_1 , get_inductor_current(self.input_lc2)      , input_voltage                             , int_radix);
        create_lcr_filter(self.input_lc2  , self.multiplier_2 , get_half_bridge_current(self.half_bridge) , get_capacitor_voltage(self.input_lc1)     , int_radix);
        create_lcr_filter(self.primary_lc , self.multiplier_3 , get_inductor_current(self.output_lc1)     , get_half_bridge_voltage(self.half_bridge) , int_radix);
        create_lcr_filter(self.output_lc1 , self.multiplier_4 , get_inductor_current(self.output_lc2)     , get_capacitor_voltage(self.primary_lc)    , int_radix);
        create_lcr_filter(self.output_lc2 , self.multiplier_5 , load_current                              , get_capacitor_voltage(self.output_lc1)    , int_radix);

        create_half_bridge(self.half_bridge, self.multiplier_6, get_inductor_current(self.primary_lc), get_capacitor_voltage(self.input_lc2), duty_ratio, 15);
        
    end create_filtered_buck;

    procedure request_filtered_buck_calculation
    (
        signal filtered_buck : out filtered_buck_record
    ) is
    begin
        request_lcr_filter_calculation(filtered_buck.input_lc1 );
        request_lcr_filter_calculation(filtered_buck.input_lc2 );
        request_lcr_filter_calculation(filtered_buck.primary_lc);
        request_lcr_filter_calculation(filtered_buck.output_lc1);
        request_lcr_filter_calculation(filtered_buck.output_lc2);
        request_half_bridge(filtered_buck.half_bridge);
        
    end request_filtered_buck_calculation;

    function get_dc_link_current
    (
        filtered_buck : filtered_buck_record
    )
    return int
    is
    begin
        return get_half_bridge_current(filtered_buck.half_bridge);
    end get_dc_link_current;

end package body filtered_buck_model_pkg;
