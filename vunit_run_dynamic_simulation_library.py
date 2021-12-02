#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()
VU = VUnit.from_argv(vhdl_standard="93")

mathlib = VU.add_library("math_library")
mathlib.add_source_files(ROOT / "../math_library/multiplier/multiplier_pkg.vhd") 
mathlib.add_source_files(ROOT / "../math_library/sincos/sincos_pkg.vhd") 
mathlib.add_source_files(ROOT / "../math_library/pi_controller/pi_controller_pkg.vhd") 
mathlib.add_source_files(ROOT / "../math_library/coordinate_transforms/abc_to_ab_transform/abc_to_ab_transform_pkg.vhd") 
mathlib.add_source_files(ROOT / "../math_library/coordinate_transforms/abc_to_ab_transform/ab_to_abc_transform_pkg.vhd") 
mathlib.add_source_files(ROOT / "../math_library/coordinate_transforms/ab_to_dq_transform/dq_to_ab_transform_pkg.vhd") 
mathlib.add_source_files(ROOT / "../math_library/coordinate_transforms/ab_to_dq_transform/ab_to_dq_transform_pkg.vhd") 

mathlib.add_source_files(ROOT / "../math_library/multiplier/simulation/tb_multiplier.vhd") 
mathlib.add_source_files(ROOT / "../math_library/coordinate_transforms/abc_to_ab_transform/abc_to_ab_transform_simulation/tb_abc_to_ab_transform.vhd") 
mathlib.add_source_files(ROOT / "../math_library/coordinate_transforms/ab_to_dq_transform/ab_to_dq_simulation/tb_ab_to_dq_transforms.vhd")

mathlib.add_source_files(ROOT / "state_variable/state_variable_pkg.vhd")
mathlib.add_source_files(ROOT / "ac_motor_models/pmsm_electrical_model_pkg.vhd")
mathlib.add_source_files(ROOT / "ac_motor_models/pmsm_mechanical_model_pkg.vhd")
mathlib.add_source_files(ROOT / "ac_motor_models/permanent_magnet_motor_model_pkg.vhd")
mathlib.add_source_files(ROOT / "ac_motor_models/field_oriented_motor_control/field_oriented_motor_control_pkg.vhd")

mathlib.add_source_files(ROOT / "../math_library/coordinate_transforms/ab_to_dq_transform/ab_to_dq_transform_pkg.vhd") 
mathlib.add_source_files(ROOT / "ac_motor_models/simulate_permanent_magnet_synchronous_machine/tb_permanent_magnet_synchronous_machine_model.vhd")
mathlib.add_source_files(ROOT / "ac_motor_models/field_oriented_motor_control/field_oriented_motor_control_simulation/tb_field_oriented_motor_control.vhd")

VU.main()
