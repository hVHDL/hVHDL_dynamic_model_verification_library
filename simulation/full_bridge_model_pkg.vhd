library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

package full_bridge_model_pkg is
------------------------------------------------------------------------
    type full_bridge_record is record
        leg1 : std_logic_vector(1 downto 0);
        leg2 : std_logic_vector(1 downto 0);
        state_counter : integer;
        timer : integer;
        active_time : integer;
        zero_time : integer;
    end record;

    constant init_full_bridge  : full_bridge_record := (("00"), ("00"), 0, 0, 0, 0);
------------------------------------------------------------------------
    procedure create_full_bridge (
        signal full_bridge_object : inout full_bridge_record);
------------------------------------------------------------------------
    function get_dc_current (
        hb1 : std_logic_vector;
        hb2 : std_logic_vector)
    return real;
------------------------------------------------------------------------
    function get_dc_current ( full_bridge_object : full_bridge_record) 
        return real;
------------------------------------------------------------------------
    procedure set_active_time (
        signal full_bridge_object : out full_bridge_record;
        active_time : in integer;
        period : in integer);
------------------------------------------------------------------------
end package full_bridge_model_pkg;


package body full_bridge_model_pkg is

    procedure create_full_bridge
    (
        signal full_bridge_object : inout full_bridge_record
    ) is
        alias m is full_bridge_object;
    begin

        if m.timer > 0 then
            m.timer <= m.timer - 1;
        end if;

        CASE m.state_counter is 
            WHEN 0 =>
                m.leg1 <= "10";
                m.leg2 <= "10";
                if m.timer = 0 then
                    m.timer <= m.active_time;
                    m.state_counter <= m.state_counter + 1;
                end if;
                
            WHEN 1 =>
                m.leg1 <= "10";
                m.leg2 <= "01";
                if m.timer = 0 then
                    m.timer <= m.zero_time;
                    m.state_counter <= m.state_counter + 1;
                end if;
            WHEN 2 =>
                m.leg1 <= "01";
                m.leg2 <= "01";
                if m.timer = 0 then
                    m.timer <= m.active_time;
                    m.state_counter <= m.state_counter + 1;
                end if;
            WHEN 3 =>
                m.leg1 <= "01";
                m.leg2 <= "10";
                if m.timer = 0 then
                    m.timer <= m.zero_time;
                    m.state_counter <= 0;
                end if;
            WHEN others =>
        end CASE;
        
    end create_full_bridge;
------------------------------------------------------------------------
    function get_dc_current
    (
        full_bridge_object : full_bridge_record
    )
    return real
    is
    begin
        return get_dc_current(full_bridge_object.leg1, full_bridge_object.leg2);
    end get_dc_current;
------------------------------------------------------------------------
    function get_dc_current
    (
        hb1 : std_logic_vector;
        hb2 : std_logic_vector
    )
    return real
    is
        variable dc_current : real;
    begin
        if hb1 /= hb2 then
            if hb1 = "10" then
                dc_current := 10.0;
            else
                dc_current := -10.0;
            end if;
        else
            dc_current := 0.0;
        end if;

        return dc_current;
    end get_dc_current;
------------------------------------------------------------------------
    procedure set_active_time
    (
        signal full_bridge_object : out full_bridge_record;
        active_time : in integer;
        period : in integer
    ) is
        alias m is full_bridge_object;
    begin
        m.active_time <= active_time;
        m.zero_time <= period-active_time;
        
    end set_active_time;
------------------------------------------------------------------------
end package body full_bridge_model_pkg;
