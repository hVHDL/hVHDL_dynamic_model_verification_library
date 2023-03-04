LIBRARY ieee, std  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity buck_with_input_and_output_filters_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of buck_with_input_and_output_filters_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 30e3*2;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    constant timestep : real := 1.0e-6; --seconds
    constant inductor : real := 1000.0e-6;
    constant capacitor : real := 42.2e-6;
    constant inductor_gain : real := timestep/inductor;
    constant capacitor_gain : real := timestep/capacitor;

    constant inductor1_gain : real := timestep/100.0e-6;
    constant capacitor1_gain : real := timestep/100.0e-6;

    constant inductor2_gain : real := timestep/10.0e-6;
    constant capacitor2_gain : real := timestep/10.0e-6;

    signal current1 : real := 0.0;
    signal voltage1 : real := 400.0;

    signal current2 : real := 0.0;
    signal voltage2 : real := 400.0;

    signal current : real := 0.0;
    signal voltage : real := 0.0;

    signal current_01 : real := 0.0;
    signal voltage_01 : real := 0.0;

    signal current_02 : real := 0.0;
    signal voltage_02 : real := 0.0;

    signal counter : integer := 0;
    signal realtime : real := 0.0;
    signal duty : real := 0.5;
    signal input_voltage : real := 400.0;
    signal load_current : real := 0.0;

    type real_array is array (integer range <>) of real;
    procedure write_to
    (
        file filee : text;
        data_to_be_written : real_array
        
    ) is
        variable row : line;
        constant number_of_characters_between_columns : integer := 30;
    begin
        
        for i in data_to_be_written'range loop
            write(row , data_to_be_written(i) , left , number_of_characters_between_columns);
        end loop;

        writeline(filee , row);
    end write_to;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

        function "="
        (
            left, right : real
        )
        return boolean
        is
            variable return_value : boolean := false;
        begin

            if abs(left-right) < 1.0e-6 then
                return_value := true;
            else
                return_value := false;
            end if;

            return return_value;
            
        end "=";
------------------------------------------------------------------------
        procedure create_lc_section
        (
            signal i, u        : inout real;
            voltage_in, load_i : in real;
            i_gain, u_gain     : in real
        ) is
        begin
            CASE counter is
                WHEN 0 => i <= i + i_gain*(voltage_in - u);
                WHEN 1 => u <= u + u_gain*(i - load_i);
                WHEN others => --do nothing
            end CASE;
            
        end create_lc_section;
------------------------------------------------------------------------
        file file_handler : text open write_mode is "buck_with_input_and_output_filters.dat";
------------------------------------------------------------------------
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            counter <= simulation_counter mod 2;

            create_lc_section(current2   , voltage2   , input_voltage-0.01*current2 , current1     , timestep/10.0e-6   , timestep/10.0e-6  );
            create_lc_section(current1   , voltage1   , voltage2                    , current*duty , timestep/100.0e-6  , timestep/100.0e-6 );
            create_lc_section(current    , voltage    , voltage1*duty-0.3*current   , current_01   , timestep/1000.0e-6 , timestep/20.0e-6  );
            create_lc_section(current_01 , voltage_01 , voltage                     , current_02   , timestep/10.0e-6   , timestep/2.2e-6   );
            create_lc_section(current_02 , voltage_02 , voltage_01                  , load_current , timestep/10.0e-6   , timestep/20.0e-6  );

            if counter = 1 then
                realtime <= realtime + timestep;

                write_to(file_handler,(0  => realtime,
                                       1  => current2,
                                       2  => voltage2,
                                       3  => current1,
                                       4  => voltage1,
                                       5  => current,
                                       6  => voltage,
                                       7  => current_01,
                                       8  => voltage_01,
                                       9  => current_02,
                                       10 => voltage_02
                                   ));
            end if;
            
            if (realtime = 10.0e-3) then
                load_current <= 10.0;
            end if;

            if (realtime = 20.0e-3) then
                input_voltage <= 390.0;
            end if;


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
