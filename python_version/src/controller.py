import networkx as nx
import matplotlib.pyplot as plt
import uuid
import json
from typing import List, Dict, Optional
from .models import DataManager, Recipe, Item

class PlannerController:
    def __init__(self, data_manager: DataManager):
        self.data_manager = data_manager
        self.graph = nx.DiGraph()
        self.custom_recipes: List[Recipe] = []
        self.custom_items: List[Item] = []
        self.nodes: Dict[str, Recipe] = {} # Map Node ID -> Recipe

    def populate_all_recipes(self):
        if not self.data_manager.data:
            return

        print("Populating recipes...")
        count = 0
        for recipe in self.data_manager.data.recipes:
            # Filter (optional)
            if 'recycling' in recipe.category or 'recycling' in recipe.name.lower():
                continue
            if 'barrel' in recipe.name.lower():
                continue
            
            self.add_recipe_node(recipe, auto_connect=False)
            count += 1
            # if count > 500: break # Limit for safety if needed

        print(f"Added {count} nodes. Connecting...")
        self._bulk_connect()
        print(f"Graph has {self.graph.number_of_nodes()} nodes and {self.graph.number_of_edges()} edges.")

    def add_recipe_node(self, recipe: Recipe, is_custom: bool = False, auto_connect: bool = True):
        node_id = str(uuid.uuid4())
        self.nodes[node_id] = recipe
        self.graph.add_node(node_id, label=recipe.name, recipe=recipe)
        
        if auto_connect:
            self._auto_connect(node_id, recipe)
            
    def _bulk_connect(self):
        # Map Product -> List[NodeID]
        product_map: Dict[str, List[str]] = {}
        
        for node_id, recipe in self.nodes.items():
            for product in recipe.products.keys():
                if product not in product_map:
                    product_map[product] = []
                product_map[product].append(node_id)
                
        # Connect Ingredients -> Producers
        for node_id, recipe in self.nodes.items():
            for ingredient in recipe.ingredients.keys():
                if ingredient in product_map:
                    for producer_id in product_map[ingredient]:
                        # Avoid self-loops if desired, though valid in Factorio
                        if producer_id != node_id:
                            self.graph.add_edge(producer_id, node_id)

    def _auto_connect(self, new_node_id: str, new_recipe: Recipe):
        # Connect to existing nodes (O(N) scan, slower than bulk)
        for existing_id, existing_recipe in self.nodes.items():
            if existing_id == new_node_id: continue
            
            # Existing -> New
            for product in existing_recipe.products:
                if product in new_recipe.ingredients:
                    self.graph.add_edge(existing_id, new_node_id)
            
            # New -> Existing
            for product in new_recipe.products:
                if product in existing_recipe.ingredients:
                    self.graph.add_edge(new_node_id, existing_id)

    def visualize(self):
        # Use Graphviz layout (requires 'pygraphviz' or 'pydot') if available for better hierarchy
        # Fallback to spring layout if not.
        # For Factorio, a hierarchical layout (dot) is best.
        
        try:
            from networkx.drawing.nx_agraph import graphviz_layout
            pos = graphviz_layout(self.graph, prog='dot')
        except ImportError:
            print("PyGraphviz not found, using spring layout (random-ish). Install graphviz for better layout.")
            pos = nx.spring_layout(self.graph, k=0.5, iterations=50)

        plt.figure(figsize=(16, 12))
        
        # Draw nodes with labels
        # Use a list to ensure order matches
        node_list = list(self.graph.nodes())
        labels = {n: self.nodes[n].name for n in node_list}
        
        # Color nodes based on category (simple hash or map)
        colors = []
        for n in node_list:
            cat = self.nodes[n].category
            # Simple distinct color logic
            if 'logistics' in cat: colors.append('#e6b8af') # Light red
            elif 'production' in cat: colors.append('#fff2cc') # Light orange
            elif 'intermediate' in cat: colors.append('#d9ead3') # Light green
            elif 'science' in cat: colors.append('#c9daf8') # Light blue
            else: colors.append('#efefef') # Grey
            
        nx.draw_networkx_nodes(self.graph, pos, node_size=300, node_color=colors, node_shape='s') # 's' for square/box-ish
        nx.draw_networkx_edges(self.graph, pos, edge_color="gray", arrows=True, alpha=0.5)
        nx.draw_networkx_labels(self.graph, pos, labels=labels, font_size=8)
        
        plt.title("Factorio Recipe Graph (Hierarchy)")
        plt.axis('off')
        plt.tight_layout()
        plt.show()

    def export_to_json(self) -> str:
        data = {
            'customItems': [i.__dict__ for i in self.custom_items],
            'customRecipes': [r.__dict__ for r in self.custom_recipes],
            'nodes': []
        }
        
        for node_id, recipe in self.nodes.items():
            data['nodes'].append({
                'id': node_id,
                'recipeId': recipe.id,
                'isCustom': recipe in self.custom_recipes
            })
            
        return json.dumps(data)

    def import_from_json(self, json_str: str):
        try:
            data = json.loads(json_str)
            
            self.graph.clear()
            self.nodes.clear()
            self.custom_items = []
            self.custom_recipes = []
            
            for i in data.get('customItems', []):
                self.custom_items.append(Item(**i))
                
            for r in data.get('customRecipes', []):
                # Reconstruct recipe object carefully
                self.custom_recipes.append(Recipe(**r))
                
            for n in data.get('nodes', []):
                recipe_id = n['recipeId']
                is_custom = n['isCustom']
                
                recipe = None
                if is_custom:
                    recipe = next((r for r in self.custom_recipes if r.id == recipe_id), None)
                else:
                    recipe = self.data_manager.get_recipe(recipe_id)
                    
                if recipe:
                    self.add_recipe_node(recipe, is_custom=is_custom, auto_connect=False)
            
            # Reconnect all after import
            self._bulk_connect()
            
        except Exception as e:
            print(f"Error importing: {e}")
