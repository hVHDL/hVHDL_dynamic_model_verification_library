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
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal realtime : real := 0.0;
    constant timestep : real := 1.0e-6;

    signal current : real := 0.0;
    signal voltage : real := 0.0;
    signal r       : real := 100.0e-3;
    signal l       : real := timestep/50.0e-6;
    signal c       : real := timestep/100.0e-6;
    signal uin     : real := 1.0;

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

        function deriv_lcr (states : real_vector) return real_vector is
            variable retval : real_vector(0 to 1) := (0.0, 0.0);
            constant l : real := 100.0e-6;
            constant c : real := 100.0e-6;
        begin
            retval(0) := (10.0 - states(0) * 0.1 - states(1)) * (1.0/l);
            retval(1) := (states(0)) * (1.0/c);
            return retval;
        end function;

        function "+" (left : real_vector; right : real_vector) return real_vector is
            variable retval : left'subtype;
        begin

            for i in left'range loop
                retval(i) := left(i) + right(i);
            end loop;

            return retval;
        end function;

        function "/" (left : real_vector; right : real) return real_vector is
            variable retval : left'subtype;
        begin

            for i in left'range loop
                retval(i) := left(i) / right;
            end loop;

            return retval;
        end function;

        function "*" (left : real_vector; right : real) return real_vector is
            variable retval : left'subtype;
        begin

            for i in left'range loop
                retval(i) := left(i) * right;
            end loop;

            return retval;
        end function;

        function generic_rk4
        generic(function deriv (input : real_vector) return real_vector is <>)
        (
            state    : real_vector;
            stepsize : real

        ) return real_vector is
            type state_array is array(1 to 4) of real_vector(0 to 1);
            variable k : state_array;
            variable retval : real_vector(0 to 1);
        begin
            k(1) := deriv(state);
            k(2) := deriv(state + k(1) * stepsize/ 2.0);
            k(3) := deriv(state + k(2) * stepsize/ 2.0);
            k(4) := deriv(state + k(3) * stepsize);

            retval := state + (k(1) + k(2) * 2.0 + k(3) * 2.0 + k(4)) *stepsize/6.0;

            return retval;
        end generic_rk4;

        function rk4 is new generic_rk4 generic map(deriv_lcr);

        variable ik : real_vector(1 to 4) := (others => 0.0);
        variable uk : real_vector(1 to 4) := (others => 0.0);

        variable lcr : real_vector(0 to 1) := (0.0, 0.0);

        file file_handler : text open write_mode is "lcr_simulation_rk4_tb.dat";
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            if simulation_counter = 0 then
                init_simfile(file_handler, ("time", "T_u1", "B_i1"));
            end if;

            if simulation_counter > 0 then
                ik(1) := (uin - voltage - current*r)*l/2.0;
                uk(1) := current*c/2.0;

                ik(2) := (uin - (voltage + uk(1)) - (current + ik(1))*r)*l/2.0;
                uk(2) := (current + ik(1))*c/2.0;

                ik(3) := (uin - (voltage + uk(2)) - (current + ik(2))*r)*l;
                uk(3) := (current + ik(2))*c;

                ik(4) := (uin - (voltage + uk(3)) - (current + ik(3))*r)*l;
                uk(4) := (current + ik(3))*c;

                current <= current + 1.0/6.0 * (ik(1) * 2.0 + 4.0 * ik(2) + 2.0 * ik(3) + ik(4));
                voltage <= voltage + 1.0/6.0 * (uk(1) * 2.0 + 4.0 * uk(2) + 2.0 * uk(3) + uk(4));

                lcr := rk4(lcr, timestep);

                realtime <= realtime + timestep;
                write_to(file_handler,(realtime, lcr(0), lcr(1)));

            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
