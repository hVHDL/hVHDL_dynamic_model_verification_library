import sys
import pandas as pd
import matplotlib.pyplot as plt

def plot_data(filenames):
    # Initialize a single figure with two subplots (top and bottom)
    fig, (ax_top, ax_bottom) = plt.subplots(2, 1, sharex=True, figsize=(7, 5))
    
    # Process each file
    for filename in filenames:
        try:
            # Load the data file into a DataFrame
            df = pd.read_csv(filename, delim_whitespace=True)
            
            # Check if 'time' column is present
            if 'time' not in df.columns:
                print(f"Error: 'time' column is missing in file '{filename}'. Skipping this file.")
                continue

            # Set 'time' as the index for the plot
            df.set_index('time', inplace=True)
            
            # Split columns into top and bottom based on the prefix
            top_columns = [col for col in df.columns if col.startswith("T_")]
            bottom_columns = [col for col in df.columns if col.startswith("B_")]
            
            # Plot top columns
            if top_columns:
                df[top_columns].plot(ax=ax_top, title="Top Data Plot", label=filename, legend=True)
                ax_top.set_ylabel("Top Data Values")
                ax_top.grid(True)
            
            # Plot bottom columns
            if bottom_columns:
                df[bottom_columns].plot(ax=ax_bottom, title="Bottom Data Plot", label=filename, legend=True)
                ax_bottom.set_ylabel("Bottom Data Values")
                ax_bottom.grid(True)

        except FileNotFoundError:
            print(f"Error: File '{filename}' not found. Skipping this file.")
        except pd.errors.EmptyDataError:
            print(f"Error: The file '{filename}' is empty. Skipping this file.")
        except Exception as e:
            print(f"An error occurred with file '{filename}': {e}. Skipping this file.")

    # Set shared x-label and layout adjustments
    plt.xlabel("Time")
    plt.tight_layout(rect=[0, 0, 1, 0.96])  # Adjust layout to fit the main title
    plt.show()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python plot_data.py <filename1> <filename2> ...")
    else:
        filenames = sys.argv[1:]  # List of all provided filenames
        plot_data(filenames)

