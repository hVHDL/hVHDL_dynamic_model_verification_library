library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library math_library;
    use math_library.multiplier_pkg.all;
    use math_library.field_oriented_motor_control_pkg.all;

package iq_current_control_pkg is


------------------------------------------------------------------------

end package iq_current_control_pkg;

package body iq_current_control_pkg is

    procedure create_iq_current_control
    (
        signal control_multiplier     : inout multiplier_record;
        signal current_control_object : inout motor_current_control_record;
        q_inductance                  : int18;
        angular_speed                 : int18;
        stator_resistance             : int18;
        feedback_current              : int18;
        feedforward_current           : int18;
        permanent_magnet_flux         : int18
    )is
        alias vd_control_process_counter  is current_control_object.vd_control_process_counter   ;
        alias vd_control_process_counter2 is current_control_object.vd_control_process_counter2 ;
    begin
        create_motor_current_control(
        control_multiplier     ,
        current_control_object ,
        q_inductance           ,
        angular_speed          ,
        stator_resistance      ,
        feedback_current       ,
        feedforward_current    );
        if vd_control_process_counter = 4 then
            multiply(control_multiplier, permanent_magnet_flux, feedback_current);
        end if;
        
    end create_iq_current_control;

end package body iq_current_control_pkg;
