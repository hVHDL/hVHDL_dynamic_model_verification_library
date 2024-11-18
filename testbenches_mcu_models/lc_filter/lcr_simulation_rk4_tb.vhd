LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.write_pkg.all;
    use work.ode_pkg.all;

entity lcr_simulation_rk4_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of lcr_simulation_rk4_tb is

    constant clock_period      : time    := 1 ns;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal realtime : real := 0.0;
    constant timestep : real := 10.0e-6;
    constant stoptime : real := 10.0e-3;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait until realtime >= stoptime;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

        variable u_in : real := 10.0;
        variable i_load : real := 0.0;

        impure function deriv_lcr (states : real_vector) return real_vector is
            variable retval : real_vector(0 to 1) := (0.0, 0.0);
            constant l : real := 100.0e-6;
            constant c : real := 100.0e-6;
        begin
            retval(0) := (u_in - states(0) * 0.1 - states(1)) * (1.0/l);
            retval(1) := (states(0) - i_load) * (1.0/c);
            return retval;
        end function;

        procedure rk1 is new generic_rk1 generic map(deriv_lcr);
        procedure rk2 is new generic_rk2 generic map(deriv_lcr);
        procedure rk4 is new generic_rk4 generic map(deriv_lcr);

        variable k : am_array := (others => (others => 0.0));
        procedure am2 is new am2_generic generic map(deriv_lcr);
        procedure am4 is new am4_generic generic map(deriv_lcr);

        variable lcr     : real_vector(0 to 1) := (0.0, 0.0);
        variable lcr_rk1 : real_vector(0 to 1) := (0.0, 0.0);
        variable lcr_rk2 : real_vector(0 to 1) := (0.0, 0.0);

        file file_handler : text open write_mode is "lcr_simulation_rk4_tb.dat";
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            if simulation_counter = 0 then
                init_simfile(file_handler, ("time", "T_u0","T_u1","T_u2", "B_i0","B_i1","B_i2"));
            end if;

            if simulation_counter > 0 then

                rk1(lcr_rk1, timestep);
                am2(k,lcr, timestep);
                rk2(lcr_rk2, timestep);

                if realtime > 5.0e-3 then i_load := 2.0; end if;

                realtime <= realtime + timestep;
                write_to(file_handler,(realtime, lcr_rk1(0),lcr(0), lcr_rk2(0), lcr_rk1(1),lcr(1), lcr_rk2(1)));

            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
