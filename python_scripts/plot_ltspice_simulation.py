from PyLTSpice import RawRead
import matplotlib.pyplot as plt         # use matplotlib for plotting the results

raw = RawRead(".\\testbenches_mcu_models\\3ph_lc\\3ph_lc.asc")   # Read the RAW file contents from disk

print(raw.get_trace_names())            # Get and print a list of all the traces
print(raw.get_raw_property())           # Print all the properties found in the Header section

vin = raw.get_trace('V(uc1,n)')            # Get the trace data
vout = raw.get_trace('V(uc2,n)')          # Get the second trace

steps = raw.get_steps()                 # Get list of step numbers ([0,1,2]) for sweeped simulations
                                        # Returns [0] if there is just 1 step

plt.figure()                            # Create the canvas for plotting

_, (ax1, ax2) = plt.subplots(2, 1, sharex=True)  # Create two subplots

for ax in (ax1, ax2):                   # Use grid on both subplots
    ax.grid(True)

plt.xlim([0.9e-3, 1.2e-3])              # Limit the X axis to just a subrange

xdata = raw.get_axis()                  # Get the X-axis data (time)

ydata = vin.get_wave()                  # Get all the values for the 'vin' trace
ax1.plot(xdata, ydata)                  # Do an X/Y plot on first subplot

ydata = vout.get_wave()                 # Get all the values for the 'vout' trace
ax1.plot(xdata, ydata)                  # Do an X/Y plot on first subplot as well

for step in steps:                      # On the second plot, print all the STEPS of Vout
    ydata = vout.get_wave(step)         # Retrieve the values for this step
    xdata = raw.get_axis(step)          # Retrieve the time vector
    ax2.plot(xdata, ydata)              # Do X/Y plot on second subplot

plt.show()                              # Show matplotlib's interactive window with the plots
