library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;


library math_library;
    use math_library.multiplier_pkg.all;
    use math_library.state_variable_pkg.all;

package pmsm_electrical_model_pkg is

    type id_current_model_record is record
        id_calculation_counter : natural range 0 to 15;
        id_current        : state_variable_record;
        Ld                : int18;
        id_state_equation : int18;
        rotor_resistance  : int18;
    end record;

    constant init_id_current_model : id_current_model_record := (15, init_state_variable_gain(5000), 5000, 0, 1000);

------------------------------------------------------------------------
    procedure request_iq_calculation (
        signal id_current_object : out id_current_model_record);
------------------------------------------------------------------------
    procedure create_pmsm_electrical_model (
        signal id_current_object : inout id_current_model_record;
        signal iq_current_object : inout id_current_model_record;
        signal id_multiplier     : inout multiplier_record;
        signal iq_multiplier     : inout multiplier_record;
        angular_speed            : in state_variable_record;
        vd_input_voltage         : in int18;
        vq_input_voltage         : in int18;
        permanent_magnet_flux    : in int18);
------------------------------------------------------------------------

end package pmsm_electrical_model_pkg;

package body pmsm_electrical_model_pkg is

    procedure request_iq_calculation
    (
        signal id_current_object : out id_current_model_record
    ) is
    begin
        id_current_object.id_calculation_counter <= 0;
        
    end request_iq_calculation;
------------------------------------------------------------------------
    procedure create_pmsm_electrical_model
    (
        signal id_current_object : inout id_current_model_record;
        signal iq_current_object : inout id_current_model_record;
        signal id_multiplier     : inout multiplier_record;
        signal iq_multiplier     : inout multiplier_record;
        angular_speed            : in state_variable_record;
        vd_input_voltage         : in int18;
        vq_input_voltage         : in int18;
        permanent_magnet_flux : in int18
    ) is
        alias rotor_resistance       is id_current_object.rotor_resistance      ;
        alias id_calculation_counter is id_current_object.id_calculation_counter;
        alias id_state_equation      is id_current_object.id_state_equation     ;
        alias Ld                     is id_current_object.Ld                    ;
        alias id_current             is id_current_object.id_current            ;

        alias iq_calculation_counter is iq_current_object.id_calculation_counter;
        alias iq_state_equation      is iq_current_object.id_state_equation;
        alias Lq                     is iq_current_object.Ld;
        alias iq_current             is iq_current_object.id_current;

    begin
            create_state_variable(id_current    , id_multiplier , id_state_equation);
            create_state_variable(iq_current    , iq_multiplier , iq_state_equation);
            CASE id_calculation_counter is
                -- calculate id state equation
                WHEN 0 =>
                    multiply(id_multiplier, rotor_resistance, id_current.state);
                    increment(id_calculation_counter);
                WHEN 1 =>
                    multiply(id_multiplier, angular_speed.state, iq_current.state);
                    increment(id_calculation_counter);
                WHEN 2 =>
                    if multiplier_is_ready(id_multiplier) then
                        id_state_equation <= -get_multiplier_result(id_multiplier,15);
                        increment(id_calculation_counter);
                    end if;
                WHEN 3 =>
                    multiply(id_multiplier, Lq, get_multiplier_result(id_multiplier,15));
                    increment(id_calculation_counter);
                WHEN 4 =>
                    if multiplier_is_ready(id_multiplier) then
                        id_state_equation <= id_state_equation + get_multiplier_result(id_multiplier,15) + vd_input_voltage;
                        increment(id_calculation_counter);
                        request_state_variable_calculation(id_current);
                    end if;
                WHEN others => -- hang here
            end CASE;

            CASE iq_calculation_counter is
                -- calculate iq state equation
                WHEN 0 =>
                    multiply(iq_multiplier, rotor_resistance, iq_current.state);
                    increment(iq_calculation_counter);
                WHEN 1 =>
                    multiply(iq_multiplier, permanent_magnet_flux, angular_speed.state);
                    increment(iq_calculation_counter);
                WHEN 2 =>
                    multiply(iq_multiplier, id_current.state, angular_speed.state);
                    increment(iq_calculation_counter);
                WHEN 3 =>
                    if multiplier_is_ready(iq_multiplier) then
                        iq_state_equation <= - get_multiplier_result(iq_multiplier, 15);
                        increment(iq_calculation_counter);
                    end if;
                WHEN 4 =>
                    iq_state_equation <= iq_state_equation - get_multiplier_result(iq_multiplier, 15);
                    increment(iq_calculation_counter);
                WHEN 5 =>
                    multiply(iq_multiplier, Ld, get_multiplier_result(iq_multiplier, 15));
                    increment(iq_calculation_counter);
                WHEN 6 =>
                    if multiplier_is_ready(iq_multiplier) then
                        iq_state_equation <= iq_state_equation - get_multiplier_result(iq_multiplier, 15) + vq_input_voltage;
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
        
    end create_pmsm_electrical_model;
------------------------------------------------------------------------

end package body pmsm_electrical_model_pkg;

