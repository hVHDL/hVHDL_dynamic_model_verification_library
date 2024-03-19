echo off

if "%1"=="" (
    set src=./
) else (
    set src=%1
)

call source/hVHDL_fixed_point/ghdl_compile_math_library.bat source/hVHDL_fixed_point

ghdl -a --ieee=synopsys --std=08 %src%/simulator_utilities/write_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %src%/half_bridge_model/half_bridge_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %src%/state_variable/state_variable_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %src%/lcr_filter_model/lcr_filter_model_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %src%/buck_simulation_model/filtered_buck_model_pkg.vhd


ghdl -a --ieee=synopsys --std=08 %src%/inverter_model/inverter_model_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %src%/power_supply_model/psu_inverter_simulation_models_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %src%/power_supply_model/power_supply_simulation_model_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %src%/ac_motor_models/pmsm_electrical_model_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %src%/ac_motor_models/pmsm_mechanical_model_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %src%/ac_motor_models/permanent_magnet_motor_model_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %src%/ac_motor_models/field_oriented_motor_control/field_oriented_motor_control_pkg.vhd
