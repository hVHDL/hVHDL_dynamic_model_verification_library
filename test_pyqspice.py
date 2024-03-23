from PyQSPICE import clsQSPICE as pqs

import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt

#make this file root for relative paths
import os
path_to_this_file = os.path.dirname(os.path.realpath(__file__))

#change directory to the lc filter directory
pqs.chdir(path_to_this_file + './testbenches_mcu_models/3ph_lc')

run = pqs('3ph_lc.qsch')

run.qsch2cir()
run.cir2qraw()

run.setNline(4999)

df = run.LoadQRAW(["V(uc1)", "V(uc2)","V(uc3)","I(L1)","I(L2)","I(L3)"])

vhdl_data = pd.read_csv(path_to_this_file + '/vunit_out/lcr_3ph_tb.dat', delim_whitespace=True)

fig1, (axT, axB) = plt.subplots(2,1,sharex=True,constrained_layout=True)

df.plot(ax=axT, x="Time",  y="V(uc1)", label="V(uc1)")
df.plot(ax=axT, x="Time",  y="V(uc2)", label="V(uc2)")
df.plot(ax=axT, x="Time",  y="V(uc3)", label="V(uc3)")
df.plot(ax=axB, x="Time",  y="I(L1)", label="I(L1)")
df.plot(ax=axB, x="Time",  y="I(L2)", label="I(L2)")
df.plot(ax=axB, x="Time",  y="I(L3)", label="I(L3)")

vhdl_data.plot(ax=axT, x="time", y="rkv1", label="rk4 uc1")
vhdl_data.plot(ax=axT, x="time", y="rkv2", label="rk4 uc2")
vhdl_data.plot(ax=axT, x="time", y="rkv3", label="rk4 uc3")

vhdl_data.plot(ax=axT, x="time", y="euv1", label="euler uc1")
vhdl_data.plot(ax=axT, x="time", y="euv2", label="euler uc2")
vhdl_data.plot(ax=axT, x="time", y="euv3", label="euler uc3")

vhdl_data.plot(ax=axB, x="time", y="rki1", label="rk4 i1")
vhdl_data.plot(ax=axB, x="time", y="rki2", label="rk4 i2")
vhdl_data.plot(ax=axB, x="time", y="rki3", label="rk4 i3")

vhdl_data.plot(ax=axB, x="time", y="eui1", label="euler i1")
vhdl_data.plot(ax=axB, x="time", y="eui2", label="euler i2")
vhdl_data.plot(ax=axB, x="time", y="eui3", label="euler i3")

plt.show()
plt.close('all')
