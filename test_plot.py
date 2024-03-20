import pandas as pd
import matplotlib.pyplot as plt

def plot_dynamic_data_from_file(filename):
    # Read the data from the file
    data = pd.read_csv(filename, delim_whitespace=True)
    
    # Determine the number of data columns (excluding the time column)
    num_data_columns = len(data.columns) - 1
    
    # Create a figure and a set of subplots
    fig, ax1 = plt.subplots()
    
    # Colors for each plot
    colors = ['tab:red', 'tab:blue', 'tab:green', 'tab:orange', 'tab:purple']
    
    for i in range(num_data_columns):
        if i == 0:
            # First data column uses ax1
            ax = ax1
            color = colors[i % len(colors)]
            ax.set_xlabel('time')
            ax.set_ylabel(data.columns[i+1], color=color)
            ax.plot(data['time'], data[data.columns[i+1]], color=color)
            ax.tick_params(axis='y', labelcolor=color)
        else:
            # Additional data columns use a twin of the x-axis
            ax = ax1.twinx()
            ax.spines['right'].set_position(('outward', 60*(i-1)))  # Offset the right spine of subsequent axes
            color = colors[i % len(colors)]
            ax.set_ylabel(data.columns[i+1], color=color)
            ax.plot(data['time'], data[data.columns[i+1]], color=color)
            ax.tick_params(axis='y', labelcolor=color)
    
    fig.tight_layout()  # Adjust layout to make room for the added axes
    plt.show()

# Replace 'your_file.txt' with the path to your data file
# plot_dynamic_data_from_file('your_file.txt')

