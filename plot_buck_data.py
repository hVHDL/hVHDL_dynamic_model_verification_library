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

LTC.create_netlist(path_to_this_file + '/ltspice_circuits/buck_converter/synch_buck_w_input_filter.asc')
netlist = SpiceEditor(path_to_this_file + '/ltspice_circuits/buck_converter/synch_buck_w_input_filter.net')

LTC.run(netlist)
LTC.wait_completion()

d = RawRead(path_to_this_file + '/vunit_out/synch_buck_w_input_filter_1.raw')

simulation_time   = []
inductor_current  = []
capacitor_voltage = []

input_current  = []
input_voltage = []

synth_simulation_time = []
synth_inductor_current  = []
synth_capacitor_voltage = []

synth_L3_current  = []
synth_C3_voltage = []

with open('./vunit_out/buck_with_input_and_output_filters.dat') as f:
    for line in f.readlines():
        line_with_ends_removed       = line.strip()
        line_with_separated_contents = line.strip().strip()
        line_with_separated_contents = line_with_ends_removed.split()
        simulation_time.append(float(line_with_separated_contents[0]))
        inductor_current.append(float(line_with_separated_contents[5]))
        capacitor_voltage.append(float(line_with_separated_contents[6]))
        input_current.append(float(line_with_separated_contents[3]))
        input_voltage.append(float(line_with_separated_contents[4]))

with open('./vunit_out/filtered_buck.dat') as f:
    for line in f.readlines():
        line_with_ends_removed       = line.strip()
        line_with_separated_contents = line.strip().strip()
        line_with_separated_contents = line_with_ends_removed.split()
        synth_simulation_time.append(float(line_with_separated_contents[0]))
        synth_inductor_current.append(float(line_with_separated_contents[1]))
        synth_capacitor_voltage.append(float(line_with_separated_contents[2]))
        synth_L3_current.append(float(line_with_separated_contents[5]))
        synth_C3_voltage.append(float(line_with_separated_contents[6]))

pyplot.subplot(2, 2, 1)
pyplot.plot(simulation_time, inductor_current)
pyplot.plot(synth_simulation_time, synth_inductor_current)
pyplot.plot(d.get_trace("time").get_time_axis(), d.get_trace("I(L1)"))
pyplot.ylabel('current(A)')
pyplot.legend(['current from VHDL', 'current from fixed point VHDL', 'current from LTSpice'])

pyplot.subplot(2, 2, 3)
pyplot.plot(simulation_time, capacitor_voltage)
pyplot.plot(synth_simulation_time, synth_capacitor_voltage)
pyplot.plot(d.get_trace("time").get_time_axis(), d.get_trace("V(output_voltage)"))
pyplot.legend(['voltage from VHDL', 'voltage from fixed point VHDL', 'voltage from LTSpice'])

pyplot.subplot(2, 2, 2)
pyplot.plot(simulation_time, input_current)
pyplot.plot(synth_simulation_time, synth_L3_current)
pyplot.plot(d.get_trace("time").get_time_axis(), d.get_trace("I(L3)"))
pyplot.legend(['current from VHDL', 'current from fixed point VHDL', 'current from LTSpice'])

pyplot.subplot(2, 2, 4)
pyplot.plot(simulation_time, input_voltage)
pyplot.plot(synth_simulation_time, synth_C3_voltage)
pyplot.plot(d.get_trace("time").get_time_axis(), d.get_trace("v(input_voltage)"))
pyplot.legend(['voltage from VHDL', 'voltage from fixed point VHDL', 'voltage from LTSpice'])

pyplot.xlabel('time (s)')
pyplot.ylabel('voltage(V)')

pyplot.show()
