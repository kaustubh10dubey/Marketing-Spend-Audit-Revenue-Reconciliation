import pandas as pd
import glob

def load_and_summarize_data():
    """
    Loads all CSV files from the 'data' directory, prints their shape and basic statistics.
    """
    csv_files = glob.glob('data/*.csv')
    
    for file in csv_files:
        try:
            df = pd.read_csv(file)
            print(f"--- {file} ---")
            print("Shape:", df.shape)
            print("Info:")
            df.info()
            print("Basic Stats:")
            print(df.describe())
            print("\n" + "="*50 + "\n")
        except Exception as e:
            print(f"Could not process {file}. Error: {e}")

if __name__ == "__main__":
    load_and_summarize_data()

