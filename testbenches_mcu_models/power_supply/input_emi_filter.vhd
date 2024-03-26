LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use std.textio.all;
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.write_pkg.all;

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

    signal realtime : real := 0.0;
    signal timestep : real := 1.0e-6;

    signal sequencer : natural := 1;

    signal current : real := 0.0;
    signal voltage : real := 0.0;
    signal r       : real := 100.0e-3;
    -- signal l       : real := timestep/50.0e-6;
    -- signal c       : real := timestep/100.0e-6;
    signal uin     : real := 1.0;

--  ---/\/\/\/\----######------/\/\/\/\----######---------/\/\/\/\---######----
--                         #                        #                         #   
--                         #                        #                         #   
--                         #                        #                         #   
--                      -------                  -------                   -------
--                      -------                  -------                   -------
--                         |                        |                         |   
--                         |                        |                         |   
--  ---------------------------------------------------------------------------
                        
    subtype real_array is real_number_array;
    signal il : real_array(0 to 2) := (others => 0.0);
    signal uc : real_array(0 to 2) := (others => 0.0);

    signal l : real_array(0 to 2) := (2.2e-6, 2.2e-6, 1000.0e-3);
    signal c : real_array(0 to 2) := (7.0e-6, 3.3e-6, 10.0e-6);

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait until realtime >= 10.0e-3;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

        type realarray is array (natural range <>) of real;
        variable ik : realarray(0 to 3) := (others => 0.0);
        variable uk : realarray(0 to 3) := (others => 0.0);
        variable i_load : real := 0.0;

        file file_handler : text open write_mode is "lcr_simulation_rk4_tb.dat";

        variable l_gain : real := 0.0;
        variable c_gain : real := 0.0;

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            if simulation_counter = 0 then
                init_simfile(file_handler, ("time", "volt", "curr"));
            end if;

            case sequencer is
                when 0 =>
                    ik(1) := (uin - voltage - current*r)*l_gain/2.0;
                    uk(1) := current*c_gain/2.0;

                    ik(2) := (uin - (voltage + uk(1)) - (current + ik(1))*r)*l_gain/2.0;
                    uk(2) := (current + ik(1))*c_gain/2.0;

                    ik(3) := (uin - (voltage + uk(2)) - (current + ik(2))*r)*l_gain;
                    uk(3) := (current + ik(2))*c_gain;

                    ik(4) := (uin - (voltage + uk(3)) - (current + ik(3))*r)*l_gain;
                    uk(4) := (current + ik(3))*c_gain;

                    current <= current + 1.0/6.0*(ik(0)*2.0 + 4.0*ik(1) + 2.0*ik(2) + ik(3));
                    voltage <= voltage + 1.0/6.0*(uk(0)*2.0 + 4.0*uk(1) + 2.0*uk(2) + uk(3));

                when 1 => 
                    realtime <= realtime + timestep;
                    write_to(file_handler,(realtime, voltage, current));

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
