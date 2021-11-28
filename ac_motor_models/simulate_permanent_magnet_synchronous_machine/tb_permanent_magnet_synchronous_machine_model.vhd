LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

library math_library;
    use math_library.multiplier_pkg.all;
    use math_library.sincos_pkg.all;
    use math_library.abc_to_ab_transform_pkg.all;
    use math_library.ab_to_abc_transform_pkg.all;
    use math_library.dq_to_ab_transform_pkg.all;
    use math_library.ab_to_dq_transform_pkg.all;
    use math_library.state_variable_pkg.all;


entity tb_permanent_magnet_synchronous_machine_model is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_permanent_magnet_synchronous_machine_model is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50e3;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    type abc is (phase_a, phase_b, phase_c, id, iq, w);

    type multiplier_array is array (abc range abc'left to abc'right) of multiplier_record;
    signal multiplier : multiplier_array := (init_multiplier, init_multiplier, init_multiplier, init_multiplier, init_multiplier, init_multiplier);

    type sincos_array is array (abc range abc'left to abc'right) of sincos_record;
    signal sincos : sincos_array := (init_sincos, init_sincos, init_sincos, init_sincos, init_sincos, init_sincos);

    signal angle_rad16 : unsigned(15 downto 0) := to_unsigned(10e3, 16);

    signal dq_to_ab_transform : dq_to_ab_record := init_dq_to_ab_transform;
    signal ab_to_dq_transform : ab_to_dq_record := init_ab_to_dq_transform;

    --------------------------------------------------
    -- motor simulation signals --

    signal id_current : state_variable_record    := init_state_variable_gain(500);
    signal iq_current : state_variable_record    := init_state_variable_gain(500);
    signal angular_speed : state_variable_record := init_state_variable_gain(500);

    signal vd_input_voltage        : int18 := 500;
    signal vq_input_voltage        : int18 := -500;

    constant permanent_magnet_flux : int18 := 5000;
    constant number_of_pole_pairs  : int18 := 2;
    signal load_torque             : int18 := 1000;
    signal rotor_resistance        : int18 := 1000;

    signal motor_model_multiplier_counter : natural range 0 to 15 := 15;
    signal motor_model_process_counter : natural range 0 to 15 := 15;

    signal id_state_equation : int18 := 0;
    signal iq_state_equation : int18 := 0;
    signal w_state_equation : int18 := 0;
    signal Ld : int18 := 5000;
    signal Lq : int18 := 5000;

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
            --------------------------------------------------
            simulation_counter <= simulation_counter + 1;

            --------------------------------------------------
            create_multiplier(multiplier(id));
            create_multiplier(multiplier(iq));
            create_multiplier(multiplier(w));

            create_state_variable(id_current    , multiplier(id) , id_state_equation);
            create_state_variable(iq_current    , multiplier(iq) , iq_state_equation);
            create_state_variable(angular_speed , multiplier(w)  , w_state_equation);

            --------------------------------------------------
            CASE motor_model_multiplier_counter is
                -- calculate id state equation
                WHEN 0 =>
                    multiply(multiplier(id), rotor_resistance, id_current.state);
                    increment(motor_model_multiplier_counter);
                WHEN 1 =>
                    multiply(multiplier(id), angular_speed.state, iq_current.state);
                    increment(motor_model_multiplier_counter);
                WHEN 2 =>
                    if multiplier_is_ready(multiplier(id)) then
                        id_state_equation <= -get_multiplier_result(multiplier(id),15);
                        increment(motor_model_multiplier_counter);
                    end if;
                WHEN 3 =>
                    multiply(multiplier(id), Lq, get_multiplier_result(multiplier(id),15));
                    increment(motor_model_multiplier_counter);
                WHEN 4 =>
                    if multiplier_is_ready(multiplier(id)) then
                        id_state_equation <= id_state_equation + get_multiplier_result(multiplier(id),15) + vd_input_voltage;
                        increment(motor_model_multiplier_counter);
                    end if;
                -- calculate iq state equation
                WHEN 5 =>
                    multiply(multiplier(id), rotor_resistance, iq_current.state);
                    increment(motor_model_multiplier_counter);
                WHEN 6 =>
                    multiply(multiplier(id), permanent_magnet_flux, angular_speed.state);
                    increment(motor_model_multiplier_counter);
                WHEN 7 =>
                    multiply(multiplier(id), id_current.state, angular_speed.state);
                    increment(motor_model_multiplier_counter);
                WHEN 8 =>
                    if multiplier_is_ready(multiplier(id)) then
                        iq_state_equation <= - get_multiplier_result(multiplier(id), 15);
                        increment(motor_model_multiplier_counter);
                    end if;
                WHEN 9 =>
                    iq_state_equation <= iq_state_equation - get_multiplier_result(multiplier(id), 15);
                    increment(motor_model_multiplier_counter);
                WHEN 10 =>
                    multiply(multiplier(id), Ld, get_multiplier_result(multiplier(id), 15));
                    increment(motor_model_multiplier_counter);
                WHEN 11 =>
                    if multiplier_is_ready(multiplier(id)) then
                        iq_state_equation <= iq_state_equation - get_multiplier_result(multiplier(id), 15) + vq_input_voltage;
                        increment(motor_model_multiplier_counter);
                        request_state_variable_calculation(id_current);
                        request_state_variable_calculation(iq_current);
                    end if;
                WHEN 12 =>
                    if state_variable_calculation_is_ready(id_current) then
                        motor_model_multiplier_counter <= 0;
                    end if;

                WHEN others => -- hang here
            end CASE;
        --------------------------------------------------
            if simulation_counter = 10 then
                motor_model_multiplier_counter <= 0;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
