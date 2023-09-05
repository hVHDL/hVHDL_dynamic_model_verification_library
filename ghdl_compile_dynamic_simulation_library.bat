echo off
SET source=%1

call %source%/hVHDL_math_library/ghdl_compile_math_library.bat %source%/hVHDL_math_library

ghdl -a --ieee=synopsys --std=08 %source%/simulator_utilities/write_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/state_variable/state_variable_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/half_bridge_model/half_bridge_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/lcr_filter_model/lcr_filter_model_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/buck_simulation_model/filtered_buck_model_pkg.vhd


ghdl -a --ieee=synopsys --std=08 %source%/inverter_model/inverter_model_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/power_supply_model/psu_inverter_simulation_models_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/power_supply_model/power_supply_simulation_model_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/ac_motor_models/pmsm_electrical_model_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/ac_motor_models/pmsm_mechanical_model_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/ac_motor_models/permanent_magnet_motor_model_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/ac_motor_models/field_oriented_motor_control/field_oriented_motor_control_pkg.vhd
