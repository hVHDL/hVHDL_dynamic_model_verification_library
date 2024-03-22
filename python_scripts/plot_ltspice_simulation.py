import pandas as pd
import numpy as np
from matplotlib import pyplot

from PyLTSpice import SimRunner, SpiceEditor, LTspice
from PyLTSpice import RawRead
import os

# LTSpice needs to be installed in one of the locations specified in 
# https://pyltspice.readthedocs.io/en/latest/_modules/PyLTSpice/sim/ltspice_simulator.html#LTspice

# this was seen in https://github.com/nunobrum/PyLTSpice/blob/master/examples/sim_runner_example.py
# example, but I do not know if it actually does something
# simulator = r"C:\Program Files\LTC\LTspice\LTSpice.exe"

path_to_this_file = os.path.dirname(os.path.realpath(__file__))
LTC = SimRunner(output_folder='./vunit_out', simulator=LTspice)

LTC.create_netlist(path_to_this_file + '/../testbenches_mcu_models/3ph_lc/3ph_lc.asc')
netlist = SpiceEditor(path_to_this_file + '/../testbenches_mcu_models/3ph_lc/3ph_lc.net')

LTC.run(netlist)
LTC.wait_completion()


raw = RawRead(path_to_this_file + '/../vunit_out/3ph_lc_1.raw')   # Read the RAW file contents from disk
vhdl_data = pd.read_csv(path_to_this_file + '/../vunit_out/lcr_3ph_tb.dat', delim_whitespace=True)

print(raw.get_trace_names())            # Get and print a list of all the traces

# pyplot.plot(raw.get_trace("time").get_time_axis(), raw.get_trace("v(uc1)"))
# pyplot.plot(raw.get_trace("time").get_time_axis(), raw.get_trace("v(uc2)"))
# pyplot.plot(raw.get_trace("time").get_time_axis(), raw.get_trace("v(uc3)"))

# pyplot.plot(vhdl_data[vhdl_data.columns[0]], vhdl_data[vhdl_data.columns[1]])
# pyplot.plot(vhdl_data[vhdl_data.columns[0]], vhdl_data[vhdl_data.columns[2]])
# pyplot.plot(vhdl_data[vhdl_data.columns[0]], vhdl_data[vhdl_data.columns[3]])
# #
pyplot.plot(vhdl_data[vhdl_data.columns[0]], vhdl_data[vhdl_data.columns[4]])
pyplot.plot(vhdl_data[vhdl_data.columns[0]], vhdl_data[vhdl_data.columns[5]])
pyplot.plot(vhdl_data[vhdl_data.columns[0]], vhdl_data[vhdl_data.columns[6]])
# pyplot.plot(raw.get_trace("time").get_time_axis(), raw.get_trace("v(uc1)"))
# pyplot.plot(raw.get_trace("time").get_time_axis(), raw.get_trace("v(uc1)"))
# pyplot.plot(raw.get_trace("time").get_time_axis(), raw.get_trace("v(uc2)"))
# pyplot.plot(raw.get_trace("time").get_time_axis(), raw.get_trace("v(uc3)"))


pyplot.grid()
pyplot.show()                              # Show matplotlib's interactive window with the plots
