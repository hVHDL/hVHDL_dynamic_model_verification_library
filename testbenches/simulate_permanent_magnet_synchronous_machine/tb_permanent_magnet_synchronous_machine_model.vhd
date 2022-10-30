LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

    use work.multiplier_pkg.all;
    use work.permanent_magnet_motor_model_pkg.all;

entity tb_permanent_magnet_synchronous_machine_model is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_permanent_magnet_synchronous_machine_model is

    signal simulation_running  : boolean    := false  ;
    signal simulator_clock     : std_logic  := '0'    ;
    constant clock_per         : time       := 1 ns   ;
    constant simtime_in_clocks : integer    := 15e3   ;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    type abc is (phase_a, phase_b, phase_c, id, iq, w, angle);

    type multiplier_array is array (abc range abc'left to abc'right) of multiplier_record;
    signal multiplier : multiplier_array := (others => init_multiplier);

    signal angle_rad16 : unsigned(15 downto 0) := to_unsigned(10e3, 16);

    --------------------------------------------------
    -- motor electrical simulation signals --

    signal vd_input_voltage : int := 300;
    signal vq_input_voltage : int := -300;

    signal pmsm_model : permanent_magnet_motor_model_record := init_permanent_magnet_motor_model;

    alias id_multiplier is multiplier(id);
    alias iq_multiplier is multiplier(iq);
    alias w_multiplier is multiplier(w);

    --------------------------------------------------
    -- mechanical model

    signal process_counter : natural range 0 to 15 := 15;
    signal rotor_angle : int := 0;

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

    simulator_clock <= not simulator_clock after clock_per/2.0;
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

            --------------------------------------------------
            create_pmsm_model(
                pmsm_model        ,
                multiplier(id)    ,
                multiplier(iq)    ,
                multiplier(w)     ,
                multiplier(angle) ,
                default_motor_parameters);
            --------------------------------------------------

            if simulation_counter = 10 or angular_speed_calculation_is_ready(pmsm_model) then
                request_angular_speed_calculation(pmsm_model);
                request_electrical_angle_calculation(pmsm_model);
                request_id_calculation(pmsm_model , vd_input_voltage);
                request_iq_calculation(pmsm_model , vq_input_voltage );
            end if;

            CASE simulation_counter is
                WHEN 0 => set_load_torque(pmsm_model, 500);
                WHEN 20e3 => set_load_torque(pmsm_model, 6000);
                WHEN 25e3 => set_load_torque(pmsm_model, 500);
                when others => -- do nothing
            end case;
            rotor_angle <= get_electrical_angle(pmsm_model);

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
