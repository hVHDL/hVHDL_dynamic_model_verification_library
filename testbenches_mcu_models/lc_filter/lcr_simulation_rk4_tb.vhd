LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

package ode_pkg is 

------------------------------------------
    impure function generic_rk2
    generic(impure function deriv (input : real_vector) return real_vector is <>)
    (
        state    : real_vector;
        stepsize : real
    ) return real_vector;
------------------------------------------
    impure function generic_rk4
    generic(impure function deriv (input : real_vector) return real_vector is <>)
    (
        state    : real_vector;
        stepsize : real
    ) return real_vector;
------------------------------------------

end package ode_pkg;

package body ode_pkg is

------------------------------------------
    function "+" (left : real_vector; right : real_vector) return real_vector is
        variable retval : left'subtype;
    begin

        for i in left'range loop
            retval(i) := left(i) + right(i);
        end loop;

        return retval;
    end function "+";
------------------------------------------
    function "/" (left : real_vector; right : real) return real_vector is
        variable retval : left'subtype;
    begin

        for i in left'range loop
            retval(i) := left(i) / right;
        end loop;

        return retval;
    end function "/";
------------------------------------------

    function "*" (left : real_vector; right : real) return real_vector is
        variable retval : left'subtype;
    begin

        for i in left'range loop
            retval(i) := left(i) * right;
        end loop;

        return retval;
    end function "*";
------------------------------------------
    impure function generic_rk2
    generic(impure function deriv (input : real_vector) return real_vector is <>)
    (
        state    : real_vector;
        stepsize : real

    ) return real_vector is
        type state_array is array(1 to 2) of real_vector(state'range);
        variable k : state_array;
        variable retval : real_vector(state'range);
    begin
        k(1) := deriv(state);
        k(2) := deriv(state + k(1) * stepsize/ 2.0);

        retval := state + k(2)*stepsize;

        return retval;
    end generic_rk2;

    impure function generic_rk4
    generic(impure function deriv (input : real_vector) return real_vector is <>)
    (
        state    : real_vector;
        stepsize : real

    ) return real_vector is
        type state_array is array(1 to 4) of real_vector(state'range);
        variable k : state_array;
        variable retval : real_vector(state'range);
    begin
        k(1) := deriv(state);
        k(2) := deriv(state + k(1) * stepsize/ 2.0);
        k(3) := deriv(state + k(2) * stepsize/ 2.0);
        k(4) := deriv(state + k(3) * stepsize);

        retval := state + (k(1) + k(2) * 2.0 + k(3) * 2.0 + k(4)) * stepsize/6.0;

        return retval;
    end generic_rk4;
------------------------------------------

end package body;

-----------------------------------------
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
    constant timestep : real := 1.0e-6;

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

        function rk2 is new generic_rk2 generic map(deriv_lcr);
        function rk4 is new generic_rk4 generic map(deriv_lcr);

        variable lcr : real_vector(0 to 1) := (0.0, 0.0);

        file file_handler : text open write_mode is "lcr_simulation_rk4_tb.dat";
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            if simulation_counter = 0 then
                init_simfile(file_handler, ("time", "T_u1", "B_i1"));
            end if;

            if simulation_counter > 0 then

                lcr := rk2(lcr, timestep);

                if realtime > 5.0e-3 then i_load := 2.0; end if;

                realtime <= realtime + timestep;
                write_to(file_handler,(realtime, lcr(0), lcr(1)));

            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
