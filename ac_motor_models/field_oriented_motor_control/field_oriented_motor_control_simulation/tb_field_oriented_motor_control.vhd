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
    use math_library.field_oriented_motor_control_pkg.all;

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
    type abc is (vd, vq, phase_a, phase_b, phase_c, id, iq, w, angle);

    type multiplier_array is array (abc range abc'left to abc'right) of multiplier_record;
    signal multiplier : multiplier_array := (init_multiplier, init_multiplier,init_multiplier, init_multiplier, init_multiplier, init_multiplier, init_multiplier, init_multiplier, init_multiplier);

    type sincos_array is array (abc range abc'left to abc'right) of sincos_record;
    signal sincos : sincos_array := (init_sincos, init_sincos, init_sincos, init_sincos, init_sincos, init_sincos, init_sincos, init_sincos, init_sincos);

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


    alias control_multiplier is multiplier(vd);
    alias control_multiplier2 is multiplier(vq);
    signal angular_speed : int18 := 0;
    signal q_inductance : int18 := 500;
    signal stator_resistance : int18 := 100;

    signal id_current_control : motor_current_control_record := init_motor_current_control;
    signal iq_current_control : motor_current_control_record := init_motor_current_control;

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
        function "*"
        (
            left, right : integer
        )
        return integer
        is
            variable result : signed(35 downto 0);
            constant radix : integer := 15;
        begin
            result := to_signed(left,18) * to_signed(right,18);
            return to_integer(result(17+radix downto radix));
            
        end "*";
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
            create_multiplier(control_multiplier);
            create_motor_current_control(
                control_multiplier,
                id_current_control,
                25000,
                get_angular_speed(pmsm_model),
                100,
                0-get_d_component(pmsm_model), get_q_component(pmsm_model));

            create_multiplier(control_multiplier2);
            create_motor_current_control(
                control_multiplier2,
                iq_current_control,
                20000,
                get_angular_speed(pmsm_model),
                100,
                -10000-get_q_component(pmsm_model), get_d_component(pmsm_model));

            if simulation_counter = 10 or angular_speed_calculation_is_ready(pmsm_model) then
                request_angular_speed_calculation(pmsm_model);
                request_electrical_angle_calculation(pmsm_model);
                request_id_calculation(pmsm_model , -get_control_output(id_current_control));
                request_iq_calculation(pmsm_model , -get_control_output(iq_current_control) + get_angular_speed(pmsm_model)*50e3 );

                request_dq_to_ab_transform(
                    dq_to_ab_transform          ,
                    get_sine(sincos(phase_a))   ,
                    get_cosine(sincos(phase_a)) ,
                    get_d_component(pmsm_model) , get_q_component(pmsm_model));

                request_motor_current_control(id_current_control);
                request_motor_current_control(iq_current_control);

            end if;

            CASE simulation_counter is
                -- WHEN 0 => set_load_torque(pmsm_model, 500);
                WHEN 2e3 => set_load_torque(pmsm_model, 6000);
            --     WHEN 25e3 => set_load_torque(pmsm_model, 500);
                when others => -- do nothing
            end case;
            rotor_angle <= get_electrical_angle(pmsm_model);


        -----

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
