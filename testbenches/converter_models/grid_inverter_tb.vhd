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

entity grid_inverter_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of grid_inverter_tb is

    constant clock_period      : time    := 1 ns;
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    constant stoptime_in_seconds : real := 10.0e-3;
    signal simulation_time : real := 0.0;

    signal multiplier : multiplier_record := init_multiplier;
    signal lcr_model  : lcr_model_record  := init_lcr_filter(inductance_is(470.0e-6), capacitance_is(20.0e-6), resistance_is(0.9));

    signal output_voltage   : real := 0.0;
    signal input_voltage    : real := 10.0;
    signal inductor_current : real := 0.0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait until simulation_time > stoptime_in_seconds;
        check(abs(output_voltage - input_voltage) < 50.0, "error in input and output voltages too high");
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

        file file_handler : text open write_mode is "inverter_simulation_results.dat";

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_multiplier(multiplier);
            create_test_lcr_filter(
                hw_multiplier     => multiplier,
                lcr_filter_object => lcr_model,
                load_current      => 0,
                u_in              => int_voltage(input_voltage));

            if lcr_filter_calculation_is_ready(lcr_model) or simulation_counter = 0 then
                request_lcr_filter_calculation(lcr_model);

                simulation_time <= simulation_time + simulation_time_step;
                write_to(file_handler,(0 => simulation_time+simulation_time_step,
                                       1 => real_voltage(get_inductor_current(lcr_model)),
                                       2 => real_voltage(get_capacitor_voltage(lcr_model))));
            end if;

            output_voltage   <= real_voltage(get_capacitor_voltage(lcr_model));
            inductor_current <= real_voltage(get_inductor_current(lcr_model));

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
