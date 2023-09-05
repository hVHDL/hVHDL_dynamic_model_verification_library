library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_pkg.all;

------------------------------------------------------------------------
package state_variable_pkg is

    type state_variable_record is record
        state_variable_has_been_calculated : boolean;
        state           : s_int;
        integrator_gain : s_int;
        state_counter : natural range 0 to 7;
    end record;

    function init_state_variable return state_variable_record;

--------------------------------------------------
    function state_variable_calculation_is_ready ( state_variable : state_variable_record)
        return boolean;
--------------------------------------------------
    function init_state_variable_gain ( integrator_gain : signed)
        return state_variable_record;

--------------------------------------------------
    procedure create_state_variable (
        signal state_variable : inout state_variable_record;
        signal hw_multiplier : inout multiplier_record;
        radix : integer;
        state_equation : in signed);

--------------------------------------------------
    procedure create_state_variable (
        signal state_variable : inout state_variable_record;
        signal hw_multiplier : inout multiplier_record;
        state_equation : in signed);

------------------------------------------------------------------------
    procedure integrate_state (
        signal state_variable : inout state_variable_record;
        state_equation : in signed);

--------------------------------------------------
    procedure integrate_state (
        signal state_variable : inout state_variable_record;
        signal multiplier : inout multiplier_record;
        constant radix : in natural;
        state_equation : in signed);

------------------------------------------------------------------------
    procedure calculate ( signal state_variable : out state_variable_record);

    procedure request_state_variable_calculation (
        signal state_variable : out state_variable_record );
------------------------------------------------------------------------
    function get_state ( state_variable : state_variable_record)
        return signed;
------------------------------------------------------------------------
    function "-" ( left : state_variable_record; right : signed)
        return signed;
    function "-" ( left : signed ; right : state_variable_record)
        return signed;
    function "-" ( left : state_variable_record ; right : state_variable_record)
        return signed;
    function "-" ( system_state : state_variable_record)
        return signed;
------------------------------------------------------------------------
    function "+" ( left : state_variable_record; right : signed)
        return signed;
    function "+" ( left : signed ; right : state_variable_record)
        return signed;
    function "+" ( left : state_variable_record ; right : state_variable_record)
        return signed;
------------------------------------------------------------------------
end package state_variable_pkg;

------------------------------------------------------------------------
------------------------------------------------------------------------
package body state_variable_pkg is


    constant initial_values_for_state_variable : state_variable_record := (false, (others => '0'), (others => '0'), 7);

    function init_state_variable return state_variable_record
    is
    begin
        return initial_values_for_state_variable;
        
    end init_state_variable;

--------------------------------------------------
    function state_variable_calculation_is_ready
    (
        state_variable : state_variable_record
    )
    return boolean
    is
    begin
        return state_variable.state_variable_has_been_calculated;
    end state_variable_calculation_is_ready;
--------------------------------------------------
    function init_state_variable_gain
    (
        integrator_gain : signed
    )
    return state_variable_record
    is
        variable state_variable : state_variable_record := init_state_variable;
    begin
        state_variable := (state_variable_has_been_calculated => false, state => (others => '0'), integrator_gain => integrator_gain, state_counter => 2);
        return state_variable;
    end init_state_variable_gain;

--------------------------------------------------
    procedure create_state_variable
    (
        signal state_variable : inout state_variable_record;
        signal hw_multiplier : inout multiplier_record;
        radix : integer;
        state_equation : in signed
    ) is
        variable mpy_result : s_int;
    begin 
        state_variable.state_variable_has_been_calculated <= false;
        CASE  state_variable.state_counter is
            WHEN 0 =>
                if multiplier_is_not_busy(hw_multiplier) then
                    multiply(hw_multiplier, state_variable.integrator_gain, state_equation); 
                    increment(state_variable.state_counter);
                end if;
            WHEN 1 =>
                if multiplier_is_ready(hw_multiplier) then
                    state_variable.state_variable_has_been_calculated <= true;
                    mpy_result := get_multiplier_result(hw_multiplier, radix);
                    state_variable.state <=  mpy_result + state_variable.state;
                    increment(state_variable.state_counter);
                end if;
            WHEN others => -- do nothing
        end CASE;

    end create_state_variable;

--------------------------------------------------
    procedure create_state_variable
    (
        signal state_variable : inout state_variable_record;
        signal hw_multiplier : inout multiplier_record;
        state_equation : in signed
    ) is
        variable mpy_result : s_int;
    begin 
        state_variable.state_variable_has_been_calculated <= false;
        if state_variable.state_counter = 0 then
            sequential_multiply(hw_multiplier, state_variable.integrator_gain, state_equation);
            if multiplier_is_ready(hw_multiplier) then
                state_variable.state_variable_has_been_calculated <= true;
                mpy_result := get_multiplier_result(hw_multiplier, 15);
                state_variable.state <= state_variable.state + mpy_result;
                increment(state_variable.state_counter);
            end if;

        end if;

    end create_state_variable;

--------------------------------------------------
    procedure integrate_state
    (
        signal state_variable : inout state_variable_record;
        state_equation : in signed
    ) is
    begin
        state_variable.state <= state_equation + state_variable.state;
        
    end integrate_state;

--------------------------------------------------
    procedure integrate_state
    (
        signal state_variable : inout state_variable_record;
        signal multiplier : inout multiplier_record;
        constant radix : in natural;
        state_equation : in signed
    ) is
        alias integrator_gain is state_variable.integrator_gain;
    begin
        sequential_multiply(multiplier, integrator_gain, state_equation); 
        if multiplier_is_ready(multiplier) then
            integrate_state(state_variable, get_multiplier_result(multiplier, radix));
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
    function get_state
    (
        state_variable : state_variable_record
    )
    return signed
    is
    begin
        return state_variable.state;
        
    end get_state;
------------------------------------------------------------------------
    function "-"
    (
        left : state_variable_record;
        right : signed
    )
    return signed
    is
    begin
        return left.state - right;
    end "-";

------------------------------------------------------------------------
    function "-"
    (
        left : signed ;
        right : state_variable_record
    )
    return signed
    is
    begin
        return left - right.state ;
        
    end "-";

------------------------------------------------------------------------
    function "-"
    (
        left : state_variable_record ;
        right : state_variable_record
    )
    return signed
    is
    begin
        return left.state - right.state;
        
    end "-";

------------------------------------------------------------------------
    function "-"
    (
        system_state : state_variable_record
    )
    return signed
    is
    begin
        return -system_state.state;
    end "-";
------------------------------------------------------------------------
    function "+"
    (
        left : state_variable_record;
        right : signed
    )
    return signed
    is
    begin
        return left.state + right;
    end "+";

    function "+"
    (
        left : signed ;
        right : state_variable_record
    )
    return signed
    is
    begin
        return right + left;
        
    end "+";

    function "+"
    (
        left : state_variable_record ;
        right : state_variable_record
    )
    return signed
    is
    begin
        return right.state + left.state;
        
    end "+";


------------------------------------------------------------------------
end package body state_variable_pkg;
