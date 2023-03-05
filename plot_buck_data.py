import numpy as np
from matplotlib import pyplot

from PyLTSpice.LTSpiceBatch import SimCommander
from PyLTSpice.LTSpice_RawRead import LTSpiceRawRead
import os
import ltspice
abs_path = os.path.dirname(os.path.realpath(__file__))
SimCommander.setLTspiceRunCommand(SimCommander,"c:/Programs/LTC/LTspiceXVII/XVIIx64.exe")

# currently needs to have the lcr_filter.asc run manually since the lcr.run does not work right for some reason
# lcr = SimCommander(abs_path + "./simulation/converter_models/lcr_filter.asc", timeout=8, verbose=False)
# lcr.run()
# lcr.wait_completion()

d = LTSpiceRawRead(abs_path + "./ltspice_circuits/buck_converter/synch_buck_w_input_filter.raw")

simulation_time   = []
inductor_current  = []
capacitor_voltage = []

input_current  = []
input_voltage = []

synth_simulation_time = []
synth_inductor_current  = []
synth_capacitor_voltage = []

with open('buck_with_input_and_output_filters.dat') as f:
    for line in f.readlines():
        line_with_ends_removed       = line.strip()
        line_with_separated_contents = line.strip().strip()
        line_with_separated_contents = line_with_ends_removed.split()
        simulation_time.append(float(line_with_separated_contents[0]))
        inductor_current.append(float(line_with_separated_contents[5]))
        capacitor_voltage.append(float(line_with_separated_contents[6]))
        input_current.append(float(line_with_separated_contents[3]))
        input_voltage.append(float(line_with_separated_contents[4]))

with open('filtered_buck.dat') as f:
    for line in f.readlines():
        line_with_ends_removed       = line.strip()
        line_with_separated_contents = line.strip().strip()
        line_with_separated_contents = line_with_ends_removed.split()
        synth_simulation_time.append(float(line_with_separated_contents[0]))
        synth_inductor_current.append(float(line_with_separated_contents[1]))
        synth_capacitor_voltage.append(float(line_with_separated_contents[2]))

pyplot.subplot(2, 2, 1)
pyplot.plot(simulation_time, inductor_current)
pyplot.plot(synth_simulation_time, synth_inductor_current)
pyplot.plot(d.get_trace("time").get_time_axis(), d.get_trace("I(L1)"))
pyplot.ylabel('current(A)')
pyplot.legend(['current from VHDL', 'current from LTSpice'])

pyplot.subplot(2, 2, 3)
pyplot.plot(simulation_time, capacitor_voltage)
pyplot.plot(synth_simulation_time, synth_capacitor_voltage)
pyplot.plot(d.get_trace("time").get_time_axis(), d.get_trace("V(output_voltage)"))
pyplot.legend(['voltage from VHDL', 'voltage from LTSpice'])

pyplot.subplot(2, 2, 2)
pyplot.plot(simulation_time, input_current)
pyplot.plot(d.get_trace("time").get_time_axis(), d.get_trace("I(L3)"))
pyplot.legend(['voltage from VHDL', 'synt current', 'voltage from LTSpice'])

pyplot.subplot(2, 2, 4)
pyplot.plot(simulation_time, input_voltage)
pyplot.plot(d.get_trace("time").get_time_axis(), d.get_trace("v(input_voltage)"))
pyplot.legend(['voltage from VHDL', 'voltage from LTSpice'])

pyplot.xlabel('time (s)')
pyplot.ylabel('voltage(V)')

pyplot.show()
