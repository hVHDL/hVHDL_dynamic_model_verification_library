echo off
FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
SET source=%project_root%/../

call %source%/math_library/ghdl_compile_math_library.bat

ghdl -a --ieee=synopsys --work=math_library %source%/dynamic_simulation_library/state_variable/state_variable_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/dynamic_simulation_library/lcr_filter_model/lcr_filter_model_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/dynamic_simulation_library/inverter_model/inverter_model_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/dynamic_simulation_library/power_supply_model/psu_inverter_simulation_models_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/dynamic_simulation_library/power_supply_model/power_supply_simulation_model_pkg.vhd

ghdl -a --ieee=synopsys --work=math_library %source%/dynamic_simulation_library/ac_motor_models/pmsm_electrical_model_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/dynamic_simulation_library/ac_motor_models/pmsm_mechanical_model_pkg.vhd
