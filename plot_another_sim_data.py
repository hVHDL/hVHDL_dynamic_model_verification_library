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

d = LTSpiceRawRead(abs_path + "./testbenches/converter_models/spice_reference_models/grid_inverter_transient.raw")

simulation_time   = []

i1  = []
c1 = []

i2  = []
c2 = []

i3  = []
c3 = []

with open('grid_inverter_inductor_step.dat') as f:
    for line in f.readlines():
        line_with_ends_removed       = line.strip()
        line_with_separated_contents = line_with_ends_removed.split()
        simulation_time.append(float(line_with_separated_contents[0]))
        i1.append(float(line_with_separated_contents[1]))
        c1.append(float(line_with_separated_contents[2]))
        i2.append(float(line_with_separated_contents[3]))
        c2.append(float(line_with_separated_contents[4]))
        i3.append(float(line_with_separated_contents[5]))
        c3.append(float(line_with_separated_contents[6]))

pyplot.subplot(2, 3, 1)
pyplot.plot(simulation_time, i3)
pyplot.plot(d.get_trace("time").get_time_axis(), d.get_trace("I(L3)"))
pyplot.ylabel('current(A)')
pyplot.legend(['current from VHDL', 'current from LTSpice'])

pyplot.subplot(2, 3, 4)
pyplot.plot(simulation_time, c3)
pyplot.plot(d.get_trace("time").get_time_axis(), d.get_trace("V(VC3)"))
pyplot.legend(['voltage from VHDL', 'voltage from LTSpice'])

pyplot.subplot(2, 3, 2)
pyplot.plot(simulation_time, i2)
pyplot.plot(d.get_trace("time").get_time_axis(), d.get_trace("I(L2)"))
pyplot.ylabel('current(A)')
pyplot.legend(['current from VHDL', 'current from LTSpice'])

pyplot.subplot(2, 3, 5)
pyplot.plot(simulation_time, c2)
pyplot.plot(d.get_trace("time").get_time_axis(), d.get_trace("V(VC2)"))
pyplot.legend(['voltage from VHDL', 'voltage from LTSpice'])

pyplot.subplot(2, 3, 3)
pyplot.plot(simulation_time, i1)
pyplot.plot(d.get_trace("time").get_time_axis(), d.get_trace("I(L1)"))
pyplot.ylabel('current(A)')
pyplot.legend(['current from VHDL', 'current from LTSpice'])

pyplot.subplot(2, 3, 6)
pyplot.plot(simulation_time, c1)
pyplot.plot(d.get_trace("time").get_time_axis(), d.get_trace("V(VC1)"))
pyplot.legend(['voltage from VHDL', 'voltage from LTSpice'])


pyplot.legend(['voltage from VHDL', 'voltage from LTSpice'])

pyplot.xlabel('time (s)')
pyplot.ylabel('voltage(V)')

pyplot.show()
