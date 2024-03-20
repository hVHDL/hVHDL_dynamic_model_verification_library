#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

#this is obsolete and will be rewritten
power_supply_lib = VU.add_library("power_supply_lib")
power_supply_lib.add_source_files(ROOT / "source/hVHDL_fixed_point/multiplier/configuration/multiply_with_1_input_and_output_registers_pkg.vhd")
power_supply_lib.add_source_files(ROOT / "source/hVHDL_fixed_point/multiplier/multiplier_base_types_22bit_pkg.vhd") 
power_supply_lib.add_source_files(ROOT / "source/hVHDL_fixed_point/multiplier/multiplier_pkg.vhd") 
power_supply_lib.add_source_files(ROOT / "state_variable/state_variable_pkg.vhd")
power_supply_lib.add_source_files(ROOT / "lcr_filter_model/to_be_removed_lcr_filter_pkg.vhd")
power_supply_lib.add_source_files(ROOT / "inverter_model/inverter_model_pkg.vhd")
power_supply_lib.add_source_files(ROOT / "power_supply_model/power_supply_simulation_model_pkg.vhd")
power_supply_lib.add_source_files(ROOT / "power_supply_model/psu_inverter_simulation_models_pkg.vhd")
power_supply_lib.add_source_files(ROOT / "source/hVHDL_fixed_point/pi_controller/pi_controller_pkg.vhd") 

power_supply_lib.add_source_files(ROOT / "testbenches/inverter_model_simulation/tb_inverter_model.vhd")
power_supply_lib.add_source_files(ROOT / "testbenches/power_supply_model_simulation/tb_power_supply_model.vhd")

motor_control_library = VU.add_library("motor_control_library")
motor_control_library.add_source_files(ROOT / "source/hVHDL_fixed_point/multiplier/configuration/multiply_with_1_input_and_output_registers_pkg.vhd")
motor_control_library.add_source_files(ROOT / "source/hVHDL_fixed_point/multiplier/multiplier_base_types_22bit_pkg.vhd") 
motor_control_library.add_source_files(ROOT / "source/hVHDL_fixed_point/multiplier/multiplier_pkg.vhd") 
motor_control_library.add_source_files(ROOT / "source/hVHDL_fixed_point/sincos/sincos_pkg.vhd") 
motor_control_library.add_source_files(ROOT / "source/hVHDL_fixed_point/pi_controller/pi_controller_pkg.vhd") 
motor_control_library.add_source_files(ROOT / "source/hVHDL_fixed_point/coordinate_transforms/abc_to_ab_transform/abc_to_ab_transform_pkg.vhd") 
motor_control_library.add_source_files(ROOT / "source/hVHDL_fixed_point/coordinate_transforms/abc_to_ab_transform/ab_to_abc_transform_pkg.vhd") 
motor_control_library.add_source_files(ROOT / "source/hVHDL_fixed_point/coordinate_transforms/ab_to_dq_transform/dq_to_ab_transform_pkg.vhd") 
motor_control_library.add_source_files(ROOT / "source/hVHDL_fixed_point/coordinate_transforms/ab_to_dq_transform/ab_to_dq_transform_pkg.vhd") 

motor_control_library.add_source_files(ROOT / "state_variable/state_variable_pkg.vhd")
motor_control_library.add_source_files(ROOT / "ac_motor_models/pmsm_electrical_model_pkg.vhd")
motor_control_library.add_source_files(ROOT / "ac_motor_models/pmsm_mechanical_model_pkg.vhd")
motor_control_library.add_source_files(ROOT / "ac_motor_models/permanent_magnet_motor_model_pkg.vhd")
motor_control_library.add_source_files(ROOT / "ac_motor_models/field_oriented_motor_control/field_oriented_motor_control_pkg.vhd")
motor_control_library.add_source_files(ROOT / "testbenches/simulate_permanent_magnet_synchronous_machine/tb_permanent_magnet_synchronous_machine_model.vhd")
motor_control_library.add_source_files(ROOT / "testbenches/field_oriented_motor_control_simulation/tb_field_oriented_motor_control.vhd")

math_library_22x22 = VU.add_library("math_library_22x22")
math_library_22x22.add_source_files(ROOT / "source/hVHDL_fixed_point/multiplier/configuration/multiply_with_1_input_and_output_registers_pkg.vhd")
math_library_22x22.add_source_files(ROOT / "simulator_utilities/write_pkg.vhd")
math_library_22x22.add_source_files(ROOT / "source/hVHDL_fixed_point/multiplier/multiplier_base_types_22bit_pkg.vhd")
math_library_22x22.add_source_files(ROOT / "source/hVHDL_fixed_point/multiplier/multiplier_pkg.vhd")
math_library_22x22.add_source_files(ROOT / "state_variable/state_variable_pkg.vhd")
math_library_22x22.add_source_files(ROOT / "lcr_filter_model/lcr_filter_model_pkg.vhd")

