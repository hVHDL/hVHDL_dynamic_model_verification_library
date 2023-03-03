LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity buck_with_input_and_output_filters_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of buck_with_input_and_output_filters_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 30e3*2;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    constant timestep : real := 1.0e-6; --seconds
    constant inductor : real := 1000.0e-6;
    constant capacitor : real := 42.2e-6;
    constant inductor_gain : real := timestep/inductor;
    constant capacitor_gain : real := timestep/capacitor;

    constant inductor1_gain : real := timestep/100.0e-6;
    constant capacitor1_gain : real := timestep/100.0e-6;

    constant inductor2_gain : real := timestep/10.0e-6;
    constant capacitor2_gain : real := timestep/10.0e-6;

    signal current1 : real := 0.0;
    signal voltage1 : real := 400.0;

    signal current2 : real := 0.0;
    signal voltage2 : real := 400.0;

    signal current : real := 0.0;
    signal voltage : real := 0.0;
    signal counter : integer := 0;
    signal realtime : real := 0.0;
    signal duty : real := 0.5;
    signal input_voltage : real := 400.0;
    signal load_current : real := 0.0;

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

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            counter <= simulation_counter mod 2;
            CASE counter is
                WHEN 0 => current2 <= current2 + inductor2_gain*(-0.01*current2 + input_voltage - voltage2);
                WHEN 1 => voltage2 <= voltage2 + capacitor2_gain*(current2 - current1);
                WHEN others => --do nothing
            end CASE;

            CASE counter is
                WHEN 0 => current1 <= current1 + inductor1_gain*(voltage2 - voltage1);
                WHEN 1 => voltage1 <= voltage1 + capacitor1_gain*(current1 - current*duty);
                WHEN others => --do nothing
            end CASE;

            CASE counter is
                WHEN 0 => current <= current + inductor_gain*(-0.3*current + voltage1*duty - voltage);
                WHEN 1 => voltage <= voltage + capacitor_gain*(current - load_current);
                WHEN others => --do nothing
            end CASE;


            if counter = 1 then
                realtime <= realtime + timestep;
            end if;
            
            if (realtime = 10.0e-3) then
                load_current <= 10.0;
            end if;

            if (realtime = 20.0e-3) then
                input_voltage <= 390.0;
            end if;


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
