LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity half_bridge_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of half_bridge_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 500;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal bridge_voltage       : real := 0.0;
    signal dc_link_side_current : real := 0.0;
    signal dc_link_voltage      : real := 100.0;
    signal bridge_current       : real := 5.0;
    signal duty_ratio_0_to_1    : real := 0.5;
    signal dc_link_current      : real := 0.0;

    type bridge_output_record is record
        bridge_voltage  : real;
        dc_link_current : real;
    end record;

    type bridge_input_record is record
        duty_ratio      : real;
        bridge_current  : real;
        dc_link_voltage : real;
    end record;

    function calculate_half_bridge
    (
        bridge_inputs : bridge_input_record
    )
    return bridge_output_record
    is
        variable returned_values : bridge_output_record;
    begin

        returned_values := (
            bridge_voltage  => bridge_inputs.duty_ratio * bridge_inputs.dc_link_voltage,
            dc_link_current => bridge_inputs.duty_ratio * bridge_inputs.bridge_current);

        return returned_values;

    end calculate_half_bridge;

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

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
