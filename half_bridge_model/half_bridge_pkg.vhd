library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_pkg.all;

package half_bridge_pkg is

    type half_bridge_record is record
        dc_link_current : int;
        output_voltage  : int;
        duty_counter    : integer range 0 to 3;
        result_counter  : integer range 0 to 3;
    end record;

    constant init_half_bridge : half_bridge_record := (0,0,0,0);

    procedure create_half_bridge (
        signal self : inout half_bridge_record;
        signal multiplier : inout multiplier_record;
        output_current : in int;
        input_voltage : in int;
        duty_ratio : in int;
        radix : in natural);

    procedure request_half_bridge (
        signal half_bridge_object : out half_bridge_record);

    function get_half_bridge_current ( half_bridge_object : half_bridge_record)
        return int;

    function get_half_bridge_voltage ( half_bridge_object  : half_bridge_record)
        return int;

end package half_bridge_pkg;

package body half_bridge_pkg is
------------------------------------------------------------------------
    procedure create_half_bridge
    (
        signal self : inout half_bridge_record;
        signal multiplier : inout multiplier_record;
        output_current : in int;
        input_voltage : in int;
        duty_ratio : in int;
        radix : in natural
    ) is
    begin
        case self.duty_counter is
            WHEN 0 => multiply_and_increment_counter(multiplier , self.duty_counter , output_current , duty_ratio);
            WHEN 1 => multiply_and_increment_counter(multiplier , self.duty_counter , input_voltage  , duty_ratio);
            WHEN others => --do nothing
        end CASE;

        if multiplier_is_ready(multiplier) then
            self.result_counter <= self.result_counter + 1;
            case self.result_counter is
                WHEN 0 => self.dc_link_current <= get_multiplier_result(multiplier, radix);
                WHEN 1 => self.output_voltage  <= get_multiplier_result(multiplier, radix);
                WHEN others => -- do nothing
            end CASE;
        end if;
    end create_half_bridge;
------------------------------
    procedure request_half_bridge
    (
        signal half_bridge_object : out half_bridge_record
    ) is
    begin
        half_bridge_object.duty_counter   <= 0;
        half_bridge_object.result_counter <= 0;
    end request_half_bridge;
------------------------------

    function get_half_bridge_current
    (
        half_bridge_object : half_bridge_record
    )
    return int
    is
    begin

        return half_bridge_object.dc_link_current;
        
    end get_half_bridge_current;

------------------------------
    function get_half_bridge_voltage
    (
        half_bridge_object  : half_bridge_record
    )
    return int
    is
    begin
        return half_bridge_object.output_voltage;
    end get_half_bridge_voltage;


end package body half_bridge_pkg;
