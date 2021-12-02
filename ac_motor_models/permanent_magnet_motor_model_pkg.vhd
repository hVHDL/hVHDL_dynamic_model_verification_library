library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library math_library;
    use math_library.multiplier_pkg.all;
    use math_library.state_variable_pkg.all;
    use math_library.pmsm_electrical_model_pkg.all;
    use math_library.pmsm_mechanical_model_pkg.all;

package permanent_magnet_motor_model_pkg is

------------------------------------------------------------------------
    type permanent_magnet_motor_model_record is record
        id_current_model    : id_current_model_record ;
        iq_current_model    : id_current_model_record ;
        angular_speed_model : angular_speed_record    ;
        electrical_angle : state_variable_record      ;
        vd_input_voltage        : int18               ;
        vq_input_voltage        : int18               ;
    end record                                        ;

    constant init_permanent_magnet_motor_model : permanent_magnet_motor_model_record := 
        (init_id_current_model          ,
         init_id_current_model          ,
         init_angular_speed_model       ,
         init_state_variable_gain(3000) ,
         0, 0);

------------------------------------------------------------------------
    function get_electrical_angle ( pmsm_model_object : permanent_magnet_motor_model_record)
        return int18;
------------------------------------------------------------------------
    function get_d_component ( pmsm_model_object : permanent_magnet_motor_model_record)
        return int18;
------------------------------------------------------------------------
    function get_q_component ( pmsm_model_object : permanent_magnet_motor_model_record)
        return int18;
------------------------------------------------------------------------
    procedure request_electrical_angle_calculation (
        signal pmsm_model_object : inout permanent_magnet_motor_model_record);
------------------------------------------------------------------------
    function angular_speed_calculation_is_ready ( pmsm_model_object : permanent_magnet_motor_model_record)
        return boolean;
------------------------------------------------------------------------
    function get_angular_speed ( pmsm_model_object : permanent_magnet_motor_model_record)
        return int18;
------------------------------------------------------------------------
    procedure request_id_calculation (
        signal pmsm_model_object : out permanent_magnet_motor_model_record;
        vd_voltage : in int18);
------------------------------------------------------------------------
    procedure request_iq_calculation (
        signal pmsm_model_object : out permanent_magnet_motor_model_record;
        vq_voltage : in int18);
------------------------------------------------------------------------
    procedure request_angular_speed_calculation (
        signal pmsm_model_object : out permanent_magnet_motor_model_record);
------------------------------------------------------------------------
    function id_calculation_is_ready ( pmsm_model_object : permanent_magnet_motor_model_record)
        return boolean;
------------------------------------------------------------------------
    procedure create_pmsm_model (
        signal pmsm_model_object : inout permanent_magnet_motor_model_record ;
        signal id_multiplier     : inout multiplier_record                   ;
        signal iq_multiplier     : inout multiplier_record                   ;
        signal w_multiplier      : inout multiplier_record                   ;
        signal angle_multiplier : inout multiplier_record                    );
------------------------------------------------------------------------
    procedure set_load_torque (
        signal pmsm_model_object : out permanent_magnet_motor_model_record;
        load_torque : in int18);
------------------------------------------------------------------------

end package permanent_magnet_motor_model_pkg;

package body permanent_magnet_motor_model_pkg is

------------------------------------------------------------------------
    function get_16_bits
    (
        number : int18
    )
    return integer
    is
    --------------------------------------------------
        function "+" ( left : unsigned; right : std_logic) 
            return unsigned is
        begin
            if right = '1' then
                return left + 1;
            else
                return left;
            end if;
        end "+";
    --------------------------------------------------
        variable uint_number : unsigned(17 downto 0);
    begin
       uint_number := unsigned(std_logic_vector(to_signed(number, 18)));
       return to_integer(uint_number(16 downto 1)+uint_number(0));
    end get_16_bits;
------------------------------------------------------------------------
    function get_electrical_angle
    (
        pmsm_model_object : permanent_magnet_motor_model_record
    )
    return int18
    is
    begin
        return get_16_bits(pmsm_model_object.electrical_angle.state);
    end get_electrical_angle;
------------------------------------------------------------------------
    function get_d_component
    (
        pmsm_model_object : permanent_magnet_motor_model_record
    )
    return int18
    is
    begin
        return get_d_component(pmsm_model_object.id_current_model);
    end get_d_component;
------------------------------------------------------------------------
    function get_q_component
    (
        pmsm_model_object : permanent_magnet_motor_model_record
    )
    return int18
    is
    begin
        return get_d_component(pmsm_model_object.iq_current_model);
    end get_q_component;
------------------------------------------------------------------------
    procedure request_electrical_angle_calculation
    (
        signal pmsm_model_object : inout permanent_magnet_motor_model_record
    ) is
    begin
        request_state_variable_calculation(pmsm_model_object.electrical_angle);
        
    end request_electrical_angle_calculation;
------------------------------------------------------------------------
    procedure set_load_torque
    (
        signal pmsm_model_object : out permanent_magnet_motor_model_record;
        load_torque : in int18
    ) is
    begin
        set_load_torque(pmsm_model_object.angular_speed_model, load_torque);
        
    end set_load_torque;
------------------------------------------------------------------------
    function get_angular_speed
    (
        pmsm_model_object : permanent_magnet_motor_model_record
    )
    return int18
    is
    begin
        return get_angular_speed(pmsm_model_object.angular_speed_model);
        
    end get_angular_speed;
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
        signal pmsm_model_object : out permanent_magnet_motor_model_record;
        vd_voltage : in int18
    )
    is
    begin
        pmsm_model_object.vd_input_voltage <= vd_voltage;
        request_iq_calculation(pmsm_model_object.iq_current_model);
    end request_id_calculation;
------------------------------------------------------------------------
    procedure request_iq_calculation
    (
        signal pmsm_model_object : out permanent_magnet_motor_model_record;
        vq_voltage : in int18
    )
    is
    begin
        pmsm_model_object.vq_input_voltage <= vq_voltage;
        request_iq_calculation(pmsm_model_object.id_current_model);
    end request_iq_calculation;
------------------------------------------------------------------------
    function get_17_bits
    (
        number : int18
    )
    return integer
    is
        variable uint_number : unsigned(17 downto 0);
    begin
       uint_number := unsigned(std_logic_vector(to_signed(number, 18)));
       return to_integer(uint_number(16 downto 0));
    end get_17_bits;
------------------------------------------------------------------------
    procedure create_pmsm_model
    (
        signal pmsm_model_object : inout permanent_magnet_motor_model_record ;

        signal id_multiplier    : inout multiplier_record ;
        signal iq_multiplier    : inout multiplier_record ;
        signal w_multiplier     : inout multiplier_record ;
        signal angle_multiplier : inout multiplier_record 
    ) is
        alias id_current_model    is pmsm_model_object.id_current_model    ;
        alias iq_current_model    is pmsm_model_object.iq_current_model    ;
        alias angular_speed_model is pmsm_model_object.angular_speed_model ;
        alias electrical_angle    is pmsm_model_object.electrical_angle    ;
        alias vd_input_voltage    is pmsm_model_object.vd_input_voltage    ;
        alias vq_input_voltage    is pmsm_model_object.vq_input_voltage    ;

        constant permanent_magnet_flux : int18 := 5000;
        constant Ld : int18 := 25e3  ;
        constant Lq : int18 := 20000 ;

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
        create_state_variable(electrical_angle,angle_multiplier, to_signed(get_angular_speed(angular_speed_model),18));

    end create_pmsm_model;

------------------------------------------------------------------------
end package body permanent_magnet_motor_model_pkg;
