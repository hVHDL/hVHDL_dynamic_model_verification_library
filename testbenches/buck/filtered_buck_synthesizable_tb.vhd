LIBRARY ieee, std  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.multiplier_pkg.all;
    use work.lcr_filter_model_pkg.all;
    use work.write_pkg.all;
    use work.real_to_fixed_pkg.all;

entity filtered_buck_synthesizable_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of filtered_buck_synthesizable_tb is

    constant clock_period      : time    := 1 ns;
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

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

    constant simulation_time_step : real := 2.0e-6;
    constant stoptime             : real := 30.0e-3;
    signal simulation_time        : real := 0.0;

    constant int_radix            : integer := int_word_length-1;

    ----
    constant scale_value : real := 2.0**10;

    impure function to_fixed
    (
        input_number : real
    )
    return integer
    is
    begin
        return to_fixed(input_number/scale_value, int_radix);
    end to_fixed;
    ----

    signal input_lc1  : lcr_model_record := init_lcr_filter(L2_inductance , C2_capacitance , 10.0e-3  , simulation_time_step , int_radix);
    signal input_lc2  : lcr_model_record := init_lcr_filter(L3_inductance , C3_capacitance , 0.0      , simulation_time_step , int_radix);
    signal primary_lc : lcr_model_record := init_lcr_filter(L1_inductance , C1_capacitance , 300.0e-3 , simulation_time_step , int_radix);
    signal output_lc1 : lcr_model_record := init_lcr_filter(L4_inductance , C4_capacitance , 0.0      , simulation_time_step , int_radix);
    signal output_lc2 : lcr_model_record := init_lcr_filter(L5_inductance , C5_capacitance , 0.0      , simulation_time_step , int_radix);

    signal multiplier_1 : multiplier_record := init_multiplier;
    signal multiplier_2 : multiplier_record := init_multiplier;
    signal multiplier_3 : multiplier_record := init_multiplier;
    signal multiplier_4 : multiplier_record := init_multiplier;
    signal multiplier_5 : multiplier_record := init_multiplier;
    signal output_voltage   : real := 0.0;
    signal inductor_current : real := 0.0;

    signal input_voltage : integer := to_fixed(400.0);
    signal load_current : integer := to_fixed(0.0);

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


        ------------------------------
        impure function to_real
        (
            number : integer
        )
        return real
        is
        begin
            return to_real(number , int_radix)*scale_value;
        end to_real;
        ------------------------------
        function "="
        (
            left, right : real
        )
        return boolean
        is
            variable return_value : boolean := false;
        begin

            if abs(left-right) < 1.0e-6 then
                return_value := true;
            else
                return_value := false;
            end if;

            return return_value;
            
        end "=";
        ------------------------------

        file file_handler : text open write_mode is "filtered_buck.dat";
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            if simulation_counter = 0 then
                input_lc1.capacitor_voltage.state <= to_fixed(400.0);
                input_lc2.capacitor_voltage.state <= to_fixed(400.0);
            end if;
            create_multiplier(multiplier_1);
            create_multiplier(multiplier_2);
            create_multiplier(multiplier_3);
            create_multiplier(multiplier_4);
            create_multiplier(multiplier_5);

            create_lcr_filter(input_lc1  , multiplier_1 , get_inductor_current(input_lc2)    , input_voltage                      , int_radix);
            create_lcr_filter(input_lc2  , multiplier_2 , get_inductor_current(primary_lc)/2 , get_capacitor_voltage(input_lc1)   , int_radix);
            create_lcr_filter(primary_lc , multiplier_3 , get_inductor_current(output_lc1)   , get_capacitor_voltage(input_lc2)/2 , int_radix);
            create_lcr_filter(output_lc1 , multiplier_4 , get_inductor_current(output_lc2)   , get_capacitor_voltage(primary_lc)  , int_radix);
            create_lcr_filter(output_lc2 , multiplier_5 , load_current                       , get_capacitor_voltage(output_lc1)  , int_radix);

            if lcr_filter_calculation_is_ready(primary_lc) or simulation_counter = 0 then
                request_lcr_filter_calculation(input_lc1 );
                request_lcr_filter_calculation(input_lc2 );
                request_lcr_filter_calculation(primary_lc);
                request_lcr_filter_calculation(output_lc1);
                request_lcr_filter_calculation(output_lc2);

                simulation_time <= simulation_time + simulation_time_step;
                write_to(file_handler,(0  => simulation_time ,
                                       1  => to_real( get_inductor_current ( primary_lc)) ,
                                       2  => to_real( get_capacitor_voltage( primary_lc)) ,
                                       3  => to_real( get_inductor_current ( input_lc1))  ,
                                       4  => to_real( get_capacitor_voltage( input_lc1))  ,
                                       5  => to_real( get_inductor_current ( input_lc2))  ,
                                       6  => to_real( get_capacitor_voltage( input_lc2))  ,
                                       7  => to_real( get_inductor_current ( output_lc1)) ,
                                       8  => to_real( get_capacitor_voltage( output_lc1)) ,
                                       9  => to_real( get_inductor_current ( output_lc2)) ,
                                       10 => to_real( get_capacitor_voltage( output_lc2))
                                   ));
            end if;

            if (simulation_time = 10.0e-3) then
                load_current <= to_fixed(10.0);
            end if;

            if (simulation_time = 20.0e-3) then
                input_voltage <= to_fixed(390.0);
            end if;

            inductor_current <= to_real(get_inductor_current(input_lc2));
            output_voltage   <= to_real(get_capacitor_voltage(input_lc2));

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
