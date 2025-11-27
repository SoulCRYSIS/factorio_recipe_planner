import sys
import os
# Add src to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from src.models import DataManager
from src.controller import PlannerController

def main():
    print("Loading Factorio data...")
    data_manager = DataManager("python_version/assets/data.json")
    data_manager.load_data()
    
    controller = PlannerController(data_manager)
    controller.populate_all_recipes()
    
    print("Visualizing graph (this might take a moment)...")
    controller.visualize()

if __name__ == "__main__":
    main()
