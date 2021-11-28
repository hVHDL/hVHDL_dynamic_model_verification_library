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

    signal simulation_running  : boolean    := false  ;
    signal simulator_clock     : std_logic  := '0'    ;
    constant clock_per         : time       := 1 ns   ;
    constant clock_half_per    : time       := 0.5 ns ;
    constant simtime_in_clocks : integer    := 25e3   ;

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
    -- motor electrical simulation signals --

    signal vd_input_voltage        : int18 := 500;
    signal vq_input_voltage        : int18 := 500;

    signal id_current_model : id_current_model_record := init_id_current_model;
    signal iq_current_model : id_current_model_record := init_id_current_model;

    alias id_multiplier is multiplier(id);
    alias iq_multiplier is multiplier(iq);
    alias w_multiplier is multiplier(w);

    --------------------------------------------------
    -- mechanical model
    constant permanent_magnet_flux           : int18                 := 5000;
    constant number_of_pole_pairs            : int18                 := 2;

    type angular_speed_record is record
        angular_speed                     : state_variable_record;
        angular_speed_calculation_counter : natural range 0 to 15;
        load_torque                       : int18                ;
        w_state_equation                  : int18                ;
        permanent_magnet_torque           : int18                ;
        Ld                                : int18                ;
        Lq                                : int18                ;
        reluctance_torque                 : int18                ;
        friction                          : int18                ;
    end record;
    constant init_angular_speed_model : angular_speed_record :=(
        angular_speed                     => init_state_variable_gain(500) ,
        angular_speed_calculation_counter => 15                            ,
        load_torque                       => 1000                          ,
        w_state_equation                  => 0                             ,
        permanent_magnet_torque           => 0                             ,
        Ld                                => 5000                          ,
        Lq                                => 15000                         ,
        reluctance_torque                 => 0                             ,
        friction                          => 0                             );
    --------------------------------------------------
    signal angular_speed_model : angular_speed_record := init_angular_speed_model;

    alias id_current is id_current_model.id_current.state;
    alias iq_current is iq_current_model.id_current.state;

    alias angular_speed                     is angular_speed_model.angular_speed                    ;
    alias angular_speed_calculation_counter is angular_speed_model.angular_speed_calculation_counter;
    alias load_torque                       is angular_speed_model.load_torque                      ;
    alias w_state_equation                  is angular_speed_model.w_state_equation                 ;
    alias permanent_magnet_torque           is angular_speed_model.permanent_magnet_torque          ;
    alias Ld                                is angular_speed_model.Ld                               ;
    alias Lq                                is angular_speed_model.Lq                               ;
    alias reluctance_torque                 is angular_speed_model.reluctance_torque                ;
    alias friction                          is angular_speed_model.friction                         ;

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

            create_state_variable(angular_speed , w_multiplier  , w_state_equation);

            --------------------------------------------------
            create_pmsm_electrical_model(
                id_current_model    ,
                iq_current_model    ,
                multiplier(id)      ,
                multiplier(iq)      ,
                angular_speed.state ,
                vd_input_voltage    ,
                vq_input_voltage    ,
                permanent_magnet_flux);
            --------------------------------------------------
            if simulation_counter = 10 or id_calculation_is_ready(iq_current_model)  then
                request_iq_calculation(id_current_model);
                request_iq_calculation(iq_current_model);
            end if;

            if simulation_counter = 10 or state_variable_calculation_is_ready(angular_speed) then
                angular_speed_calculation_counter <= 0;
            end if;

            CASE angular_speed_calculation_counter is
                WHEN 0 =>
                    multiply(w_multiplier, id_current, iq_current);
                    increment(angular_speed_calculation_counter);
                WHEN 1 =>
                    multiply(w_multiplier, permanent_magnet_flux, iq_current);
                    increment(angular_speed_calculation_counter);
                WHEN 2 =>
                    if multiplier_is_ready(w_multiplier) then
                        multiply(w_multiplier, (Ld-Lq), get_multiplier_result(w_multiplier, 15));
                        increment(angular_speed_calculation_counter);
                    end if;
                WHEN 3 =>
                    multiply(w_multiplier, angular_speed.state, 10e3);
                    permanent_magnet_torque <= get_multiplier_result(w_multiplier, 15);
                    w_state_equation        <= get_multiplier_result(w_multiplier, 15);
                    increment(angular_speed_calculation_counter);
                WHEN 4 =>
                    increment(angular_speed_calculation_counter);
                WHEN 5 =>
                    if multiplier_is_ready(w_multiplier) then
                        reluctance_torque <= get_multiplier_result(w_multiplier, 15);
                        w_state_equation <= w_state_equation + get_multiplier_result(w_multiplier, 15);
                        increment(angular_speed_calculation_counter);
                    end if;
                WHEN 6 =>
                    friction <= - get_multiplier_result(w_multiplier, 15);
                    w_state_equation <= w_state_equation - get_multiplier_result(w_multiplier, 15);
                    increment(angular_speed_calculation_counter);
                WHEN 7 =>
                    request_state_variable_calculation(angular_speed);
                    increment(angular_speed_calculation_counter);
                WHEN others =>
            end CASE;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
