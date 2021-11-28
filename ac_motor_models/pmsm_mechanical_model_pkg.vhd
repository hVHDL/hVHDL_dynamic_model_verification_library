library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library math_library;
    use math_library.multiplier_pkg.all;
    use math_library.state_variable_pkg.all;

package pmsm_mechanical_model_pkg is

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

end package pmsm_mechanical_model_pkg;

package body pmsm_mechanical_model_pkg is

end package body pmsm_mechanical_model_pkg;
