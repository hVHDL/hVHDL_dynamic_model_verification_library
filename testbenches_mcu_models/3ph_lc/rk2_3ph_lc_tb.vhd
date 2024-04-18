library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

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
    use work.write_pkg.all;

package arraymath is

    function "*" ( number : real; num_array : real_array)
        return real_array;

    function "/" ( number : real; num_array : real_array)
        return real_array;

    function "/" ( num_array : real_array; number : real)
        return real_array;

end package arraymath;

package body arraymath is
------------------------------------------------------------------------
    function "*"
    (
        number : real; num_array : real_array
    )
    return real_array
    is
        variable retval : real_array(num_array'range);
    begin
        for i in num_array'range loop
            retval(i) := num_array(i)*number;
        end loop;

        return retval;

    end "*";
------------------------------------------------------------------------
    function "/"
    (
        number : real; num_array : real_array
    )
    return real_array
    is
        variable retval : real_array(num_array'range);
    begin
        for i in num_array'range loop
            retval(i) := number/num_array(i);
        end loop;

        return retval;

    end "/";
------------------------------------------------------------------------
    function "/"
    (
        num_array : real_array; number : real
    )
    return real_array
    is
        variable retval : real_array(num_array'range);
    begin
        for i in num_array'range loop
            retval(i) := num_array(i)/number;
        end loop;

        return retval;

    end "/";
------------------------------------------------------------------------

end package body arraymath;

LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.arraymath.all;

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
    use work.write_pkg.all;

entity rk2_3ph_lc_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of rk2_3ph_lc_tb is

    constant clock_period      : time    := 1 ns;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;

        subtype t_retval is real_array(0 to 5);

        function calculate_lcr_3ph
        (
            u1 : real;
            u2 : real;
            u3 : real;

            uc1_ref : real;
            uc2_ref : real;
            uc3_ref : real;

            i1_ref : real;
            i2_ref : real;
            i3_ref : real;

            r : real_array;
            l : real_array;
            c : real_array;
            timestep : real
        )
        return t_retval
        is

            variable add      : real_array(0 to 15) := (others => 0.0);
            variable sub      : real_array(0 to 15) := (others => 0.0);
            variable mult_add : real_array(0 to 15) := (others => 0.0);
            variable mult     : real_array(0 to 15) := (others => 0.0);
            variable result   : real_array(0 to 15) := (others => 0.0);

            constant neutral_gains : real_array := (l(1)*l(2) , l(0)*l(2), l(0)*l(1)) / (l(0)*l(1) + l(0)*l(2) + l(1)*l(2));
        begin
            mult_add(0) := uc1_ref + i1_ref * r(0);
            mult_add(1) := uc2_ref + i2_ref * r(1);
            mult_add(2) := uc3_ref + i3_ref * r(2);

            mult(6) := (i1_ref) / c(0) * timestep; -- uc1k(0)
            mult(7) := (i2_ref) / c(1) * timestep; -- uc2k(0)
            mult(8) := (i3_ref) / c(2) * timestep; -- uc3k(0)
            sub(0) := u1 - mult_add(0); --ul1 := sub(0);
            sub(1) := u2 - mult_add(1); --ul2 := sub(1);
            sub(2) := u3 - mult_add(2); --ul3 := sub(2);

            mult(0) := sub(0) * neutral_gains(0);
            mult(1) := sub(1) * neutral_gains(1);
            mult(2) := sub(2) * neutral_gains(2);

            add(0) := mult(0) + mult(1);

            add(1) := add(0) + mult(2); -- vn

            sub(3) := sub(0) - add(1);
            sub(4) := sub(1) - add(1);
            sub(5) := sub(2) - add(1);

            mult(3) := (sub(3)) / l(0) * timestep; -- i1k(0)
            mult(4) := (sub(4)) / l(1) * timestep; -- i2k(0)
            mult(5) := (sub(5)) / l(2) * timestep; -- i3k(0)

            return (
                    mult(3), -- i1k(0)
                    mult(4), -- i2k(0)
                    mult(5), -- i3k(0)
                    mult(6), -- uc1k(0)
                    mult(7), -- uc2k(0)
                    mult(8)  -- uc3k(0)
                );   
            
        end calculate_lcr_3ph;

    -----------------------------------
    -----------------------------------
    -----------------------------------
    -----------------------------------
    -- simulation specific signals ----
    ------------------------------------------------------------------------

    signal i1 : real := 0.0;
    signal i2 : real := 0.0;
    signal i3 : real := 0.0;
    signal uc1 : real := 0.0;
    signal uc2 : real := 0.0;
    signal uc3 : real := 0.0;

    signal i1_ref  : real := 0.0;
    signal i2_ref  : real := 0.0;
    signal i3_ref  : real := 0.0;
    signal uc1_ref : real := 0.0;
    signal uc2_ref : real := 0.0;
    signal uc3_ref : real := 0.0;

    constant init_phase : real := 0.0;

    constant init_u1 : real := sin((init_phase+2.0*math_pi/3.0) mod (2.0*math_pi));
    constant init_u2 : real := sin(init_phase);
    constant init_u3 : real := -init_u1-init_u2;

    signal u1 : real := init_u1;
    signal u2 : real := init_u2;
    signal u3 : real := init_u3;

    signal simtime : real := 0.0;
    constant timestep : real := 1.5e-6;
    constant stoptime : real := 20.0e-3;


    constant r : real_array(0 to 2) := (0.03  , 0.03  , 0.03);
    constant l : real_array(0 to 2) := (80.0e-6, 80.0e-6, 80.0e-6);
    constant c : real_array(0 to 2) := (60.0e-6, 60.0e-6, 60.0e-6);

    constant neutral_gains : real_array := (l(1)*l(2) , l(0)*l(2), l(0)*l(1)) / (l(0)*l(1) + l(0)*l(2) + l(1)*l(2));

    signal sine_amplitude : real := 1.0;
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

    signal usum : real := 0.0;
    signal usum_ref : real := 0.0;
    signal isum_ref : real := 0.0;

    signal un : real := 0.0;

    signal di1 : real := 0.0;
    signal di2 : real := 0.0;
    signal di3 : real := 0.0;

begin

------------------------------------------------------------------------
    process
    begin
        test_runner_setup(runner, runner_cfg);
        wait until simtime >= stoptime;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process;

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

        variable used_instruction : t_instruction;

        variable ul1  : real := 0.0;
        variable ul2  : real := 0.0;
        variable ul3  : real := 0.0;

        variable add      : real_array(0 to 15) := (others => 0.0);
        variable sub      : real_array(0 to 15) := (others => 0.0);
        variable mult_add : real_array(0 to 15) := (others => 0.0);
        variable mult     : real_array(0 to 15) := (others => 0.0);
        variable result   : real_array(0 to 15) := (others => 0.0);

        variable i1k : real_array(0 to 3) := (others => 0.0);
        variable uc1k : real_array(0 to 3) := (others => 0.0);

        variable i2k : real_array(0 to 3) := (others => 0.0);
        variable uc2k : real_array(0 to 3) := (others => 0.0);

        variable i3k : real_array(0 to 3) := (others => 0.0);
        variable uc3k : real_array(0 to 3) := (others => 0.0);

        variable phase : real := init_phase;

        file file_handler : text open write_mode is "lcr_3ph_general_tb.dat";

        variable vn : real := 0.0;
        variable retvals : real_array(0 to 5);

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            if simulation_counter = 0 then
                init_simfile(file_handler, ("time", "rkv1", "rkv2", "rkv3", "rki1", "rki2", "rki3", "mcv1", "mcv2", "mcv3", "mci1", "mci2", "mci3"));
            end if;
            CASE sequencer is
                WHEN 0 => 

                ------------------------------------------------------------------------
                -- runge kutta 1st iteration

                    -- load current
                    -- sub(0) := i1_ref - i1_load
                    -- sub(0) := i2_ref - i2_load
                    -- sub(0) := i3_ref - i3_load

                    retvals := calculate_lcr_3ph(u1, u2, u3, uc1_ref, uc2_ref, uc3_ref, i1_ref, i2_ref, i3_ref, r, l, c, timestep);

                    i1k(0) := retvals(0);
                    i2k(0) := retvals(1);
                    i3k(0) := retvals(2);
                    uc1k(0) := retvals(3);
                    uc2k(0) := retvals(4);
                    uc3k(0) := retvals(5);

                ------------------------------------------------------------------------
                    retvals := calculate_lcr_3ph(u1, u2, u3, 
                        (uc1_ref+uc1k(0) / 2.0),
                        (uc2_ref+uc2k(0) / 2.0),
                        (uc3_ref+uc3k(0) / 2.0),
                        (i1_ref+i1k(0) / 2.0),
                        (i2_ref+i2k(0) / 2.0),
                        (i3_ref+i3k(0) / 2.0),
                        r, l, c, timestep);

                    i1k(1) := retvals(0);
                    i2k(1) := retvals(1);
                    i3k(1) := retvals(2);
                    uc1k(1) := retvals(3);
                    uc2k(1) := retvals(4);
                    uc3k(1) := retvals(5);

                ------------------------------------------------------------------------
                ------------------------------------------------------------------------
                -- runge kutta output

                    i1_ref <= i1_ref + i1k(1);
                    i2_ref <= i2_ref + i2k(1);
                    i3_ref <= i3_ref + i3k(1);

                    uc1_ref <= uc1_ref + uc1k(1);
                    uc2_ref <= uc2_ref + uc2k(1);
                    uc3_ref <= uc3_ref + uc3k(1);

                ------------------------------------------------------------------------

                    write_to(file_handler,(simtime, uc1, uc2, uc3, i1, i2, i3 , uc1_ref, uc2_ref, uc3_ref, i1_ref, i2_ref, i3_ref));
                    sequencer <= sequencer + 1;

                    phase := ((simtime + timestep)*2.0*math_pi*1000.0) mod (2.0*math_pi);
                    simtime <= simtime + timestep;

                    u1 <= sine_amplitude*sin((phase+2.0*math_pi/3.0) mod (2.0*math_pi));
                    u2 <= 0.2*sine_amplitude*sin(phase);
                    u3 <= sine_amplitude*sin((phase-2.0*math_pi/3.0) mod (2.0*math_pi));

                WHEN others => -- do nothing
            end CASE;

            if sequencer = 0 then
                sequencer <= 0;
            end if;

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
