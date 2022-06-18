LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.buck_converter_model_pkg.all;

entity test_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of test_tb is

    constant clock_period      : time    := 10.0 ns;
    constant simtime_in_clocks : integer := integer(1500000.0/2.5);
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----


    signal buck_converter : buck_converter_record := init_buck_converter(10.0e-6, 50.0e-6, 10.0e-9);
    signal current : real := 0.0;
    signal voltage : real := 0.0;
    signal pwm_out : std_logic := '0';

    signal pwm_carrier : integer := 0;

    signal carrier_max : integer := 500;

    signal sampled_current : integer := 0;
    signal sampled_voltage : integer := 0;
    signal duty_ratio : integer := 150;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            pwm_carrier <= (pwm_carrier + 1) mod carrier_max;
            if pwm_carrier < duty_ratio then
                pwm_out <= '1';
            else
                pwm_out <= '0';
            end if;

            create_buck_converter(buck_converter, pwm_out);

            if simulation_counter > 176900 and simulation_counter < 183000 then
                buck_converter.voltage <= 0.0;
            end if;

            if pwm_carrier = duty_ratio/2 or pwm_carrier = carrier_max - (carrier_max - duty_ratio)/2 then
                sampled_voltage <= integer(get_voltage(buck_converter)/256.0*32768.0);
                sampled_current <= integer(get_current(buck_converter)/256.0*32768.0);
            end if;

            voltage <= get_voltage(buck_converter);
            current <= get_current(buck_converter);

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
