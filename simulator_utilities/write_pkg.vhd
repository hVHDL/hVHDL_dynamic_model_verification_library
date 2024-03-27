library ieee;
    use ieee.std_logic_1164.all;
    use ieee.math_real.all;
    use std.textio.all;
    use ieee.numeric_std.all;

package write_pkg is

    type real_number_array is array (natural range <>) of real;
    alias real_array is real_number_array;
    type stringarray is array (natural range <>) of string;
------------------------------------------------------------------------
    procedure write_to (
        file filee : text;
        data_to_be_written : real_number_array);
------------------------------------------------------------------------
    procedure init_simfile (
        file filee : text;
        data_to_be_written : stringarray);
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
    procedure init_simfile
    (
        file filee : text;
        data_to_be_written : stringarray
    ) is
        variable row : line;
        constant number_of_characters_between_columns : integer := 30;
    begin
        
        for i in data_to_be_written'range loop
            write(row , data_to_be_written(i) , left , number_of_characters_between_columns);
        end loop;

        writeline(filee , row);
    end init_simfile;
------------------------------------------------------------------------
end package body write_pkg;
