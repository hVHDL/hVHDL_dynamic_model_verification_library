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
        alias calculation_ready           is current_control_object.calculation_ready ;
        alias pi_output                   is current_control_object.pi_output        ;
        alias pi_output_buffer            is current_control_object.pi_output_buffer ;
        alias integrator                  is current_control_object.integrator       ;
    begin
        create_motor_current_control(
            control_multiplier     ,
            current_control_object ,
            q_inductance           ,
            angular_speed          ,
            stator_resistance      ,
            feedback_current       ,
            feedforward_current    );

        calculation_ready <= false;
        if vd_control_process_counter = 4 then
            multiply(control_multiplier, permanent_magnet_flux, feedback_current);
            increment(vd_control_process_counter);
        end if;

        CASE vd_control_process_counter2 is
            WHEN 3 =>
                pi_output <= pi_output;
                pi_output_buffer <= pi_output_buffer - integrator ;
                increment(vd_control_process_counter);
            WHEN 4 =>
                if multiplier_is_ready(control_multiplier) then
                    pi_output <= pi_output_buffer + get_multiplier_result(control_multiplier,15);
                    calculation_ready <= true;
                    increment(vd_control_process_counter);
                    calculation_ready <= true;
                end if;
            WHEN others => -- do nothing
        end CASE;
        
    end create_iq_current_control;

end package body iq_current_control_pkg;
