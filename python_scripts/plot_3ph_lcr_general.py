from PyQSPICE import clsQSPICE as pqs

import pandas as pd
import matplotlib.pyplot as plt

#make this file root for relative paths
import os
path_to_this_file = os.path.dirname(os.path.realpath(__file__))

#change directory to the lc filter directory
pqs.chdir(path_to_this_file + '/../testbenches_mcu_models/3ph_lc')

run = pqs('3ph_lc_general.qsch')

run.qsch2cir()
run.cir2qraw()

# no idea what this does
run.setNline(4999)

# run qspice simulation and load voltages and currents
df = run.LoadQRAW(["V(uc1)", "V(uc2)","V(uc3)","I(L1)","I(L2)","I(L3)"])

# load vhdl simulation data

fig1, (axT, axB) = plt.subplots(2,1,sharex=True,constrained_layout=True)

# df.plot(ax=axT, x="Time",  y="V(uc1)", label="V(uc1)")
# df.plot(ax=axT, x="Time",  y="V(uc2)", label="V(uc2)")
df.plot(ax=axT, x="Time",  y="V(uc3)", label="V(uc3)")
# df.plot(ax=axB, x="Time",  y="I(L1)", label="I(L1)")
# df.plot(ax=axB, x="Time",  y="I(L2)", label="I(L2)")
df.plot(ax=axB, x="Time",  y="I(L3)", label="I(L3)")

vhdl_data = pd.read_csv(path_to_this_file + '/../vunit_out/lcr_3ph_general_tb.dat', delim_whitespace=True)

# vhdl_data.plot(ax=axT, x="time", y="rkv1", label="rk4 uc1")
# vhdl_data.plot(ax=axT, x="time", y="rkv2", label="rk4 uc2")
# vhdl_data.plot(ax=axT, x="time", y="rkv3", label="rk4 uc3")

vhdl_data.plot(ax=axT, x="time", y="euv1", label="euler uc1")
# vhdl_data.plot(ax=axT, x="time", y="euv2", label="euler uc2")
# vhdl_data.plot(ax=axT, x="time", y="euv3", label="euler uc3")

# ((V(u1)-Uc1-i1*r1)*L2*L3 +  (U2-Uc2-i2*r2)*L1*L3 + (U3-Uc3-i3*r3)*L1*L2) / (L1*L2+L1*L3+L2*L3)

# ((V(u1)-V(uc1)-I(L1)*0.1)*40e-6*30e-6+(V(u2)-V(uc2)-I(L2)*0.1)*40e-6*30e-6+(V(u3)-V(uc3)-I(L3)*0.1)*40e-6*40e-6)/(40e-6*40e-6+40e-6*30e-6+40e-6*30e-6)

# ((V(u1)-V(uc1,n)-I(L1)*0.1)*40*30+(V(u2)-V(uc2,n)-I(L2)*0.1)*40*30+(V(u3)-V(uc3,n)-I(L3)*0.1)*40*40)/(40*40+40*30+40*30)

# vhdl_data.plot(ax=axB, x="time", y="rki1", label="rk4 i1")
# vhdl_data.plot(ax=axB, x="time", y="rki2", label="rk4 i2")
# vhdl_data.plot(ax=axB, x="time", y="rki3", label="rk4 i3")

vhdl_data.plot(ax=axB, x="time", y="eui1", label="euler i1")
# vhdl_data.plot(ax=axB, x="time", y="eui2", label="euler i2")
# vhdl_data.plot(ax=axB, x="time", y="eui3", label="euler i3")

plt.show()
plt.close('all')
