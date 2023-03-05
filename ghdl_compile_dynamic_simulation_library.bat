echo off
FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
SET source=%project_root%/

rem call %source%/hVHDL_math_library/ghdl_compile_math_library.bat

ghdl -a --ieee=synopsys --std=08 %source%/simulator_utilities/write_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_math_library/multiplier/multiplier_base_types_18bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_math_library/multiplier/multiplier_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_math_library/sincos/sincos_pkg.vhd


ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_math_library/division/division_internal_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_math_library/division/division_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_math_library/first_order_filter/first_order_filter_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_math_library/pi_controller/pi_controller_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_math_library/coordinate_transforms/abc_to_ab_transform/abc_to_ab_transform_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_math_library/coordinate_transforms/abc_to_ab_transform/ab_to_abc_transform_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_math_library/coordinate_transforms/ab_to_dq_transform/dq_to_ab_transform_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/hVHDL_math_library/coordinate_transforms/ab_to_dq_transform/ab_to_dq_transform_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/state_variable/state_variable_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/lcr_filter_model/lcr_filter_model_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/inverter_model/inverter_model_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/power_supply_model/psu_inverter_simulation_models_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/power_supply_model/power_supply_simulation_model_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/ac_motor_models/pmsm_electrical_model_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/ac_motor_models/pmsm_mechanical_model_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/ac_motor_models/permanent_magnet_motor_model_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/ac_motor_models/field_oriented_motor_control/field_oriented_motor_control_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/simulator_engine/simulation_configuration_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/simulator_engine/simulation_pkg.vhd
