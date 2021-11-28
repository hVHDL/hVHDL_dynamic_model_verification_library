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
    type abc is (phase_a, phase_b, phase_c, id, iq, w, angle);

    type multiplier_array is array (abc range abc'left to abc'right) of multiplier_record;
    signal multiplier : multiplier_array := (init_multiplier,init_multiplier, init_multiplier, init_multiplier, init_multiplier, init_multiplier, init_multiplier);

    type sincos_array is array (abc range abc'left to abc'right) of sincos_record;
    signal sincos : sincos_array := (init_sincos, init_sincos, init_sincos, init_sincos, init_sincos, init_sincos, init_sincos);

    signal angle_rad16 : unsigned(15 downto 0) := to_unsigned(10e3, 16);

    signal dq_to_ab_transform : dq_to_ab_record := init_dq_to_ab_transform;
    signal ab_to_dq_transform : ab_to_dq_record := init_ab_to_dq_transform;

    --------------------------------------------------
    -- motor electrical simulation signals --

    signal vd_input_voltage : int18 := 500;
    signal vq_input_voltage : int18 := 500;

    signal pmsm_model : permanent_magnet_motor_model_record := init_permanent_magnet_motor_model;

    alias id_multiplier is multiplier(id);
    alias iq_multiplier is multiplier(iq);
    alias w_multiplier is multiplier(w);

    --------------------------------------------------
    -- mechanical model
    signal electrical_angle : state_variable_record := init_state_variable_gain(30000);

    function get_16_bits
    (
        number : int18
    )
    return integer
    is
        variable uint_number : unsigned(17 downto 0);
    begin
       uint_number := unsigned(std_logic_vector(to_signed(number, 18)));
       return to_integer(uint_number(15 downto 0));
    end get_16_bits;

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

            electrical_angle.state <= get_16_bits(electrical_angle.state);
            create_state_variable(electrical_angle,multiplier(angle), get_angle(pmsm_model));

            --------------------------------------------------
            create_pmsm_model(
                pmsm_model            ,
                multiplier(id)        ,
                multiplier(iq)        ,
                multiplier(w)         ,
                vd_input_voltage      ,
                vq_input_voltage      );
            --------------------------------------------------
            if simulation_counter = 10 or id_calculation_is_ready(pmsm_model)  then
                request_id_calculation(pmsm_model);
                request_iq_calculation(pmsm_model);
            end if;

            if simulation_counter = 10 or angular_speed_calculation_is_ready(pmsm_model) then
                request_angular_speed_calculation(pmsm_model);
                request_state_variable_calculation(electrical_angle);
            end if;


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
