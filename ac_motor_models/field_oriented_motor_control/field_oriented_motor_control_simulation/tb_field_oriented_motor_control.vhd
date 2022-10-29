LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

    use work.multiplier_pkg.all;
    use work.sincos_pkg.all;
    use work.abc_to_ab_transform_pkg.all;
    use work.ab_to_abc_transform_pkg.all;
    use work.dq_to_ab_transform_pkg.all;
    use work.ab_to_dq_transform_pkg.all;
    use work.permanent_magnet_motor_model_pkg.all;
    use work.state_variable_pkg.all;
    use work.field_oriented_motor_control_pkg.all;
    use work.pi_controller_pkg.all;

entity tb_field_oriented_motor_control is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_field_oriented_motor_control is

    signal simulation_running  : boolean    := false  ;
    signal simulator_clock     : std_logic  := '0'    ;
    constant clock_period      : time       := 1 ns   ;
    constant simtime_in_clocks : integer    := 10e3   ;

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
    signal d_reference : int := 15000;
    signal square_sum : int := 0;

    --------------------------------------------------
    -- motor electrical simulation signals --

    signal pmsm_model : permanent_magnet_motor_model_record := init_permanent_magnet_motor_model;

    alias id_multiplier is multiplier(id);
    alias iq_multiplier is multiplier(iq);
    alias w_multiplier is multiplier(w);

    --------------------------------------------------

    alias control_multiplier is multiplier(vd);
    alias control_multiplier2 is multiplier(vq);

    signal id_current_control : motor_current_control_record := init_motor_current_control;
    signal iq_current_control : motor_current_control_record := init_motor_current_control;

    signal speed_control_multiplier : multiplier_record := init_multiplier;
    signal speed_controller : pi_controller_record := init_pi_controller;

    signal speed_reference : int := 15e3;

    signal id_current : integer := 0;
    signal iq_current : integer := 0;

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
                multiplier(angle) ,
                default_motor_parameters);
            --------------------------------------------------
            create_multiplier(control_multiplier);
            create_motor_current_control(
                control_multiplier                        ,
                id_current_control                        ,
                default_motor_parameters.Lq               ,
                get_angular_speed(pmsm_model)             ,
                default_motor_parameters.rotor_resistance ,
                d_reference-get_d_component(pmsm_model)   , get_q_component(pmsm_model));

            --------------------------------------------------
            create_multiplier(control_multiplier2);
            create_motor_current_control(
                control_multiplier2                                                 ,
                iq_current_control                                                  ,
                default_motor_parameters.Ld                                         ,
                get_angular_speed(pmsm_model)                                       ,
                default_motor_parameters.rotor_resistance                           ,
                get_pi_control_output(speed_controller)-get_q_component(pmsm_model) , get_d_component(pmsm_model));
            --------------------------------------------------
            create_multiplier(speed_control_multiplier);
            create_pi_controller(speed_control_multiplier, speed_controller, 30000, 2500);

            --------------------------------------------------
            if simulation_counter = 10 or angular_speed_calculation_is_ready(pmsm_model) then
                request_angular_speed_calculation(pmsm_model);
                request_electrical_angle_calculation(pmsm_model);
                request_id_calculation(pmsm_model , -get_control_output(id_current_control));
                request_iq_calculation(pmsm_model , -get_control_output(iq_current_control) + get_angular_speed(pmsm_model)*default_motor_parameters.permanent_magnet_flux );

                request_dq_to_ab_transform(
                    dq_to_ab_transform          ,
                    get_sine(sincos(phase_a))   ,
                    get_cosine(sincos(phase_a)) ,
                    get_d_component(pmsm_model) , get_q_component(pmsm_model));

                request_motor_current_control(id_current_control);
                request_motor_current_control(iq_current_control);
                request_pi_control(speed_controller, speed_reference - get_angular_speed(pmsm_model));

            end if;

            CASE simulation_counter is
                -- WHEN 0 => set_load_torque(pmsm_model, 500);
                -- WHEN 0 => set_load_torque(pmsm_model, -10e3);
                -- WHEN 5e3 => set_load_torque(pmsm_model, 16e3);
                -- WHEN 7e3 => speed_reference <=  0;
                --             set_load_torque(pmsm_model, -16e3);
                when others => -- do nothing
            end case;
            square_sum <= get_q_component(pmsm_model) * get_q_component(pmsm_model) + get_d_component(pmsm_model) * get_d_component(pmsm_model);
            id_current <= get_d_component(pmsm_model);
            iq_current <= get_q_component(pmsm_model);
        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
