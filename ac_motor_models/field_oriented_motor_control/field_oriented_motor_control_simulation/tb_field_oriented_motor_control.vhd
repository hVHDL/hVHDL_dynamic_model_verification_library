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
    use math_library.permanent_magnet_motor_model_pkg.all;
    use math_library.state_variable_pkg.all;

entity tb_field_oriented_motor_control is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_field_oriented_motor_control is

    signal simulation_running  : boolean    := false  ;
    signal simulator_clock     : std_logic  := '0'    ;
    constant clock_per         : time       := 1 ns   ;
    constant clock_half_per    : time       := 0.5 ns ;
    constant simtime_in_clocks : integer    := 5e3   ;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    type abc is (vd, phase_a, phase_b, phase_c, id, iq, w, angle);

    type multiplier_array is array (abc range abc'left to abc'right) of multiplier_record;
    signal multiplier : multiplier_array := (init_multiplier,init_multiplier, init_multiplier, init_multiplier, init_multiplier, init_multiplier, init_multiplier, init_multiplier);

    type sincos_array is array (abc range abc'left to abc'right) of sincos_record;
    signal sincos : sincos_array := (init_sincos, init_sincos, init_sincos, init_sincos, init_sincos, init_sincos, init_sincos, init_sincos);

    signal angle_rad16 : unsigned(15 downto 0) := to_unsigned(10e3, 16);

    signal dq_to_ab_transform : dq_to_ab_record := init_dq_to_ab_transform;
    signal ab_to_dq_transform : ab_to_dq_record := init_ab_to_dq_transform;

    --------------------------------------------------
    -- motor electrical simulation signals --

    signal vd_input_voltage : int18 := 300;
    signal vq_input_voltage : int18 := -300;

    signal pmsm_model : permanent_magnet_motor_model_record := init_permanent_magnet_motor_model;

    alias id_multiplier is multiplier(id);
    alias iq_multiplier is multiplier(iq);
    alias w_multiplier is multiplier(w);

    --------------------------------------------------

    signal rotor_angle : int18 := 0;

    signal vd_control_process_counter : natural range 0 to 15 := 15;
    signal vd_control_process_counter2 : natural range 0 to 15 := 15;

    alias control_multiplier is multiplier(vd);
    signal stator_resistance : int18 := 100;
    signal id_current : int18 := 0;
    signal iq_current : int18 := 0;
    signal angular_speed : int18 := 0;
    signal vd_kp : int18 := 5000;
    signal vd_ki : int18 := 500;
    signal control_input : int18 := 0;
    signal q_inductance : int18 := 500;

    signal integrator : int18 := 0;
    signal pi_output_buffer : int18 := 0;
    signal intermediat2 : int18 := 0;
    signal pi_output : int18 := 0;

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
            create_multiplier(multiplier(angle));

            create_multiplier(multiplier(phase_a));
            create_sincos(multiplier(phase_a) , sincos(phase_a));

            create_multiplier(multiplier(phase_b));
            create_dq_to_ab_transform(multiplier(phase_b), dq_to_ab_transform);

            request_sincos(sincos(phase_a), get_electrical_angle(pmsm_model));

            --------------------------------------------------
            create_pmsm_model(
                pmsm_model        ,
                multiplier(id)    ,
                multiplier(iq)    ,
                multiplier(w)     ,
                multiplier(angle) );
            --------------------------------------------------

            if simulation_counter = 10 or angular_speed_calculation_is_ready(pmsm_model) then
                request_angular_speed_calculation(pmsm_model);
                request_electrical_angle_calculation(pmsm_model);
                request_id_calculation(pmsm_model , vd_input_voltage);
                request_iq_calculation(pmsm_model , vq_input_voltage );

                request_dq_to_ab_transform(
                    dq_to_ab_transform          ,
                    get_sine(sincos(phase_a))   ,
                    get_cosine(sincos(phase_a)) ,
                    get_d_component(pmsm_model) , get_q_component(pmsm_model));

                    vd_control_process_counter <= 0;
            end if;

            CASE simulation_counter is
                WHEN 0 => set_load_torque(pmsm_model, 500);
                WHEN 20e3 => set_load_torque(pmsm_model, 6000);
                WHEN 25e3 => set_load_torque(pmsm_model, 500);
                when others => -- do nothing
            end case;
            rotor_angle <= get_electrical_angle(pmsm_model);


        -----
            create_multiplier(control_multiplier);
            CASE vd_control_process_counter is
                WHEN 0 =>
                    sequential_multiply(control_multiplier, q_inductance, angular_speed);
                    if multiplier_is_ready(control_multiplier) then
                        increment(vd_control_process_counter);
                        vd_control_process_counter2 <= 0;
                        multiply(control_multiplier, get_multiplier_result(control_multiplier, 15), iq_current);
                    end if;
                WHEN 1 =>
                    multiply(control_multiplier, stator_resistance, id_current);
                    increment(vd_control_process_counter);
                WHEN 2 =>
                    multiply(control_multiplier, vd_kp, control_input);
                    increment(vd_control_process_counter);
                WHEN 3 =>
                    multiply(control_multiplier, vd_ki, control_input);
                    increment(vd_control_process_counter);
                when others => -- wait for triggering
            end CASE;

        --------------------------------------------------
            CASE vd_control_process_counter2 is
                WHEN 0 =>
                    if multiplier_is_ready(control_multiplier) then
                        increment(vd_control_process_counter2);
                        pi_output_buffer <= get_multiplier_result(control_multiplier, 15);
                    end if;
                WHEN 1 =>
                    if multiplier_is_ready(control_multiplier) then
                        increment(vd_control_process_counter2);
                        pi_output_buffer <= pi_output_buffer + get_multiplier_result(control_multiplier, 15);
                    end if;
                WHEN 2 =>
                    if multiplier_is_ready(control_multiplier) then
                        increment(vd_control_process_counter2);
                        integrator <= integrator + get_multiplier_result(control_multiplier, 15);
                    end if;
                WHEN 3 =>
                    if multiplier_is_ready(control_multiplier) then
                        increment(vd_control_process_counter2);
                        pi_output <= integrator + pi_output_buffer;
                    end if;
                WHEN others => -- wait for triggering
            end CASE;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
