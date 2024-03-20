LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity lcr_simulation_rk4_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of lcr_simulation_rk4_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 50000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----
    signal sequencer : natural := 0;

    signal current : real := 0.0;
    signal voltage : real := 0.0;
    signal r : real := 0.00;
    signal c : real := 0.1;
    signal l : real := 0.1;
    signal uin : real := 1.0;

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

        type realarray is array (natural range <>) of real;
        variable ik : realarray(1 to 4) := (others => 0.0);
        variable uk : realarray(1 to 4) := (others => 0.0);

        -- function calcu
        -- (
        --     
        -- )
        -- return 
        -- is
        -- begin
        --     
        -- end calcu;
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            case sequencer is
                when 0 =>
                    ik(1) := (uin - voltage - current*r)*l/2.0;
                    uk(1) := current*c/2.0;

                    ik(2) := (uin - (voltage + uk(1)) - (current + ik(1))*r)*l/2.0;
                    uk(2) := (current + ik(1))*c/2.0;

                    ik(3) := (uin - (voltage + uk(2)) - (current + ik(2))*r)*l;
                    uk(3) := (current + ik(2))*c;

                    ik(4) := (uin - (voltage + uk(3)) - (current + ik(3))*r)*l;
                    uk(4) := (current + ik(3))*c;

                    -- current <= current + ik(1) * 0.5 + ik(2);
                    -- voltage <= voltage + uk(1) * 0.5 + uk(2);

                    -- current <= current + (uin - voltage - current*r)*l;
                    -- voltage <= voltage + current*c;

                    current <= current + 1.0/6.0*(ik(1)*2.0 + 4.0*ik(2) + 2.0*ik(3) + ik(4));
                    voltage <= voltage + 1.0/6.0*(uk(1)*2.0 + 4.0*uk(2) + 2.0*uk(3) + uk(4));
                when others => --do nothing
            end case;

            sequencer <= sequencer + 1;
            if sequencer > 0 then
                sequencer <= 0;
            end if;


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
