LIBRARY ieee  ; 
LIBRARY std  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    USE ieee.std_logic_textio.all  ; 
    use ieee.math_real.all;
    USE std.textio.all  ; 

    use work.multiplier_pkg.all;
    use work.state_variable_pkg.all;
    use work.lcr_filter_model_pkg.all;
    use work.inverter_model_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity tb_inverter_model is
  generic (runner_cfg : string);
end;

architecture sim of tb_inverter_model is
    signal rstn : std_logic;

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    signal clocked_reset : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 25e3;

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

    signal grid_inverter : inverter_model_record := init_inverter_model;
    signal output_inverter : inverter_model_record := init_inverter_model;
    
    signal inverter_multiplier  : multiplier_record := multiplier_init_values;
    signal inverter_multiplier2 : multiplier_record := multiplier_init_values;
    signal inverter_multiplier3 : multiplier_record := multiplier_init_values;

    signal inverter_simulation_trigger_counter : natural := 0;
    signal inverter_voltage : int18 := 0;

    signal load_resistor_current : int18 := 0;

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
        impure function "*" ( left, right : int18)
        return int18
        is
        begin
            sequential_multiply(inverter_multiplier, left, right);
            return get_multiplier_result(inverter_multiplier, 15);
        end "*";
    --------------------------------------------------
    begin
        if rising_edge(simulator_clock) then
            ------------------------------------------------------------------------
            simulation_counter <= simulation_counter + 1;
            if simulation_counter = 10e3 then
                duty_ratio <= 19e3;
            end if;

            create_multiplier(inverter_multiplier);
            create_multiplier(inverter_multiplier2);
            create_multiplier(inverter_multiplier3);

            create_inverter_model(grid_inverter   , output_inverter.dc_link_current , -output_inverter_load_current);
            create_inverter_model(output_inverter , grid_inverter.dc_link_current   , 0);


            --------------------------------------------------
            output_inverter.inverter_lc_filter.capacitor_voltage.state <= -2e3;

            inverter_simulation_trigger_counter <= inverter_simulation_trigger_counter + 1;
            if inverter_simulation_trigger_counter = 24 then
                inverter_simulation_trigger_counter <= 0;
                request_inverter_calculation(grid_inverter, duty_ratio);
                request_inverter_calculation(output_inverter, -duty_ratio);
            end if; 

            --------------------------------------------------
            sequential_multiply(inverter_multiplier, grid_inverter.inverter_lc_filter.capacitor_voltage.state, 40e3);
            if multiplier_is_ready(inverter_multiplier) then
                output_inverter_load_current <= get_multiplier_result(inverter_multiplier, 15);
            end if;

            -------------------------------------------------- 
            dc_link_voltage        <= grid_inverter.dc_link_voltage.state;
            output_dc_link_voltage <= output_inverter.dc_link_voltage.state;
            output_dc_link_current <= output_inverter.dc_link_current;
            output_voltage         <= output_inverter.inverter_lc_filter.capacitor_voltage.state;
    
        end if; -- rstn
    end process clocked_reset_generator;	
------------------------------------------------------------------------

end sim;
