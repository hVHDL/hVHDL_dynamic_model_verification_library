library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library math_library;
    use math_library.multiplier_pkg.all;

------------------------------------------------------------------------
package state_variable_pkg is

    type state_variable_record is record
        state           : int18;
        integrator_gain : int18;
        state_counter : natural range 0 to 1;
    end record;

    constant init_state_variable : state_variable_record := (0, 0, 1);
--------------------------------------------------
    function init_state_variable_gain ( integrator_gain : int18)
        return state_variable_record;

--------------------------------------------------
    procedure create_state_variable (
        signal state_variable : inout state_variable_record;
        signal hw_multiplier : inout multiplier_record;
        state_equation : int18);

--------------------------------------------------
    procedure integrate_state (
        signal state_variable : inout state_variable_record;
        signal multiplier : inout multiplier_record;
        constant radix : in natural;
        state_equation : in int18);

------------------------------------------------------------------------
    procedure calculate ( signal state_variable : out state_variable_record);

    procedure request_state_variable_calculation (
        signal state_variable : out state_variable_record );
------------------------------------------------------------------------
------------------------------------------------------------------------
    function "-" ( left : state_variable_record; right : integer)
        return integer;
    function "-" ( left : integer ; right : state_variable_record)
        return integer;
    function "-" ( left : state_variable_record ; right : state_variable_record)
        return integer;
    function "-" ( system_state : state_variable_record)
        return int18;
------------------------------------------------------------------------
    function "+" ( left : state_variable_record; right : integer)
        return integer;
    function "+" ( left : integer ; right : state_variable_record)
        return integer;
    function "+" ( left : state_variable_record ; right : state_variable_record)
        return integer;
------------------------------------------------------------------------
end package state_variable_pkg;

------------------------------------------------------------------------
------------------------------------------------------------------------
package body state_variable_pkg is

--------------------------------------------------
    function init_state_variable_gain
    (
        integrator_gain : int18
    )
    return state_variable_record
    is
        variable state_variable : state_variable_record;
    begin
        state_variable := (state => 0, integrator_gain => integrator_gain, state_counter => 1);
        return state_variable;
    end init_state_variable_gain;

--------------------------------------------------
    procedure create_state_variable
    (
        signal state_variable : inout state_variable_record;
        signal hw_multiplier : inout multiplier_record;
        state_equation : int18
    ) is
    begin 
        if state_variable.state_counter = 0 then
            integrate_state(state_variable, hw_multiplier, 15, state_equation);
            increment_counter_when_ready(hw_multiplier, state_variable.state_counter);
        end if;

    end create_state_variable;

--------------------------------------------------
    procedure integrate_state
    (
        signal state_variable : inout state_variable_record;
        signal multiplier : inout multiplier_record;
        constant radix : in natural;
        state_equation : in int18
    ) is
        alias integrator_gain is state_variable.integrator_gain;
    begin
        sequential_multiply(multiplier, integrator_gain, state_equation); 
        if multiplier_is_ready(multiplier) then
            state_variable.state <= get_multiplier_result(multiplier, radix) + state_variable.state;
        end if;
        
    end integrate_state;
------------------------------------------------------------------------
    procedure calculate
    (
        signal state_variable : out state_variable_record
    ) is
    begin
        state_variable.state_counter <= 0;
    end calculate;
------------------------------------------------------------------------
    procedure request_state_variable_calculation
    (
        signal state_variable : out state_variable_record 
    ) is
    begin
        calculate(state_variable);
        
    end request_state_variable_calculation;

------------------------------------------------------------------------
    function "-"
    (
        left : state_variable_record;
        right : integer
    )
    return integer
    is
    begin
        return left.state - right;
    end "-";

    function "-"
    (
        left : integer ;
        right : state_variable_record
    )
    return integer
    is
    begin
        return left - right.state ;
        
    end "-";

    function "-"
    (
        left : state_variable_record ;
        right : state_variable_record
    )
    return integer
    is
    begin
        return left.state - right.state;
        
    end "-";

    function "-"
    (
        system_state : state_variable_record
    )
    return int18
    is
    begin
        return -system_state.state;
    end "-";
------------------------------------------------------------------------
    function "+"
    (
        left : state_variable_record;
        right : integer
    )
    return integer
    is
    begin
        return left.state + right;
    end "+";

    function "+"
    (
        left : integer ;
        right : state_variable_record
    )
    return integer
    is
    begin
        return right + left;
        
    end "+";

    function "+"
    (
        left : state_variable_record ;
        right : state_variable_record
    )
    return integer
    is
    begin
        return right.state + left.state;
        
    end "+";


------------------------------------------------------------------------
end package body state_variable_pkg;
