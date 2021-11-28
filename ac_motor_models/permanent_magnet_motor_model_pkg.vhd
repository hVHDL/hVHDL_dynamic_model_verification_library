library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library math_library;
    use math_library.multiplier_pkg.all;
    use math_library.sincos_pkg.all;
    use math_library.state_variable_pkg.all;
    use math_library.pmsm_electrical_model_pkg.all;
    use math_library.pmsm_mechanical_model_pkg.all;

package permanent_magnet_motor_model_pkg is

------------------------------------------------------------------------
    type permanent_magnet_motor_model_record is record
        id_current_model    : id_current_model_record;
        iq_current_model    : id_current_model_record;
        angular_speed_model : angular_speed_record;
    end record;

    constant init_permanent_magnet_motor_model : permanent_magnet_motor_model_record := 
        (init_id_current_model ,
         init_id_current_model ,
         init_angular_speed_model);
------------------------------------------------------------------------
    function angular_speed_calculation_is_ready ( pmsm_model_object : permanent_magnet_motor_model_record)
        return boolean;
------------------------------------------------------------------------
    procedure request_id_calculation (
        signal pmsm_model_object : out permanent_magnet_motor_model_record);
------------------------------------------------------------------------
    procedure request_iq_calculation (
        signal pmsm_model_object : out permanent_magnet_motor_model_record);
------------------------------------------------------------------------
    procedure request_angular_speed_calculation (
        signal pmsm_model_object : out permanent_magnet_motor_model_record);
------------------------------------------------------------------------
    function id_calculation_is_ready ( pmsm_model_object : permanent_magnet_motor_model_record)
        return boolean;
------------------------------------------------------------------------
    procedure create_pmsm_model (
        signal pmsm_model_object : inout permanent_magnet_motor_model_record ;
        signal id_multiplier     : inout multiplier_record ;
        signal iq_multiplier     : inout multiplier_record ;
        signal w_multiplier      : inout multiplier_record ;
        vd_input_voltage         : int18                   ;
        vq_input_voltage         : int18                   );
------------------------------------------------------------------------

end package permanent_magnet_motor_model_pkg;

package body permanent_magnet_motor_model_pkg is

------------------------------------------------------------------------
    function angular_speed_calculation_is_ready
    (
        pmsm_model_object : permanent_magnet_motor_model_record
    )
    return boolean
    is
    begin
        return angular_speed_calculation_is_ready(pmsm_model_object.angular_speed_model);
    end angular_speed_calculation_is_ready;
------------------------------------------------------------------------
    function id_calculation_is_ready
    (
        pmsm_model_object : permanent_magnet_motor_model_record
    )
    return boolean
    is
    begin
        return id_calculation_is_ready(pmsm_model_object.iq_current_model);
    end id_calculation_is_ready;
------------------------------------------------------------------------
    procedure request_angular_speed_calculation
    (
        signal pmsm_model_object : out permanent_magnet_motor_model_record
    ) is
    begin
        request_angular_speed_calculation(pmsm_model_object.angular_speed_model);
    end request_angular_speed_calculation;
------------------------------------------------------------------------
    procedure request_id_calculation
    (
        signal pmsm_model_object : out permanent_magnet_motor_model_record
    )
    is
    begin
        request_iq_calculation(pmsm_model_object.iq_current_model);
    end request_id_calculation;
------------------------------------------------------------------------
    procedure request_iq_calculation
    (
        signal pmsm_model_object : out permanent_magnet_motor_model_record
    )
    is
    begin
        request_iq_calculation(pmsm_model_object.id_current_model);
    end request_iq_calculation;
------------------------------------------------------------------------
    procedure create_pmsm_model
    (
        signal pmsm_model_object : inout permanent_magnet_motor_model_record ;

        signal id_multiplier : inout multiplier_record ;
        signal iq_multiplier : inout multiplier_record ;
        signal w_multiplier  : inout multiplier_record ;
        vd_input_voltage     : int18                   ;
        vq_input_voltage     : int18
    ) is
        alias id_current_model    is pmsm_model_object.id_current_model    ;
        alias iq_current_model    is pmsm_model_object.iq_current_model    ;
        alias angular_speed_model is pmsm_model_object.angular_speed_model ;

        constant permanent_magnet_flux : int18 := 5000;
        constant Ld : int18 := 5000  ;
        constant Lq : int18 := 15000 ;

    begin
        
        --------------------------------------------------
        create_pmsm_electrical_model(
            id_current_model                        ,
            iq_current_model                        ,
            id_multiplier                           ,
            iq_multiplier                           ,
            angular_speed_model.angular_speed.state ,
            vd_input_voltage                        ,
            vq_input_voltage                        ,
            permanent_magnet_flux);

        --------------------------------------------------
        create_angular_speed_model(
            angular_speed_model               ,
            w_multiplier                      ,
            Ld                                ,
            Lq                                ,
            id_current_model.id_current.state ,
            id_current_model.id_current.state);
        --------------------------------------------------
    end create_pmsm_model;

------------------------------------------------------------------------
end package body permanent_magnet_motor_model_pkg;
