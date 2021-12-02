library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library math_library;
    use math_library.multiplier_pkg.all;

package field_oriented_motor_control_pkg is

    type motor_current_control_record is record
        vd_control_process_counter : natural range 0 to 15 ;
        vd_control_process_counter2 : natural range 0 to 15;
        control_input    : int18;
        integrator       : int18;
        pi_output_buffer : int18;
        pi_output        : int18;
        vd_kp            : int18;
        vd_ki            : int18;
    end record;

    constant init_motor_current_control : motor_current_control_record :=
    (15 , 15 , 0 , 0 , 0 , 0 , 5000 , 500);

    procedure request_motor_current_control (
        signal current_control_object : out motor_current_control_record);

    procedure create_motor_current_control (
        signal control_multiplier     : inout multiplier_record;
        signal current_control_object : inout motor_current_control_record;
        q_inductance                  : int18;
        angular_speed                 : int18;
        id_current                    : int18;
        iq_current                    : int18;
        stator_resistance             : int18);


end package field_oriented_motor_control_pkg;

package body field_oriented_motor_control_pkg is

    procedure request_motor_current_control
    (
        signal current_control_object : out motor_current_control_record
    ) is
    begin
        current_control_object.vd_control_process_counter <= 0;
    end request_motor_current_control;

    procedure create_motor_current_control
    (
        signal control_multiplier     : inout multiplier_record;
        signal current_control_object : inout motor_current_control_record;
        q_inductance                  : int18;
        angular_speed                 : int18;
        id_current                    : int18;
        iq_current                    : int18;
        stator_resistance             : int18
    ) is

        alias vd_control_process_counter    is current_control_object.vd_control_process_counter    ;
        alias vd_control_process_counter2    is current_control_object.vd_control_process_counter2    ;
        alias control_input    is current_control_object.control_input    ;
        alias integrator       is current_control_object.integrator       ;
        alias pi_output_buffer is current_control_object.pi_output_buffer ;
        alias pi_output        is current_control_object.pi_output        ;
        alias vd_kp            is current_control_object.vd_kp            ;
        alias vd_ki            is current_control_object.vd_ki            ;

    begin
            CASE vd_control_process_counter is
                WHEN 0 =>
                    sequential_multiply(control_multiplier, q_inductance, angular_speed);
                    if multiplier_is_ready(control_multiplier) then
                        increment(vd_control_process_counter);
                        vd_control_process_counter2 <= 0;
                        multiply(control_multiplier, get_multiplier_result(control_multiplier, 15), iq_current);
                    end if;
                WHEN 1 =>
                    multiply(control_multiplier, stator_resistance, id_current);
                    increment(vd_control_process_counter);
                WHEN 2 =>
                    multiply(control_multiplier, vd_kp, control_input);
                    increment(vd_control_process_counter);
                WHEN 3 =>
                    multiply(control_multiplier, vd_ki, control_input);
                    increment(vd_control_process_counter);
                when others => -- wait for triggering
            end CASE;

        --------------------------------------------------
            CASE vd_control_process_counter2 is
                WHEN 0 =>
                    if multiplier_is_ready(control_multiplier) then
                        increment(vd_control_process_counter2);
                        pi_output_buffer <= get_multiplier_result(control_multiplier, 15);
                    end if;
                WHEN 1 =>
                    if multiplier_is_ready(control_multiplier) then
                        increment(vd_control_process_counter2);
                        pi_output_buffer <= pi_output_buffer + get_multiplier_result(control_multiplier, 15);
                    end if;
                WHEN 2 =>
                    if multiplier_is_ready(control_multiplier) then
                        increment(vd_control_process_counter2);
                        integrator <= integrator + get_multiplier_result(control_multiplier, 15);
                    end if;
                WHEN 3 =>
                    if multiplier_is_ready(control_multiplier) then
                        increment(vd_control_process_counter2);
                        pi_output <= integrator + pi_output_buffer;
                    end if;
                WHEN others => -- wait for triggering
            end CASE;
        
    end create_motor_current_control;

end package body field_oriented_motor_control_pkg;
