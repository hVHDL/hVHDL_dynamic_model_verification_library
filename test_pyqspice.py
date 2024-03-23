from PyQSPICE import clsQSPICE as pqs

import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt

#make this file root for relative paths
import os
path_to_this_file = os.path.dirname(os.path.realpath(__file__))

#change directory to the lc filter directory
pqs.chdir(path_to_this_file + './testbenches_mcu_models/lc_filter')

run = pqs('lcr_qspice.qsch')

run.qsch2cir()
run.cir2qraw()

run.setNline(4999)

df = run.LoadQRAW(["V(vout)", "I(L1)"])

fig1, (axT, axB) = plt.subplots(2,1,sharex=True,constrained_layout=True)

df.plot(ax=axT, x="Time",  y="V(vout)", label="V(vout)")
df.plot(ax=axB, x="Time",  y="I(L1)", label="I(L1)")

plt.show()
plt.close('all')
