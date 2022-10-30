LIBRARY ieee  ; 
LIBRARY std  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    USE ieee.std_logic_textio.all  ; 
    use ieee.math_real.all;
    USE std.textio.all  ; 

    use work.multiplier_pkg.all;
    use work.state_variable_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity tb_state_variable is
  generic (runner_cfg : string);
end;

architecture sim of tb_state_variable is
    signal rstn : std_logic;

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    signal clocked_reset : std_logic;
    constant clock_per : time := 8.4 ns;
    constant clock_half_per : time := 4.2 ns;
    constant simtime_in_clocks : integer := 25e3;

    signal simulation_counter : natural := 0;
    signal multiplier_output : signed(35 downto 0);
    signal multiplier_is_ready_when_1 : std_logic;
    signal int_multiplier_output : int := 0;

    signal hw_multiplier : multiplier_record := multiplier_init_values;
    signal hw_multiplier2 : multiplier_record := multiplier_init_values;
------------------------------------------------------------------------
    signal simulation_trigger_counter : natural := 0;
------------------------------------------------------------------------
    -- lrc model signals
    signal input_voltage : int     := 0;
    signal capacitor_delta : int   := 0;

    signal inductor_current_delta    : int := 0;
    signal inductor_integrator_gain  : int := 25e3;
    signal capacitor_integrator_gain : int := 2000;
    signal load_resistance           : int := 10; 
    signal inductor_series_resistance : int := 950;

    signal load_current : int := 0;

    signal process_counter : natural := 0;


    signal inductor_current   : state_variable_record := init_state_variable_gain(inductor_integrator_gain);
    signal capacitor_voltage  : state_variable_record := init_state_variable_gain(capacitor_integrator_gain);
    signal inductor2_current  : state_variable_record := init_state_variable_gain(inductor_integrator_gain);
    signal capacitor2_voltage : state_variable_record := init_state_variable_gain(capacitor_integrator_gain);

    signal int_inductor_current  : int;
    signal int_capacitor_voltage : int;
begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        simulation_running <= false;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

------------------------------------------------------------------------
    sim_clock_gen : process
    begin
        simulator_clock <= '0';
        rstn <= '0';
        simulator_clock <= '0';
        wait for clock_half_per;
        while simulation_running loop
            wait for clock_half_per;
                rstn <= '1';
                simulator_clock <= not simulator_clock;
            end loop;
        wait;
    end process;
------------------------------------------------------------------------

    clocked_reset_generator : process(simulator_clock)
    --------------------------------------------------
        impure function "*" ( left, right : int)
        return int
        is
        begin
            sequential_multiply(hw_multiplier, left, right);
            return get_multiplier_result(hw_multiplier, 15);
        end "*";
    --------------------------------------------------

    begin
        if rising_edge(simulator_clock) then

            create_multiplier(hw_multiplier); 
            create_multiplier(hw_multiplier2); 

            simulation_counter <= simulation_counter + 1;

            simulation_trigger_counter <= simulation_trigger_counter + 1;
            if simulation_trigger_counter = 19 then
                simulation_trigger_counter <= 0;
                process_counter <= 0;
            end if;

            input_voltage <= 32e2;
            if simulation_counter = 17000  then
                load_resistance <= 65e3;
            end if;

            CASE process_counter is 
                WHEN 0 => 
                    multiply_and_get_result(multiplier => hw_multiplier, radix =>15, result => inductor_current_delta, left => inductor_series_resistance, right => inductor_current.state);
                    increment_counter_when_ready(hw_multiplier, process_counter);

                WHEN 1 => 
                    integrate_state(inductor_current, hw_multiplier, 15, input_voltage - capacitor_voltage.state - inductor_current_delta);
                    increment_counter_when_ready(hw_multiplier, process_counter);

                WHEN 2 => 
                    multiply_and_get_result(multiplier => hw_multiplier, radix =>15, result => capacitor_delta, left => load_resistance, right => capacitor_voltage.state);
                    increment_counter_when_ready(hw_multiplier, process_counter);

                WHEN 3 =>
                    integrate_state(capacitor_voltage, hw_multiplier, 15, inductor_current.state - load_current - capacitor_delta);
                    increment_counter_when_ready(hw_multiplier, process_counter);
                WHEN others => -- do nothing

            end CASE; 
        end if; -- rstn
    end process clocked_reset_generator;	

    int_inductor_current <= inductor_current.state;
    int_capacitor_voltage <= capacitor_voltage.state;

------------------------------------------------------------------------
end sim;
