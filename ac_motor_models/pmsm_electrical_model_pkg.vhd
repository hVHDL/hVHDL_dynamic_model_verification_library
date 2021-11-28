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

end package pmsm_electrical_model_pkg;

package body pmsm_electrical_model_pkg is

end package body pmsm_electrical_model_pkg;

