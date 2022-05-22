library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_pkg.all;
    use work.state_variable_pkg.all;
    use work.psu_inverter_simulation_models_pkg.all;
    use work.pi_controller_pkg.all;

package power_supply_simulation_model_pkg is

------------------------------------------------------------------------
    type power_supply_model_record is record
        grid_inverter_simulation       : grid_inverter_record;
        output_inverter_simulation     : output_inverter_record;
        dab_pi_controller              : pi_controller_record;
        multiplier                     : multiplier_record;
        grid_inductor_model_multiplier : multiplier_record;
        grid_inductor_model            : state_variable_record;
    end record;

    constant power_supply_model_init : power_supply_model_record := (grid_inverter_init, output_inverter_init, pi_controller_init, multiplier_init_values,  multiplier_init_values, init_state_variable_gain(35e3));

    --------------------------------------------------
    procedure create_power_supply_simulation_model (
        signal power_supply_simulation : inout power_supply_model_record;
        grid_voltage : int;
        output_inverter_load_current : int);
    --------------------------------------------------
    procedure request_power_supply_calculation (
        signal power_supply_simulation : inout power_supply_model_record;
        grid_inverter_duty_ratio       : int;
        output_inverter_duty_ratio     : int);
------------------------------------------------------------------------

end package power_supply_simulation_model_pkg;


package body power_supply_simulation_model_pkg is

------------------------------------------------------------------------
    procedure create_power_supply_simulation_model
    (
        signal power_supply_simulation : inout power_supply_model_record;
        grid_voltage : int;
        output_inverter_load_current : int
    ) is
        alias grid_inverter_simulation is power_supply_simulation.grid_inverter_simulation;
        alias output_inverter_simulation is power_supply_simulation.output_inverter_simulation;
        alias dab_pi_controller is power_supply_simulation.dab_pi_controller;
        alias multiplier is power_supply_simulation.multiplier;
        alias grid_inductor_model_multiplier is power_supply_simulation.grid_inductor_model_multiplier;
        alias grid_inductor_model is power_supply_simulation.grid_inductor_model;
    begin
        create_multiplier(multiplier);
        create_pi_controller(multiplier, dab_pi_controller, 18e3, 2e3); 

        create_multiplier(grid_inductor_model_multiplier);
        create_state_variable(grid_inductor_model, grid_inductor_model_multiplier, power_supply_simulation.grid_inverter_simulation.grid_emi_filter_2.capacitor_voltage.state + grid_voltage);

        create_grid_inverter(grid_inverter_simulation, -dab_pi_controller.pi_out, grid_inductor_model.state);
        create_output_inverter(output_inverter_simulation, dab_pi_controller.pi_out, output_inverter_load_current);
        
    end create_power_supply_simulation_model;

    --------------------------------------------------
    procedure request_power_supply_calculation
    (
        signal power_supply_simulation : inout power_supply_model_record;
        grid_inverter_duty_ratio : int;
        output_inverter_duty_ratio : int
    ) is
        alias grid_inverter_simulation is power_supply_simulation.grid_inverter_simulation;
        alias output_inverter_simulation is power_supply_simulation.output_inverter_simulation;
        alias dab_pi_controller is power_supply_simulation.dab_pi_controller;
        alias multiplier is power_supply_simulation.multiplier;
        alias grid_inductor_model is power_supply_simulation.grid_inductor_model;
    begin

        calculate(grid_inductor_model);
        calculate_pi_control(dab_pi_controller, output_inverter_simulation.output_inverter.dc_link_voltage - grid_inverter_simulation.grid_inverter.dc_link_voltage); 
        request_grid_inverter_calculation(grid_inverter_simulation, grid_inverter_duty_ratio); 
        request_output_inverter_calculation(output_inverter_simulation, output_inverter_duty_ratio); 
        
    end request_power_supply_calculation;

------------------------------------------------------------------------ 
end package body power_supply_simulation_model_pkg; 
