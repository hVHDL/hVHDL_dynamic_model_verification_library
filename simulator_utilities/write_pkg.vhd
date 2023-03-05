library ieee;
    use ieee.std_logic_1164.all;
    use ieee.math_real.all;
    use std.textio.all;
    use ieee.numeric_std.all;

package write_pkg is

    type real_number_array is array (integer range <>) of real;
------------------------------------------------------------------------
    procedure write_to (
        file filee : text;
        data_to_be_written : real_number_array);
------------------------------------------------------------------------
end package write_pkg;

package body write_pkg is

------------------------------------------------------------------------
    procedure write_to
    (
        file filee : text;
        data_to_be_written : real_number_array
        
    ) is
        variable row : line;
        constant number_of_characters_between_columns : integer := 30;
    begin
        
        for i in data_to_be_written'range loop
            write(row , data_to_be_written(i) , left , number_of_characters_between_columns);
        end loop;

        writeline(filee , row);
    end write_to;
------------------------------------------------------------------------
end package body write_pkg;
