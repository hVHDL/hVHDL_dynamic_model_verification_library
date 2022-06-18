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


    signal buck_converter : buck_converter_record := init_buck_converter(50.0e-6, 100.0e-6, 10.0e-9);
    signal current : real := 0.0;
    signal voltage : real := 0.0;
    signal pwm_out : std_logic := '0';

    signal pwm_carrier : integer := 0;

    signal carrier_max : integer := 500;

    signal sampled_current : integer := 0;
    signal sampled_voltage : integer := 0;
    signal duty_ratio : integer := 150;

    -- signal multiplier : multiplier_record := init_multiplier;

    signal multiplier_counter : integer := 0;

    constant radix : integer := 20;

    function to_radix15
    (
        number : real range -8.0 to 8.0
    )
    return integer
    is
    begin
        return integer(number * 2.0**radix);
    end to_radix15;

------------------------------------------------------------------------
    function "*"
    (
        left, right : integer
    )
    return integer
    is
        variable result : signed(63 downto 0);
    begin
        result := to_signed(left,32) * to_signed(right,32);

        return to_integer(result(31+radix downto 0+radix));
    end "*";
------------------------------------------------------------------------
    signal pi_out : integer := 0;
    signal integrator : integer := 0;

    signal v_pi_out     :  integer := 0;
    signal v_integrator :  integer := 0;

    signal request_pi_control_calculation : boolean := false;
------------------------------------------------------------------------

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

            create_buck_converter(buck_converter, 100.0, pwm_out);

            pwm_carrier <= (pwm_carrier + 1) mod carrier_max;
            if pwm_carrier < pi_out then
                pwm_out <= '1';
            else
                pwm_out <= '0';
            end if;

            if simulation_counter > 176900 and simulation_counter < 183000 then
                buck_converter.load_resistance <= 100.0;
            end if;

            request_pi_control_calculation <= false;
            if pwm_carrier = pi_out/2 or pwm_carrier = carrier_max - (carrier_max - pi_out)/2 then
                sampled_voltage <= integer(get_voltage(buck_converter)/256.0*32768.0);
                sampled_current <= integer(get_current(buck_converter)/256.0*32768.0);
                request_pi_control_calculation <= true;

            end if;

            if request_pi_control_calculation then

                pi_out <= (v_pi_out-sampled_current) * to_radix15(0.2) + integrator;
                integrator <= integrator + (v_pi_out-sampled_current) * to_radix15(0.03);

                v_pi_out     <= (8200-sampled_voltage) * to_radix15(0.80) + v_integrator;
                v_integrator <= v_integrator + (8200-sampled_voltage) * to_radix15(0.04);
            end if;

            if pi_out < 10 then pi_out <= 10; end if;
            if pi_out > 490 then pi_out <= 490; end if;

            voltage <= get_voltage(buck_converter);
            current <= get_current(buck_converter);

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
