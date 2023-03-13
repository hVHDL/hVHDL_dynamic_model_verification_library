#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

#this is obsolete and will be rewritten
power_supply_lib = VU.add_library("power_supply_lib")
power_supply_lib.add_source_files(ROOT / "hVHDL_math_library/multiplier/multiplier_base_types_22bit_pkg.vhd") 
power_supply_lib.add_source_files(ROOT / "hVHDL_math_library/multiplier/multiplier_pkg.vhd") 
power_supply_lib.add_source_files(ROOT / "state_variable/state_variable_pkg.vhd")
power_supply_lib.add_source_files(ROOT / "lcr_filter_model/to_be_removed_lcr_filter_pkg.vhd")
power_supply_lib.add_source_files(ROOT / "inverter_model/inverter_model_pkg.vhd")
power_supply_lib.add_source_files(ROOT / "power_supply_model/power_supply_simulation_model_pkg.vhd")
power_supply_lib.add_source_files(ROOT / "power_supply_model/psu_inverter_simulation_models_pkg.vhd")
power_supply_lib.add_source_files(ROOT / "hVHDL_math_library/pi_controller/pi_controller_pkg.vhd") 

power_supply_lib.add_source_files(ROOT / "testbenches/inverter_model_simulation/tb_inverter_model.vhd")
power_supply_lib.add_source_files(ROOT / "testbenches/power_supply_model_simulation/tb_power_supply_model.vhd")

motor_control_library = VU.add_library("motor_control_library")
motor_control_library.add_source_files(ROOT / "hVHDL_math_library/multiplier/multiplier_base_types_22bit_pkg.vhd") 
motor_control_library.add_source_files(ROOT / "hVHDL_math_library/multiplier/multiplier_pkg.vhd") 
motor_control_library.add_source_files(ROOT / "hVHDL_math_library/sincos/sincos_pkg.vhd") 
motor_control_library.add_source_files(ROOT / "hVHDL_math_library/pi_controller/pi_controller_pkg.vhd") 
motor_control_library.add_source_files(ROOT / "hVHDL_math_library/coordinate_transforms/abc_to_ab_transform/abc_to_ab_transform_pkg.vhd") 
motor_control_library.add_source_files(ROOT / "hVHDL_math_library/coordinate_transforms/abc_to_ab_transform/ab_to_abc_transform_pkg.vhd") 
motor_control_library.add_source_files(ROOT / "hVHDL_math_library/coordinate_transforms/ab_to_dq_transform/dq_to_ab_transform_pkg.vhd") 
motor_control_library.add_source_files(ROOT / "hVHDL_math_library/coordinate_transforms/ab_to_dq_transform/ab_to_dq_transform_pkg.vhd") 

motor_control_library.add_source_files(ROOT / "state_variable/state_variable_pkg.vhd")
motor_control_library.add_source_files(ROOT / "ac_motor_models/pmsm_electrical_model_pkg.vhd")
motor_control_library.add_source_files(ROOT / "ac_motor_models/pmsm_mechanical_model_pkg.vhd")
motor_control_library.add_source_files(ROOT / "ac_motor_models/permanent_magnet_motor_model_pkg.vhd")
motor_control_library.add_source_files(ROOT / "ac_motor_models/field_oriented_motor_control/field_oriented_motor_control_pkg.vhd")
motor_control_library.add_source_files(ROOT / "testbenches/simulate_permanent_magnet_synchronous_machine/tb_permanent_magnet_synchronous_machine_model.vhd")
motor_control_library.add_source_files(ROOT / "testbenches/field_oriented_motor_control_simulation/tb_field_oriented_motor_control.vhd")

math_library_22x22 = VU.add_library("math_library_22x22")
math_library_22x22.add_source_files(ROOT / "simulator_utilities/write_pkg.vhd")
math_library_22x22.add_source_files(ROOT / "hVHDL_math_library/multiplier/multiplier_base_types_22bit_pkg.vhd")
math_library_22x22.add_source_files(ROOT / "hVHDL_math_library/multiplier/multiplier_pkg.vhd")
math_library_22x22.add_source_files(ROOT / "state_variable/state_variable_pkg.vhd")
math_library_22x22.add_source_files(ROOT / "lcr_filter_model/lcr_filter_model_pkg.vhd")

math_library_22x22.add_source_files(ROOT / "hVHDL_math_library/real_to_fixed/real_to_fixed_pkg.vhd")
#22x22 testbenches
math_library_22x22.add_source_files(ROOT / "testbenches/converter_models/lcr_filter_tb.vhd")

math_library_26x26 = VU.add_library("math_library_26x26")
math_library_26x26.add_source_files(ROOT / "hVHDL_math_library/real_to_fixed/real_to_fixed_pkg.vhd")
math_library_26x26.add_source_files( ROOT / "simulator_utilities/write_pkg.vhd")
math_library_26x26.add_source_files(ROOT / "hVHDL_math_library/multiplier/multiplier_base_types_26bit_pkg.vhd")
math_library_26x26.add_source_files(ROOT / "hVHDL_math_library/multiplier/multiplier_pkg.vhd")
math_library_26x26.add_source_files(ROOT / "state_variable/state_variable_pkg.vhd")
math_library_26x26.add_source_files(ROOT / "lcr_filter_model/lcr_filter_model_pkg.vhd")
math_library_26x26.add_source_files(ROOT / "buck_simulation_model/filtered_buck_model_pkg.vhd")

#26x26 testbenches

math_library_26x26.add_source_files(ROOT / "testbenches/buck/buck_with_input_and_output_filters_tb.vhd")
math_library_26x26.add_source_files(ROOT / "testbenches/converter_models/cascaded_lcr_filters_tb.vhd")
math_library_26x26.add_source_files(ROOT / "testbenches/buck/buck_converter_tb.vhd")
math_library_26x26.add_source_files(ROOT / "testbenches/buck/filtered_buck_synthesizable_tb.vhd")

VU.main()
