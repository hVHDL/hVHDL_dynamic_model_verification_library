LIBRARY ieee  ; 
LIBRARY std  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    USE ieee.std_logic_textio.all  ; 
    use ieee.math_real.all;
    USE std.textio.all  ; 

    use work.multiplier_pkg.all;
    use work.state_variable_pkg.all;
    use work.power_supply_simulation_model_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity tb_power_supply_model is
  generic (runner_cfg : string);
end;

architecture sim of tb_power_supply_model is
    signal rstn : std_logic;

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    signal clocked_reset : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50e3;

    signal simulation_counter : natural := 0;

------------------------------------------------------------------------
    -- inverter model signals
    signal duty_ratio : int18 := 15e3;
    signal input_voltage : int18 := 0;
    signal dc_link_voltage : int18 := 0;

    signal dc_link_current : int18 := 0;
    signal dc_link_load_current : int18 := 0;
    signal output_dc_link_load_current : int18 := 0;
    signal output_inverter_load_current : int18 := 0;
    signal output_voltage : int18 := 0;

    signal output_dc_link_voltage : int18 := 0;
    signal output_dc_link_current : int18 := 0;

------------------------------------------------------------------------
    signal inverter_multiplier  : multiplier_record := multiplier_init_values;

    signal inverter_simulation_trigger_counter : natural := 0;

    signal output_resistance : natural  :=50e3;
    signal output_current : integer := 0;
    signal dab_pi_output : int18 := 0;
    signal dab_pi_error : int18 := 0;

    signal power_supply_simulation : power_supply_model_record := power_supply_model_init;
    signal grid_inductor_model_multiplier : multiplier_record := multiplier_init_values;
    signal grid_inductor_model : state_variable_record := init_state_variable_gain(35e3);

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        simulation_running <= false;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

------------------------------------------------------------------------
    sim_clock_gen : process
    begin
        simulator_clock <= '0';
        rstn <= '0';
        simulator_clock <= '0';
        wait for clock_half_per;
        while simulation_running loop
            wait for clock_half_per;
                rstn <= '1';
                simulator_clock <= not simulator_clock;
            end loop;
        wait;
    end process;
------------------------------------------------------------------------

    clocked_reset_generator : process(simulator_clock, rstn)
    --------------------------------------------------
    begin
        if rising_edge(simulator_clock) then
            ------------------------------------------------------------------------
            simulation_counter <= simulation_counter + 1;
            if simulation_counter = 30e3 then
                -- duty_ratio <= 19e3;
                output_resistance <= 12e3;
            end if;

            --------------------------------------------------
            create_power_supply_simulation_model(power_supply_simulation, 8e3, output_inverter_load_current); 

            inverter_simulation_trigger_counter <= inverter_simulation_trigger_counter + 1;
            if inverter_simulation_trigger_counter = 24 then
                inverter_simulation_trigger_counter <= 0; 

                calculate(grid_inductor_model);
                request_power_supply_calculation(power_supply_simulation, -duty_ratio, duty_ratio);

            end if; 

            --------------------------------------------------
            create_multiplier(inverter_multiplier); 
            sequential_multiply(inverter_multiplier, power_supply_simulation.output_inverter_simulation.output_emi_filter.capacitor_voltage.state, output_resistance);
            if multiplier_is_ready(inverter_multiplier) then
                output_inverter_load_current <= get_multiplier_result(inverter_multiplier, 15);
            end if;

            -------------------------------------------------- 
            dc_link_voltage        <= power_supply_simulation.grid_inverter_simulation.grid_inverter.dc_link_voltage.state;
            output_dc_link_voltage <= power_supply_simulation.output_inverter_simulation.output_inverter.dc_link_voltage.state;
            output_dc_link_current <= power_supply_simulation.output_inverter_simulation.output_inverter.dc_link_current;
            output_voltage         <= power_supply_simulation.output_inverter_simulation.output_emi_filter.capacitor_voltage.state;
            output_current         <= power_supply_simulation.output_inverter_simulation.output_inverter.inverter_lc_filter.inductor_current.state;
            dab_pi_output          <= power_supply_simulation.dab_pi_controller.pi_out;
            dab_pi_error           <= power_supply_simulation.output_inverter_simulation.output_inverter.dc_link_voltage - power_supply_simulation.grid_inverter_simulation.grid_inverter.dc_link_voltage.state;
    
        end if; -- rstn
    end process clocked_reset_generator;	
------------------------------------------------------------------------

end sim;
