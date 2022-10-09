#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

mathlib = VU.add_library("math_library")
mathlib.add_source_files(ROOT / "hVHDL_math_library/multiplier/multiplier_base_types_22bit_pkg.vhd") 
mathlib.add_source_files(ROOT / "hVHDL_math_library/multiplier/multiplier_pkg.vhd") 
mathlib.add_source_files(ROOT / "hVHDL_math_library/sincos/sincos_pkg.vhd") 
mathlib.add_source_files(ROOT / "hVHDL_math_library/pi_controller/pi_controller_pkg.vhd") 
mathlib.add_source_files(ROOT / "hVHDL_math_library/coordinate_transforms/abc_to_ab_transform/abc_to_ab_transform_pkg.vhd") 
mathlib.add_source_files(ROOT / "hVHDL_math_library/coordinate_transforms/abc_to_ab_transform/ab_to_abc_transform_pkg.vhd") 
mathlib.add_source_files(ROOT / "hVHDL_math_library/coordinate_transforms/ab_to_dq_transform/dq_to_ab_transform_pkg.vhd") 
mathlib.add_source_files(ROOT / "hVHDL_math_library/coordinate_transforms/ab_to_dq_transform/ab_to_dq_transform_pkg.vhd") 

mathlib.add_source_files(ROOT / "hVHDL_math_library/multiplier/simulation/tb_multiplier.vhd") 
mathlib.add_source_files(ROOT / "hVHDL_math_library/coordinate_transforms/abc_to_ab_transform/abc_to_ab_transform_simulation/tb_abc_to_ab_transform.vhd") 
mathlib.add_source_files(ROOT / "hVHDL_math_library/coordinate_transforms/ab_to_dq_transform/ab_to_dq_simulation/tb_ab_to_dq_transforms.vhd")

mathlib.add_source_files(ROOT / "state_variable/state_variable_pkg.vhd")
mathlib.add_source_files(ROOT / "ac_motor_models/pmsm_electrical_model_pkg.vhd")
mathlib.add_source_files(ROOT / "ac_motor_models/pmsm_mechanical_model_pkg.vhd")
mathlib.add_source_files(ROOT / "ac_motor_models/permanent_magnet_motor_model_pkg.vhd")
mathlib.add_source_files(ROOT / "ac_motor_models/field_oriented_motor_control/field_oriented_motor_control_pkg.vhd")

mathlib.add_source_files(ROOT / "lcr_filter_model/lcr_filter_model_pkg.vhd")
mathlib.add_source_files(ROOT / "lcr_filter_model/lcr_filter_simulation/tb_lcr_filter.vhd")

mathlib.add_source_files(ROOT / "hVHDL_math_library/coordinate_transforms/ab_to_dq_transform/ab_to_dq_transform_pkg.vhd") 
mathlib.add_source_files(ROOT / "ac_motor_models/simulate_permanent_magnet_synchronous_machine/tb_permanent_magnet_synchronous_machine_model.vhd")
mathlib.add_source_files(ROOT / "ac_motor_models/field_oriented_motor_control/field_oriented_motor_control_simulation/tb_field_oriented_motor_control.vhd")

mathlib.add_source_files(ROOT / "inverter_model/inverter_model_pkg.vhd")
mathlib.add_source_files(ROOT / "inverter_model/inverter_model_simulation/tb_inverter_model.vhd")

mathlib.add_source_files(ROOT / "power_supply_model/power_supply_simulation_model_pkg.vhd")
mathlib.add_source_files(ROOT / "power_supply_model/psu_inverter_simulation_models_pkg.vhd")
mathlib.add_source_files(ROOT / "power_supply_model/power_supply_model_simulation/tb_power_supply_model.vhd")

mathlib.add_source_files(ROOT / "state_variable/simulation/tb_state_variable.vhd")

simulation = VU.add_library("real_simulation")
# simulation.add_source_files(ROOT / "simulation/testi" / "*.vhd")
# simulation.add_source_files(ROOT / "simulation" / "*.vhd")
simulation.add_source_files(ROOT / "hVHDL_math_library/multiplier/multiplier_base_types_22bit_pkg.vhd") 
simulation.add_source_files(ROOT / "hVHDL_math_library/multiplier/multiplier_pkg.vhd") 


VU.main()
