
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    use std.textio.all;

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
    use work.write_pkg.all;

entity lcr_3ph_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of lcr_3ph_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 20e2;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----
    ------------------------------------------------------------------------

------------------------------------------------------------------------
    signal i1 : real := 0.0;
    signal i2 : real := 0.0;
    signal i3 : real := 0.0;
    signal uc1 : real := 0.0;
    signal uc2 : real := 0.0;
    signal uc3 : real := 0.0;

    signal i1_ref : real := 0.0;
    signal i2_ref : real := 0.0;
    signal i3_ref : real := 0.0;
    signal uc1_ref : real := 0.0;
    signal uc2_ref : real := 0.0;
    signal uc3_ref : real := 0.0;

    constant init_phase : real := 0.4;
    signal phase : real := 0.7*2.0*math_pi;

    signal u1 : real := 0.0;
    signal u2 : real := 0.0;
    signal u3 : real := 0.0;

    signal simtime : real := 0.0;
    constant timestep : real := 10.0e-6;

    signal r : real := 0.55;
    signal l : real := timestep/100.0e-6;
    signal c : real := timestep/100.0e-6;
    signal sequencer : natural := 1;

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


begin

------------------------------------------------------------------------
    process
    begin
        test_runner_setup(runner, runner_cfg);
        wait until simtime >= 10.0e-3;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process;

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

        variable used_instruction : t_instruction;

        variable mac1 : real := 0.0;
        variable sub1 : real := 0.0;
        variable mac2 : real := 0.0;
        variable mac3 : real := 0.0;
        variable ul1  : real := 0.0;

    type realarray is array (natural range <>) of real;

        variable add      : realarray(0 to 15) := (others => 0.0);
        variable sub      : realarray(0 to 15) := (others => 0.0);
        variable mult_add : realarray(0 to 15) := (others => 0.0);
        variable mult     : realarray(0 to 15) := (others => 0.0);
        variable result   : realarray(0 to 15) := (others => 0.0);

        variable i1k : realarray(0 to 3) := (others => 0.0);
        variable uc1k : realarray(0 to 3) := (others => 0.0);

        variable i2k : realarray(0 to 3) := (others => 0.0);
        variable uc2k : realarray(0 to 3) := (others => 0.0);

        variable i3k : realarray(0 to 3) := (others => 0.0);
        variable uc3k : realarray(0 to 3) := (others => 0.0);

        file file_handler : text open write_mode is "lcr_3ph_tb.dat";
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            if simulation_counter = 0 then
                -- init_simfile(file_handler, ("time", "vol1", "vol2", "vol3", "cur1", "cur2", "cur3"));
                init_simfile(file_handler, ("time", "vol1", "vol2", "vol3"));
            end if;

            i1k := (others => 0.0);
            uc1k := (others => 0.0);

            i2k := (others => 0.0);
            uc2k := (others => 0.0);

            i3k := (others => 0.0);
            uc3k := (others => 0.0);

            CASE sequencer is
                WHEN 1 => 

                    i1k(0)  := ( (+u1-u2-u3) - (+i1-i2-i3) * r - (+uc1-uc2-uc3))/2.0 * l/2.0;
                    i2k(0)  := ( (-u1+u2-u3) - (-i1+i2-i3) * r - (-uc1+uc2-uc3))/2.0 * l/2.0;
                    i3k(0)  := ( (-u1-u2+u3) - (-i1-i2+i3) * r - (-uc1-uc2+uc3))/2.0 * l/2.0;

                    uc1k(0) := ((+i1-i2-i3 ))/2.0 * c/2.0;
                    uc2k(0) := ((-i1+i2-i3 ))/2.0 * c/2.0;
                    uc3k(0) := ((-i1-i2+i3 ))/2.0 * c/2.0;

            ------------------------------

                    i1k(1)  := ( (+u1-u2-u3) - (+i1-i2-i3 +i1k(0)-i2k(0)-i3k(0))* r- (+uc1-uc2-uc3+uc1k(0)-uc2k(0)-uc3k(0)))/2.0 * l/2.0;
                    i2k(1)  := ( (-u1+u2-u3) - (-i1+i2-i3 -i1k(0)+i2k(0)-i3k(0))* r- (-uc1+uc2-uc3-uc1k(0)+uc2k(0)-uc3k(0)))/2.0 * l/2.0;
                    i3k(1)  := ( (-u1-u2+u3) - (-i1-i2+i3 -i1k(0)-i2k(0)+i3k(0))* r- (-uc1-uc2+uc3-uc1k(0)-uc2k(0)+uc3k(0)))/2.0 * l/2.0;

                    uc1k(1) := (+i1-i2-i3 +i1k(0)-i2k(0)-i3k(0))/2.0 * c/2.0;
                    uc2k(1) := (-i1+i2-i3 -i1k(0)+i2k(0)-i3k(0))/2.0 * c/2.0;
                    uc3k(1) := (-i1-i2+i3 -i1k(0)-i2k(0)+i3k(0))/2.0 * c/2.0;

            ------------------------------

                    i1k(2)  := ( (+u1-u2-u3) - (+i1-i2-i3+i1k(1)-i2k(1)-i3k(1)) * r- (+uc1-uc2-uc3+uc1k(1)-uc2k(1)-uc3k(1)))/2.0 * l;
                    i2k(2)  := ( (-u1+u2-u3) - (-i1+i2-i3-i1k(1)+i2k(1)-i3k(1)) * r- (-uc1+uc2-uc3-uc1k(1)+uc2k(1)-uc3k(1)))/2.0 * l;
                    i3k(2)  := ( (-u1-u2+u3) - (-i1-i2+i3-i1k(1)-i2k(1)+i3k(1)) * r- (-uc1-uc2+uc3-uc1k(1)-uc2k(1)+uc3k(1)))/2.0 * l;

                    uc1k(2) := ((+i1-i2-i3 +i1k(1)-i2k(1)-i3k(1)))/2.0 * c;
                    uc2k(2) := ((-i1+i2-i3 -i1k(1)+i2k(1)-i3k(1)))/2.0 * c;
                    uc3k(2) := ((-i1-i2+i3 -i1k(1)-i2k(1)+i3k(1)))/2.0 * c;

            ------------------------------

                    i1k(3)  := ( (+u1-u2-u3) - (+i1-i2-i3+i1k(2)-i2k(2)-i3k(2)) * r- (+uc1-uc2-uc3+uc1k(2)-uc2k(2)-uc3k(2)))/2.0 * l;
                    i2k(3)  := ( (-u1+u2-u3) - (-i1+i2-i3-i1k(2)+i2k(2)-i3k(2)) * r- (-uc1+uc2-uc3-uc1k(2)+uc2k(2)-uc3k(2)))/2.0 * l;
                    i3k(3)  := ( (-u1-u2+u3) - (-i1-i2+i3-i1k(2)-i2k(2)+i3k(2)) * r- (-uc1-uc2+uc3-uc1k(2)-uc2k(2)+uc3k(2)))/2.0 * l;

                    uc1k(3) := ((+i1-i2-i3 +i1k(2)-i2k(2)-i3k(2)))/2.0 * c;
                    uc2k(3) := ((-i1+i2-i3 -i1k(2)+i2k(2)-i3k(2)))/2.0 * c;
                    uc3k(3) := ((-i1-i2+i3 -i1k(2)-i2k(2)+i3k(2)))/2.0 * c;

            ------------------------------

                    i1 <= i1     + 1.0/6.0*(i1k(0)*2.0 + 4.0*i1k(1) + 2.0*i1k(2) + i1k(3));
                    i2 <= i2     + 1.0/6.0*(i2k(0)*2.0 + 4.0*i2k(1) + 2.0*i2k(2) + i2k(3));
                    i3 <= -i1-i2 + 1.0/6.0*(i3k(0)*2.0 + 4.0*i3k(1) + 2.0*i3k(2) + i3k(3));

                    uc1 <= uc1      + 1.0/6.0*(uc1k(0)*2.0 + 4.0*uc1k(1) + 2.0*uc1k(2) + uc1k(3));
                    uc2 <= uc2      + 1.0/6.0*(uc2k(0)*2.0 + 4.0*uc2k(1) + 2.0*uc2k(2) + uc2k(3));
                    uc3 <= -uc1-uc2 + 1.0/6.0*(uc3k(0)*2.0 + 4.0*uc3k(1) + 2.0*uc3k(2) + uc3k(3));


                    i1_ref <= ((+u1-u2-u3) - (+i1_ref-i2_ref-i3_ref) * r - (+uc1_ref-uc2_ref-uc3_ref))/2.0 * l + i1_ref;
                    i2_ref <= ((-u1+u2-u3) - (-i1_ref+i2_ref-i3_ref) * r - (-uc1_ref+uc2_ref-uc3_ref))/2.0 * l + i2_ref;
                    i3_ref <= ((-u1-u2+u3) - (-i1_ref-i2_ref+i3_ref) * r - (-uc1_ref-uc2_ref+uc3_ref))/2.0 * l - i1_ref - i2_ref;
                    -- uc1   <= ((+i1-i2-i3 ) ) * c/2.0 + uc1;
                    -- uc2   <= ((-i1+i2-i3 ) ) * c/2.0 + uc2;
                    -- uc3   <= ((-i1-i2+i3 ) ) * c/2.0 + uc3;

                WHEN 0 => 
                    

                    uc1_ref <= ((+i1_ref-i2_ref-i3_ref ) )/2.0 * c + uc1_ref;
                    uc2_ref <= ((-i1_ref+i2_ref-i3_ref ) )/2.0 * c + uc2_ref;
                    uc3_ref <= ((-i1_ref-i2_ref+i3_ref ) )/2.0 * c  -uc1_ref - uc2_ref;


                    sequencer <= sequencer + 1;

                    -- write_to(file_handler,(simtime, uc1, uc2, uc3, i1, i2, i3));
                WHEN others => -- do nothing
            end CASE;

            CASE sequencer is
                WHEN 0 =>
                    if simulation_counter < 2 then
                        phase <= (phase + 2.0*math_pi/250.0) mod (2.0*math_pi);
                    end if;
                WHEN 1 =>
                    -- u1 <= sin((phase+2.0*math_pi/3.0) mod (2.0*math_pi));
                    -- u2 <= sin(phase);
                    -- u3 <= -u1-u2;
                    simtime <= simtime + timestep;
                    write_to(file_handler,(simtime, uc1_ref, uc2_ref, uc3_ref));

                    u1 <= -0.95;
                    u2 <= 0.23;
                    u3 <= -u1-u2;

                    usum_ref <= uc1_ref+uc2_ref+uc3_ref;
                WHEN others => -- do nothing
            end CASE;

            if sequencer = 1 then
                sequencer <= 0;
                -- check_equal(i1,i1_ref, "i1", 1.0e-6);
                -- check_equal(i2,i2_ref, "i2", 1.0e-6);
                -- check_equal(i3,i3_ref, "i3", 1.0e-6);
                --
                -- check_equal(uc1,uc1_ref, "uc1", 1.0e-6);
                -- check_equal(uc2,uc2_ref, "uc2", 1.0e-6);
                -- check_equal(uc3,uc3_ref, "uc3", 1.0e-6);
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