math_library_22x22.add_source_files(ROOT / "source/hVHDL_fixed_point/real_to_fixed/real_to_fixed_pkg.vhd")
#22x22 testbenches
math_library_22x22.add_source_files(ROOT / "testbenches/converter_models/lcr_filter_tb.vhd")

math_library_26x26 = VU.add_library("math_library_26x26")
math_library_26x26.add_source_files(ROOT / "source/hVHDL_fixed_point/multiplier/configuration/multiply_with_1_input_and_output_registers_pkg.vhd")
math_library_26x26.add_source_files(ROOT / "source/hVHDL_fixed_point/real_to_fixed/real_to_fixed_pkg.vhd")
math_library_26x26.add_source_files( ROOT / "simulator_utilities/write_pkg.vhd")
math_library_26x26.add_source_files(ROOT / "source/hVHDL_fixed_point/multiplier/multiplier_base_types_26bit_pkg.vhd")
math_library_26x26.add_source_files(ROOT / "source/hVHDL_fixed_point/multiplier/multiplier_pkg.vhd")
math_library_26x26.add_source_files(ROOT / "state_variable/state_variable_pkg.vhd")
math_library_26x26.add_source_files(ROOT / "lcr_filter_model/lcr_filter_model_pkg.vhd")
math_library_26x26.add_source_files(ROOT / "half_bridge_model/half_bridge_pkg.vhd")
math_library_26x26.add_source_files(ROOT / "buck_simulation_model/filtered_buck_model_pkg.vhd")

#26x26 testbenches

math_library_26x26.add_source_files(ROOT / "testbenches/buck/buck_with_input_and_output_filters_tb.vhd")
math_library_26x26.add_source_files(ROOT / "testbenches/converter_models/cascaded_lcr_filters_tb.vhd")
math_library_26x26.add_source_files(ROOT / "testbenches/buck/buck_converter_tb.vhd")
math_library_26x26.add_source_files(ROOT / "testbenches/buck/filtered_buck_synthesizable_tb.vhd")

#floating point testbenches

mcu = VU.add_library("mcu")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_floating_point/float_type_definitions/float_word_length_24_bit_pkg.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_floating_point/float_type_definitions/float_type_definitions_pkg.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_floating_point/float_arithmetic_operations/*.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_floating_point/normalizer/normalizer_configuration/normalizer_with_1_stage_pipe_pkg.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_floating_point/denormalizer/denormalizer_configuration/denormalizer_with_1_stage_pipe_pkg.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_floating_point/normalizer/*.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_floating_point/denormalizer/*.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_floating_point/float_to_real_conversions" / "*.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_floating_point/float_adder/*.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_floating_point/float_multiplier/*.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_floating_point/float_alu/*.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_floating_point/float_first_order_filter/*.vhd")

mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_fixed_point/real_to_fixed/real_to_fixed_pkg.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_fixed_point/multiplier/multiplier_base_types_20bit_pkg.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_fixed_point/multiplier/configuration/multiply_with_1_input_and_output_registers_pkg.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_fixed_point/multiplier/multiplier_base_types_20bit_pkg.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_fixed_point/multiplier/multiplier_pkg.vhd")

mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/processor_configuration/float_processor_ram_width_pkg.vhd")

mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_memory_library/multi_port_ram/multi_port_ram_pkg.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_memory_library/multi_port_ram/ram_read_x2_write_x1.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_memory_library/multi_port_ram/arch_sim_read_x2_write_x1.vhd")

mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_memory_library/multi_port_ram/ram_read_x4_write_x1.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/source/hVHDL_memory_library/multi_port_ram/arch_sim_read_x4_write_x1.vhd")

mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/processor_configuration/processor_configuration_pkg.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/vhdl_assembler/microinstruction_pkg.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/vhdl_assembler/float_assembler_pkg.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/simple_processor/test_programs_pkg.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/processor_configuration/float_pipeline_pkg.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/simple_processor/simple_processor_pkg.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/memory_processor/memory_processing_pkg.vhd")
mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/memory_processor/memory_processor.vhd")

mcu.add_source_files(ROOT / "source/hVHDL_microprogram_processor/simple_processor/float_example_program_pkg.vhd")

mcu.add_source_files(ROOT / "testbenches_mcu_models/lc_filter/lcr_simulation_tb.vhd")
mcu.add_source_files(ROOT / "testbenches_mcu_models/lc_filter/lcr_simulation_rk4_tb.vhd")
mcu.add_source_files(ROOT / "testbenches_mcu_models/3ph_lc/lcr_3ph_tb.vhd")

mcu.add_source_files(ROOT / "simulator_utilities/write_pkg.vhd")

VU.main()
