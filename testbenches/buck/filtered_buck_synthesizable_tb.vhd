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
    use work.filtered_buck_model_pkg.all;

entity filtered_buck_synthesizable_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of filtered_buck_synthesizable_tb is

    constant clock_period      : time    := 1 ns;
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

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

    constant simulation_time_step : real := 2.0e-6;

    signal output_voltage   : real := 0.0;
    signal inductor_current : real := 0.0;

    signal input_voltage : integer := to_fixed(400.0);
    signal load_current : integer := to_fixed(0.0);

    signal filtered_buck : filtered_buck_record := init_filtered_buck;

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

            create_filtered_buck(filtered_buck, to_fixed(0.5, 15), input_voltage, load_current);

            if simulation_counter = 0 then
                filtered_buck.input_lc1.capacitor_voltage.state <= to_fixed(400.0);
                filtered_buck.input_lc2.capacitor_voltage.state <= to_fixed(400.0);
            end if;

            if lcr_filter_calculation_is_ready(filtered_buck.primary_lc) or simulation_counter = 0 then
                request_filtered_buck_calculation(filtered_buck);
                simulation_time <= simulation_time + simulation_time_step;
                write_to(file_handler,(0  => simulation_time ,
                                       1  => to_real( get_inductor_current ( filtered_buck.primary_lc)) ,
                                       2  => to_real( get_capacitor_voltage( filtered_buck.primary_lc)) ,
                                       3  => to_real( get_inductor_current ( filtered_buck.input_lc1))  ,
                                       4  => to_real( get_capacitor_voltage( filtered_buck.input_lc1))  ,
                                       5  => to_real( get_inductor_current ( filtered_buck.input_lc2))  ,
                                       6  => to_real( get_capacitor_voltage( filtered_buck.input_lc2))  ,
                                       7  => to_real( get_inductor_current ( filtered_buck.output_lc1)) ,
                                       8  => to_real( get_capacitor_voltage( filtered_buck.output_lc1)) ,
                                       9  => to_real( get_inductor_current ( filtered_buck.output_lc2)) ,
                                       10 => to_real( get_capacitor_voltage( filtered_buck.output_lc2))
                                   ));
            end if;

            if (simulation_time = 10.0e-3) then
                load_current <= to_fixed(10.0);
            end if;

            if (simulation_time = 20.0e-3) then
                input_voltage <= to_fixed(390.0);
            end if;

            inductor_current <= to_real(get_inductor_current(filtered_buck.input_lc2));
            output_voltage   <= to_real(get_capacitor_voltage(filtered_buck.input_lc2));

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
