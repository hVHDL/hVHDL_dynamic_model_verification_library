LIBRARY ieee, std  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.multiplier_pkg.all;
    use work.lcr_filter_model_pkg.all;
    use work.simulation_pkg.all;
    use work.write_pkg.all;

entity grid_inverter_current_step_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of grid_inverter_current_step_tb is

    constant clock_period      : time    := 1 ns;
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    constant L1_inductance : real := 1.0e-3;
    constant L2_inductance : real := 1.0e-3;
    constant L3_inductance : real := 1.0e-3;

    constant C1_capacitance : real := 10.0e-6;
    constant C2_capacitance : real := 3.3e-6;
    constant C3_capacitance : real := 7.0e-6;

    constant simulation_time_step : real := 0.3e-6;
    constant stoptime         : real := 2.0e-3;
    signal simulation_time    : real := 0.0;
    ----
    signal primary_lc : lcr_model_record := init_lcr_filter(inductance_is(1000.0e-6) , capacitance_is(10.0e-6) , resistance_is(0.2));
    signal emi_lc_0   : lcr_model_record := init_lcr_filter(inductance_is(4.0e-6)    , capacitance_is(3.3e-6)  , resistance_is(50.0e-3));
    signal emi_lc_1   : lcr_model_record := init_lcr_filter(inductance_is(4.0e-6)    , capacitance_is(7.0e-6)  , resistance_is(50.0e-3));

    signal multiplier_1 : multiplier_record := init_multiplier;
    signal multiplier_2 : multiplier_record := init_multiplier;
    signal multiplier_3 : multiplier_record := init_multiplier;
    signal output_voltage   : real := 0.0;
    signal input_voltage    : real := 325.0;
    signal inductor_current : real := 0.0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait until simulation_time > stoptime;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

        file file_handler : text open write_mode is "grid_inverter_inductor_step.dat";

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            create_multiplier(multiplier_1);
            create_multiplier(multiplier_2);
            create_multiplier(multiplier_3);

            create_test_lcr_filter( multiplier_1 , primary_lc , get_inductor_current(emi_lc_0) , 0);
            create_test_lcr_filter( multiplier_2 , emi_lc_0   , get_inductor_current(emi_lc_1) , get_capacitor_voltage(primary_lc));
            create_test_lcr_filter( multiplier_3 , emi_lc_1   , 0                              , get_capacitor_voltage(emi_lc_0));

            if lcr_filter_calculation_is_ready(primary_lc) or simulation_counter = 0 then
                request_lcr_filter_calculation(primary_lc);
                request_lcr_filter_calculation(emi_lc_0);
                request_lcr_filter_calculation(emi_lc_1);

                simulation_time <= simulation_time + simulation_time_step;
                write_to(file_handler,(0 => simulation_time,
                                       1 => real_voltage(get_inductor_current(primary_lc))  ,
                                       2 => real_voltage(get_capacitor_voltage(primary_lc)) ,
                                       3 => real_voltage(get_inductor_current(emi_lc_0))    ,
                                       4 => real_voltage(get_capacitor_voltage(emi_lc_0))   ,
                                       5 => real_voltage(get_inductor_current(emi_lc_1))    ,
                                       6 => real_voltage(get_capacitor_voltage(emi_lc_1))
                                   ));
            end if;

            inductor_current <= real_voltage(get_inductor_current(emi_lc_1));
            output_voltage   <= real_voltage(get_capacitor_voltage(emi_lc_1));

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
