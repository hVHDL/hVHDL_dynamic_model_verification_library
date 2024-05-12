import pandas as pd
import matplotlib.pyplot as plt

#make this file root for relative paths
import os
path_to_this_file = os.path.dirname(os.path.realpath(__file__))
fig1, (axT, axB) = plt.subplots(2,1,sharex=True,constrained_layout=True)

vhdl_data = pd.read_csv(path_to_this_file + '/../vunit_out/lcr_simulation_mcu_tb.dat', delim_whitespace=True)
vhdl_data.plot(ax=axT, x="time", y="volt", label="voltage")
vhdl_data.plot(ax=axT, x="time", y="vref", label="ref voltage")
vhdl_data.plot(ax=axB, x="time", y="curr", label="current")
vhdl_data.plot(ax=axB, x="time", y="iref", label="ref current")

plt.show()
plt.close('all')
