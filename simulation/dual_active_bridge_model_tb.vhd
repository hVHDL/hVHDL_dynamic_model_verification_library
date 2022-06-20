LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

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
    signal timer : integer := 0;
    signal leg1 : std_logic_vector(1 downto 0) := (others => '0');
    signal leg2 : std_logic_vector(1 downto 0) := (others => '0');

    signal state_counter : integer := 0;

    function get_dc_current
    (
        hb1 : std_logic_vector;
        hb2 : std_logic_vector
    )
    return real
    is
        variable dc_current : real;
    begin
        if hb1 /= hb2 then
            if hb1 = "10" then
                dc_current := 10.0;
            else
                dc_current := -10.0;
            end if;
        else
            dc_current := 0.0;
        end if;

        return dc_current;
    end get_dc_current;

    signal dc_link_current : real := 0.0;

    signal half_period : integer := 50;
    signal active_time : integer := 40;
    signal zero_time : integer := half_period-active_time;

    signal current : real := -41.0/2.0;

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

            if timer > 0 then
                timer <= timer - 1;
            end if;

            CASE state_counter is 
                WHEN 0 =>
                    leg1 <= "10";
                    leg2 <= "10";
                    if timer = 0 then
                        timer <= active_time;
                        state_counter <= state_counter + 1;
                    end if;
                    
                WHEN 1 =>
                    leg1 <= "10";
                    leg2 <= "01";
                    if timer = 0 then
                        timer <= zero_time;
                        state_counter <= state_counter + 1;
                    end if;
                WHEN 2 =>
                    leg1 <= "01";
                    leg2 <= "01";
                    if timer = 0 then
                        timer <= active_time;
                        state_counter <= state_counter + 1;
                    end if;
                WHEN 3 =>
                    leg1 <= "01";
                    leg2 <= "10";
                    if timer = 0 then
                        timer <= zero_time;
                        state_counter <= 0;
                    end if;
                WHEN others =>
            end CASE;

            dc_link_current <= get_dc_current(leg1, leg2);


            current <= current + get_dc_current(leg1, leg2)*0.1;


            if simulation_counter > 330 then
                active_time <= 10;
                zero_time <= half_period-10;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
