rem simulate lcr_model.vhd
echo off

echo %project_root%
FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
set source= %project_root%/source

ghdl -a --ieee=synopsys --work=math_library %source%/math_library/multiplier/multiplier_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/state_variable/state_variable_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/lcr_filter_model/lcr_filter_model_pkg.vhd
ghdl -a --ieee=synopsys tb_lcr_filter.vhd
ghdl -e --ieee=synopsys tb_lcr_filter
ghdl -r --ieee=synopsys tb_lcr_filter --vcd=tb_lcr_filter.vcd 

IF %1 EQU 1 start "" gtkwave tb_lcr_filter.vcd
