rem simulate inverter_model.vhd
echo off

echo %project_root%
FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
SET source=%project_root%/source
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/multiplier/multiplier_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/first_order_filter/first_order_filter_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/state_variable/state_variable_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/lcr_filter_model/lcr_filter_model_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/pi_controller/pi_controller_pkg.vhd 
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/inverter_model/inverter_model_pkg.vhd

ghdl -a --ieee=synopsys tb_inverter_model.vhd
ghdl -e --ieee=synopsys tb_inverter_model
ghdl -r --ieee=synopsys tb_inverter_model --vcd=tb_inverter_model.vcd


IF %1 EQU 1 start "" gtkwave tb_inverter_model.vcd
