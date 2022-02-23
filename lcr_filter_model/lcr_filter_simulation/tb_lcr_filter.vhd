LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.multiplier_pkg.all;
    use work.lcr_filter_model_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity tb_lcr_filter is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_lcr_filter is
    signal rstn : std_logic;

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    signal clocked_reset : std_logic;
    constant clock_per : time := 8.4 ns;
    constant clock_half_per : time := 4.2 ns;
    constant simtime_in_clocks : integer := 25e3;

    signal simulation_counter : natural := 0;

    signal hw_multiplier : multiplier_record := multiplier_init_values;
    signal hw_multiplier2 : multiplier_record := multiplier_init_values;
    signal hw_multiplier3 : multiplier_record := multiplier_init_values;
------------------------------------------------------------------------
    signal simulation_trigger_counter : natural := 0;
------------------------------------------------------------------------
    -- lrc model signals
    signal input_voltage   : int18 := 3000;
    signal load_resistance : int18 := 10;
    signal load_current    : int18 := 3000;

    signal lcr_filter : lcr_model_record := init_lcr_model_integrator_gains(25e3, 2e3);
    signal lcr_filter2 : lcr_model_record := init_lcr_model_integrator_gains(25e3, 2e3);
    signal lcr_filter3 : lcr_model_record := init_lcr_model_integrator_gains(25e3, 2e3);

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

    clocked_reset_generator : process(simulator_clock)
    --------------------------------------------------
        impure function "*" ( left, right : int18)
        return int18
        is
        begin
            sequential_multiply(hw_multiplier2, left, right);
            return get_multiplier_result(hw_multiplier, 15);
        end "*";
    --------------------------------------------------

    begin
        if rising_edge(simulator_clock) then

            create_multiplier(hw_multiplier); 
            create_multiplier(hw_multiplier2); 
            create_multiplier(hw_multiplier3); 

            create_lcr_filter(lcr_filter  , hw_multiplier  , input_voltage - lcr_filter.capacitor_voltage.state                        , lcr_filter.inductor_current.state - lcr_filter2.inductor_current.state);
            create_lcr_filter(lcr_filter2 , hw_multiplier2 , lcr_filter.capacitor_voltage.state - lcr_filter2.capacitor_voltage.state  , lcr_filter2.inductor_current.state - lcr_filter3.inductor_current.state);
            create_lcr_filter(lcr_filter3 , hw_multiplier3 , lcr_filter2.capacitor_voltage.state - lcr_filter3.capacitor_voltage.state , lcr_filter3.inductor_current.state - load_current);

            simulation_counter <= simulation_counter + 1;

            simulation_trigger_counter <= simulation_trigger_counter + 1;
            if simulation_trigger_counter = 19 then
                simulation_trigger_counter <= 0;
                calculate_lcr_filter(lcr_filter);
                calculate_lcr_filter(lcr_filter2);
                calculate_lcr_filter(lcr_filter3);
            end if;

            input_voltage <= 3e3;
            if simulation_counter mod 6000 = 0  then
                load_current <= -load_current;
            end if;


        end if; -- rstn
    end process clocked_reset_generator;	

------------------------------------------------------------------------
end vunit_simulation;
