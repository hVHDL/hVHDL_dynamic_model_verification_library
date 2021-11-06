library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library math_library;
    use math_library.multiplier_pkg.all;
    use math_library.state_variable_pkg.all;
    use math_library.lcr_filter_model_pkg.all;
    use math_library.inverter_model_pkg.all;

package psu_inverter_simulation_models_pkg is

------------------------------------------------------------------------
    type grid_inverter_record is record
        grid_inverter : inverter_model_record;
        multiplier1 : multiplier_record;
        multiplier2 : multiplier_record;
        grid_emi_filter_1 : lcr_model_record;
        grid_emi_filter_2 : lcr_model_record;
    end record;

    constant grid_inverter_init : grid_inverter_record := (init_inverter_model, multiplier_init_values, multiplier_init_values,init_lcr_model_integrator_gains(25e3, 2e3), init_lcr_model_integrator_gains(25e3, 2e3));
------------------------------------------------------------------------
    type output_inverter_record is record
        output_inverter : inverter_model_record;
        multiplier : multiplier_record;
        output_emi_filter : lcr_model_record;
    end record;

    constant output_inverter_init : output_inverter_record := (init_inverter_model, multiplier_init_values, init_lcr_model_integrator_gains(25e3, 2e3));
------------------------------------------------------------------------ 
    procedure create_grid_inverter (
        signal grid_inverter : inout grid_inverter_record;
        dc_link_load_current : in int18;
        ac_load_current : in int18);

    procedure request_grid_inverter_calculation (
        signal grid_inverter : inout grid_inverter_record;
        duty_ratio : in int18);
------------------------------------------------------------------------
    procedure create_output_inverter (
        signal output_inverter : inout output_inverter_record;
        output_dc_link_load_current : in int18;
        ac_load_current : in int18);

    procedure request_output_inverter_calculation (
        signal output_inverter : inout output_inverter_record;
        duty_ratio : in int18);
------------------------------------------------------------------------

end package psu_inverter_simulation_models_pkg;


package body psu_inverter_simulation_models_pkg is
------------------------------------------------------------------------
    procedure create_grid_inverter
    (
        signal grid_inverter : inout grid_inverter_record;
        dc_link_load_current : in int18;
        ac_load_current : in int18
    ) is
        alias emi_filter1 is grid_inverter.grid_emi_filter_1;
        alias emi_filter2 is grid_inverter.grid_emi_filter_2;
        alias inverter_lc is grid_inverter.grid_inverter.inverter_lc_filter;
    begin
        create_multiplier(grid_inverter.multiplier1);
        create_multiplier(grid_inverter.multiplier2);
        create_inverter_model(grid_inverter.grid_inverter , dc_link_load_current      , -emi_filter1.inductor_current);
        create_lcr_filter(grid_inverter.grid_emi_filter_1 , grid_inverter.multiplier1 , inverter_lc.capacitor_voltage - emi_filter1.capacitor_voltage , emi_filter1.inductor_current - emi_filter2.inductor_current);
        create_lcr_filter(grid_inverter.grid_emi_filter_2 , grid_inverter.multiplier2 , emi_filter1.capacitor_voltage - emi_filter2.capacitor_voltage , emi_filter2.inductor_current - ac_load_current);

    end create_grid_inverter;

    procedure request_grid_inverter_calculation
    (
        signal grid_inverter : inout grid_inverter_record;
        duty_ratio : in int18
    ) is
    begin
        request_inverter_calculation(grid_inverter.grid_inverter, duty_ratio);
        calculate_lcr_filter(grid_inverter.grid_emi_filter_1);
        calculate_lcr_filter(grid_inverter.grid_emi_filter_2);
    end request_grid_inverter_calculation;

------------------------------------------------------------------------
    procedure create_output_inverter
    (
        signal output_inverter : inout output_inverter_record;
        output_dc_link_load_current : in int18;
        ac_load_current : in int18
    ) is
        alias emi_filter is output_inverter.output_emi_filter;
        alias inverter is output_inverter.output_inverter;
    begin
        create_multiplier(output_inverter.multiplier); 
        create_inverter_model(output_inverter.output_inverter , output_dc_link_load_current, -emi_filter.inductor_current);
        create_lcr_filter(emi_filter, output_inverter.multiplier, inverter.inverter_lc_filter.capacitor_voltage - emi_filter.capacitor_voltage , emi_filter.inductor_current - ac_load_current); 

    end create_output_inverter;

    procedure request_output_inverter_calculation
    (
        signal output_inverter : inout output_inverter_record;
        duty_ratio : in int18
    ) is
    begin
        request_inverter_calculation(output_inverter.output_inverter, duty_ratio);
        calculate_lcr_filter(output_inverter.output_emi_filter);
    end request_output_inverter_calculation;

end package body psu_inverter_simulation_models_pkg; 
