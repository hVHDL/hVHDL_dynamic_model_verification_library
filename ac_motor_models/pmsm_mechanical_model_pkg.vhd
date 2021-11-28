library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library math_library;
    use math_library.multiplier_pkg.all;
    use math_library.state_variable_pkg.all;

package pmsm_mechanical_model_pkg is

------------------------------------------------------------------------
    type angular_speed_record is record
        angular_speed                     : state_variable_record;
        angular_speed_calculation_counter : natural range 0 to 15;
        load_torque                       : int18                ;
        w_state_equation                  : int18                ;
        permanent_magnet_torque           : int18                ;
        permanent_magnet_flux             : int18                ;
        reluctance_torque                 : int18                ;
        friction                          : int18                ;
    end record;

    constant init_angular_speed_model : angular_speed_record :=(
        angular_speed                     => init_state_variable_gain(500) ,
        angular_speed_calculation_counter => 15                            ,
        load_torque                       => 1000                          ,
        w_state_equation                  => 0                             ,
        permanent_magnet_torque           => 0                             ,
        permanent_magnet_flux             => 5000                          ,
        reluctance_torque                 => 0                             ,
        friction                          => 0                             );
------------------------------------------------------------------------
    function get_angle ( angular_speed_object : angular_speed_record)
        return int18;
------------------------------------------------------------------------
    function angular_speed_calculation_is_ready ( angular_speed_object : angular_speed_record)
        return boolean;
------------------------------------------------------------------------
    procedure request_angular_speed_calculation (
        signal angular_speed_object : out angular_speed_record);
    --------------------------------------------------
    procedure create_angular_speed_model (
        signal angular_speed_object : inout angular_speed_record;
        signal w_multiplier         : inout multiplier_record;
        Ld                          : int18;
        Lq                          : int18;
        id_current                  : int18;
        iq_current                  : int18);
    --------------------------------------------------

------------------------------------------------------------------------
end package pmsm_mechanical_model_pkg;

package body pmsm_mechanical_model_pkg is

------------------------------------------------------------------------
    function get_angle
    (
        angular_speed_object : angular_speed_record
    )
    return int18
    is
    begin
        return angular_speed_object.angular_speed.state;
    end get_angle;
------------------------------------------------------------------------
    function angular_speed_calculation_is_ready
    (
        angular_speed_object : angular_speed_record
    )
    return boolean
    is
    begin
        return state_variable_calculation_is_ready(angular_speed_object.angular_speed);
    end angular_speed_calculation_is_ready;
------------------------------------------------------------------------
    procedure request_angular_speed_calculation
    (
        signal angular_speed_object : out angular_speed_record
    ) is
    begin
        angular_speed_object.angular_speed_calculation_counter <= 0;
    end request_angular_speed_calculation;
------------------------------------------------------------------------
    procedure create_angular_speed_model
    (
        signal angular_speed_object : inout angular_speed_record;
        signal w_multiplier         : inout multiplier_record;
        Ld                          : int18;
        Lq                          : int18;
        id_current                  : int18;
        iq_current                  : int18
    ) is
        alias angular_speed                     is angular_speed_object.angular_speed                     ;
        alias angular_speed_calculation_counter is angular_speed_object.angular_speed_calculation_counter ;
        alias load_torque                       is angular_speed_object.load_torque                       ;
        alias w_state_equation                  is angular_speed_object.w_state_equation                  ;
        alias permanent_magnet_torque           is angular_speed_object.permanent_magnet_torque           ;
        alias permanent_magnet_flux             is angular_speed_object.permanent_magnet_flux             ;
        alias reluctance_torque                 is angular_speed_object.reluctance_torque                 ;
        alias friction                          is angular_speed_object.friction                          ;
    begin
        create_state_variable(angular_speed , w_multiplier  , w_state_equation);

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
        
    end create_angular_speed_model;

------------------------------------------------------------------------
end package body pmsm_mechanical_model_pkg;
