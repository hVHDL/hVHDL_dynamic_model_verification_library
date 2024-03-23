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

fig1, (axT, axB) = plt.subplots(2,1,sharex=True,constrained_layout=True)

df.plot(ax=axT, x="Time",  y="V(uc1)", label="V(uc1)")
df.plot(ax=axT, x="Time",  y="V(uc2)", label="V(uc2)")
df.plot(ax=axT, x="Time",  y="V(uc3)", label="V(uc3)")
df.plot(ax=axB, x="Time",  y="I(L1)", label="I(L1)")
df.plot(ax=axB, x="Time",  y="I(L2)", label="I(L2)")
df.plot(ax=axB, x="Time",  y="I(L3)", label="I(L3)")

plt.show()
plt.close('all')
