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
    use math_library.pmsm_electrical_model_pkg.all;


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

    signal vd_input_voltage        : int18 := 500;
    signal vq_input_voltage        : int18 := -500;

    constant permanent_magnet_flux : int18 := 5000;
    constant number_of_pole_pairs  : int18 := 2;
    signal load_torque             : int18 := 1000;
    signal w_state_equation : int18 := 0;

    type iq_current_model_record is record
        iq_calculation_counter : natural range 0 to 15;
        iq_state_equation      : int18                ;
        Lq                     : int18                ;
        iq_current             : state_variable_record;
    end record;

    signal angular_speed : state_variable_record := init_state_variable_gain(5000);

    signal id_current_model : id_current_model_record    := init_id_current_model;
    signal iq_current_model : id_current_model_record    := init_id_current_model;

    alias rotor_resistance       is id_current_model.rotor_resistance      ;
    alias id_calculation_counter is id_current_model.id_calculation_counter;
    alias id_state_equation      is id_current_model.id_state_equation     ;
    alias Ld                     is id_current_model.Ld                    ;
    alias id_current             is id_current_model.id_current            ;

    signal iq_calculation_counter : natural range 0 to 15 := 15;
    signal iq_state_equation      : int18                 := 0;
    signal Lq                     : int18                 := 5000;
    signal iq_current             : state_variable_record := init_state_variable_gain(Lq);


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
            if simulation_counter = 10 then
                id_calculation_counter <= 0;
                iq_calculation_counter <= 0;
            end if;
            --------------------------------------------------

            CASE id_calculation_counter is
                -- calculate id state equation
                WHEN 0 =>
                    multiply(multiplier(id), rotor_resistance, id_current.state);
                    increment(id_calculation_counter);
                WHEN 1 =>
                    multiply(multiplier(id), angular_speed.state, iq_current.state);
                    increment(id_calculation_counter);
                WHEN 2 =>
                    if multiplier_is_ready(multiplier(id)) then
                        id_state_equation <= -get_multiplier_result(multiplier(id),15);
                        increment(id_calculation_counter);
                    end if;
                WHEN 3 =>
                    multiply(multiplier(id), Lq, get_multiplier_result(multiplier(id),15));
                    increment(id_calculation_counter);
                WHEN 4 =>
                    if multiplier_is_ready(multiplier(id)) then
                        id_state_equation <= id_state_equation + get_multiplier_result(multiplier(id),15) + vd_input_voltage;
                        increment(id_calculation_counter);
                        request_state_variable_calculation(id_current);
                    end if;
                WHEN others => -- hang here
            end CASE;

            CASE iq_calculation_counter is
                -- calculate iq state equation
                WHEN 0 =>
                    multiply(multiplier(iq), rotor_resistance, iq_current.state);
                    increment(iq_calculation_counter);
                WHEN 1 =>
                    multiply(multiplier(iq), permanent_magnet_flux, angular_speed.state);
                    increment(iq_calculation_counter);
                WHEN 2 =>
                    multiply(multiplier(iq), id_current.state, angular_speed.state);
                    increment(iq_calculation_counter);
                WHEN 3 =>
                    if multiplier_is_ready(multiplier(iq)) then
                        iq_state_equation <= - get_multiplier_result(multiplier(iq), 15);
                        increment(iq_calculation_counter);
                    end if;
                WHEN 4 =>
                    iq_state_equation <= iq_state_equation - get_multiplier_result(multiplier(iq), 15);
                    increment(iq_calculation_counter);
                WHEN 5 =>
                    multiply(multiplier(iq), Ld, get_multiplier_result(multiplier(iq), 15));
                    increment(iq_calculation_counter);
                WHEN 6 =>
                    if multiplier_is_ready(multiplier(iq)) then
                        iq_state_equation <= iq_state_equation - get_multiplier_result(multiplier(iq), 15) + vq_input_voltage;
                        increment(iq_calculation_counter);
                        request_state_variable_calculation(iq_current);
                    end if;
                WHEN 7 =>
                    if state_variable_calculation_is_ready(iq_current) then
                        id_calculation_counter <= 0;
                        iq_calculation_counter <= 0;
                    end if;
                WHEN others => -- hang here
            end CASE;
        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
