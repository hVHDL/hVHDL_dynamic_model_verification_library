LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

    use work.full_bridge_model_pkg.all;

entity tb_dual_actibe_bridge_model is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_dual_actibe_bridge_model is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 500;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal full_bridge : full_bridge_record := init_full_bridge;
    signal full_bridge2 : full_bridge_record := init_full_bridge;

    signal dc_link_current : real := 0.0;
    signal current : real := -41.0/2.0;
    signal inductor_voltage : real := 0.0;

    type int_array is array (integer range 0 to 3) of integer;
    signal counter : int_array := (0,0,0,0);

    signal dab_voltage : integer := 0;

    function get_dab_voltage
    (
        dab_carrier : integer;
        carrier_max : integer;
        active_time : integer
    )
    return integer
    is
        variable returned_voltage : integer;
        variable used_carrier : integer;
    begin

        used_carrier := abs(dab_carrier - carrier_max/2);
        if used_carrier > carrier_max/2 - active_time then
            returned_voltage := 1;
        elsif used_carrier < active_time then
            returned_voltage := -1;
        else
            returned_voltage := 0;
        end if;

        return returned_voltage;
    end get_dab_voltage;

    signal test_driving_from_two_processes : integer := 0;

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
        wait for clock_half_per;
        while simulation_running loop
            wait for clock_half_per;
                simulator_clock <= not simulator_clock;
            end loop;
        wait;
    end process;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            create_full_bridge(full_bridge);
            create_full_bridge(full_bridge2);

            dc_link_current  <= get_dc_current(full_bridge);
            current          <= current + (get_dc_current(full_bridge) - get_dc_current(full_bridge2))*0.1;
            inductor_voltage <= (get_dc_current(full_bridge) - get_dc_current(full_bridge2));

            CASE simulation_counter is
                WHEN 5 => set_active_time(full_bridge, 50, 100);
                          set_active_time(full_bridge2, 51, 100);
                WHEN 200 => 
                          set_active_time(full_bridge2, 48, 100);
                WHEN others => --do nothing
            end CASE;

            counter(0) <= counter(0) - 1;
            counter(1) <= counter(0);
            if counter(0) = 0 then
                counter(0) <= 99;
            end if;

            if simulation_counter < 150 then
                dab_voltage <= get_dab_voltage(counter(1), 99, 1);
            else
                dab_voltage <= get_dab_voltage(counter(1), 99, 20);
            end if;

            if simulation_counter < 10 then
                test_driving_from_two_processes <= 51;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
    testi : process(simulator_clock)
        
    begin
        if rising_edge(simulator_clock) then
            if simulation_counter > 10 then
                test_driving_from_two_processes <= 2356;
            end if;
        end if; --rising_edge
    end process testi;	
------------------------------------------------------------------------
end vunit_simulation;
