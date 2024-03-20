
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.microinstruction_pkg.all;
    use work.multi_port_ram_pkg.all;
    use work.simple_processor_pkg.all;
    use work.processor_configuration_pkg.all;
    use work.float_alu_pkg.all;
    use work.float_type_definitions_pkg.all;
    use work.float_to_real_conversions_pkg.all;

    use work.memory_processing_pkg.all;
    use work.float_assembler_pkg.all;
    use work.microinstruction_pkg.all;

entity lcr_simulation_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of lcr_simulation_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 100e3;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----
    ------------------------------------------------------------------------

------------------------------------------------------------------------
    signal current : real := 0.0;
    signal voltage : real := 0.0;
    signal input_voltage : real := 1.0;
    signal r : real := 0.5;
    signal l : real := 0.01;
    signal c : real := 0.01;
    signal sequencer : natural := 0;

    constant input_voltage_addr : natural := 89;
    constant voltage_addr       : natural := 90;
    constant current_addr       : natural := 91;
    constant c_addr             : natural := 92;
    constant l_addr             : natural := 93;
    constant r_addr             : natural := 94;
    constant mac1_addr          : natural := 95;
    constant mac2_addr          : natural := voltage_addr;
    constant sub1_addr          : natural := 97;

    function build_lcr_sw (filter_gain : real range 0.0 to 1.0; u_address, y_address, g_address, temp_address : natural) return ram_array
    is

        constant program : program_array :=(
            pipelined_block(
                program_array'(
                write_instruction(mpy_add, mac1_addr, current_addr, r_addr, voltage_addr),
                write_instruction(mpy_add, mac2_addr, current_addr, c_addr, voltage_addr)
                )
            ) &
            pipelined_block(
                write_instruction(sub, sub1_addr, input_voltage_addr, mac1_addr)
            ) &
            pipelined_block(
                write_instruction(mpy_add, current_addr, sub1_addr, l_addr, current_addr)
            ) &
            write_instruction(program_end));
        ------------------------------
        variable retval : ram_array := (others => (others => '0'));
    begin
        for i in program'range loop
            retval(i) := program(i);
        end loop;
        retval(input_voltage_addr) := to_std_logic_vector(to_float(1.0));
        retval(voltage_addr      ) := to_std_logic_vector(to_float(0.0));
        retval(current_addr      ) := to_std_logic_vector(to_float(0.0));
        retval(c_addr            ) := to_std_logic_vector(to_float(0.01));
        retval(l_addr            ) := to_std_logic_vector(to_float(0.01));
        retval(r_addr            ) := to_std_logic_vector(to_float(0.5));
        retval(mac1_addr         ) := to_std_logic_vector(to_float(0.0));
        retval(mac2_addr         ) := to_std_logic_vector(to_float(0.0));
        retval(sub1_addr         ) := to_std_logic_vector(to_float(0.0));

        return retval;
    end build_lcr_sw;

------------------------------------------------------------------------
    constant ram_contents : ram_array := build_lcr_sw(0.05 , 0 , 0 , 0, 0);
------------------------------------------------------------------------

    signal self                     : simple_processor_record := init_processor;
    signal ram_read_instruction_in  : ram_read_in_record  := (0, '0');
    signal ram_read_instruction_out : ram_read_out_record ;
    signal ram_read_data_in         : ram_read_in_record  := (0, '0');
    signal ram_read_data_out        : ram_read_out_record ;
    signal ram_read_2_data_in       : ram_read_in_record  := (0, '0');
    signal ram_read_2_data_out      : ram_read_out_record ;
    signal ram_read_3_data_in       : ram_read_in_record  := (0, '0');
    signal ram_read_3_data_out      : ram_read_out_record ;
    signal ram_write_port           : ram_write_in_record ;

    signal processor_is_ready : boolean := false;

    signal counter : natural range 0 to 7 :=7;
    signal counter2 : natural range 0 to 7 :=7;

    signal result1 : real := 0.0;
    signal result2 : real := 0.0;
    signal result3 : real := 0.0;

    signal float_alu : float_alu_record := init_float_alu;


    signal testi1 : real := 0.0;
    signal testi2 : real := 0.0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        check(abs(result3-voltage) < 0.01);
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)
        variable used_instruction : t_instruction;
        variable mac1 : real := 0.0;
        variable sub1 : real := 0.0;
        variable mac2 : real := 0.0;
        variable mac3 : real := 0.0;
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            CASE sequencer is
                WHEN 0 => 
                    mac1 := current * r + voltage;
                    mac2 := current * c + voltage;

                    sub1 := input_voltage - mac1;

                    mac3 := sub1 * l + current;

                    current   <= mac3;
                    voltage   <= mac2;
                    sequencer <= sequencer + 1;
                WHEN others => -- do nothing
            end CASE;

            --------------------
            create_simple_processor (
                self                     ,
                ram_read_instruction_in  ,
                ram_read_instruction_out ,
                ram_read_data_in         ,
                ram_read_data_out        ,
                ram_write_port           ,
                used_instruction);

            init_ram_read(ram_read_2_data_in);
            init_ram_read(ram_read_3_data_in);
            create_float_alu(float_alu);

            create_memory_process_pipeline(
             self                     ,
             float_alu                ,
             used_instruction         ,
             ram_read_instruction_out ,
             ram_read_data_in         ,
             ram_read_data_out        ,
             ram_read_2_data_in       ,
             ram_read_2_data_out      ,
             ram_read_3_data_in       ,
             ram_read_3_data_out      ,
             ram_write_port          );


        ------------------------------------------------------------------------
        ------------------------------------------------------------------------
            ------------------------------------------------------------------------
            -- test signals
            ------------------------------------------------------------------------
            if simulation_counter mod 61 = 0 then
                request_processor(self);
            end if;
            processor_is_ready <= processor_is_enabled(self);
            if program_is_ready(self) then
                counter <= 0;
                counter2 <= 0;
                sequencer <= 0;
            end if;
            if counter < 7 then
                counter <= counter +1;
            end if;

            CASE counter is
                WHEN 0 => request_data_from_ram(ram_read_data_in, voltage_addr);
                WHEN 1 => request_data_from_ram(ram_read_data_in, current_addr);
                WHEN others => --do nothing
            end CASE;
            if not processor_is_enabled(self) then
                if ram_read_is_ready(ram_read_data_out) then
                    counter2 <= counter2 + 1;
                    CASE counter2 is
                        WHEN 0 => result3 <= to_real(to_float(get_ram_data(ram_read_data_out)));
                        WHEN 1 => result2 <= to_real(to_float(get_ram_data(ram_read_data_out)));
                        WHEN others => -- do nothing
                    end CASE; --counter2
                end if;
            end if;

        end if; -- rising_edge
    end process stimulus;	

------------------------------------------------------------------------
    u_mpram : entity work.ram_read_x4_write_x1
    generic map(ram_contents)
    port map(
    simulator_clock          ,
    ram_read_instruction_in  ,
    ram_read_instruction_out ,
    ram_read_data_in         ,
    ram_read_data_out        ,
    ram_read_2_data_in       ,
    ram_read_2_data_out      ,
    ram_read_3_data_in       ,
    ram_read_3_data_out      ,
    ram_write_port);
------------------------------------------------------------------------
end vunit_simulation;
