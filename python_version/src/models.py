import json
from dataclasses import dataclass
from typing import List, Dict, Optional, Any

@dataclass
class Item:
    id: str
    name: str
    category: str
    stack: Optional[int] = None
    row: int = 0
    iconId: Optional[str] = None

@dataclass
class Recipe:
    id: str
    name: str
    category: str
    row: int
    time: float
    ingredients: Dict[str, float]
    products: Dict[str, float]
    producers: List[str]

@dataclass
class IconDefinition:
    id: str
    position: str
    color: str
    
    @property
    def x(self) -> float:
        return abs(float(self.position.split(' ')[0].replace('px', '')))
        
    @property
    def y(self) -> float:
        return abs(float(self.position.split(' ')[1].replace('px', '')))

@dataclass
class Category:
    id: str
    name: str
    icon: Optional[str] = None

class FactorioData:
    def __init__(self, data: Dict[str, Any]):
        self.version = data.get('version', {})
        self.categories = [Category(**c) for c in data.get('categories', [])]
        self.icons = [IconDefinition(**i) for i in data.get('icons', [])]
        
        # Handle Items with extra fields safely
        self.items = []
        for i in data.get('items', []):
            # Filter out fields not in dataclass or use **kwargs with a custom init
            # Simple approach: just pick what we need
            self.items.append(Item(
                id=i['id'],
                name=i['name'],
                category=i['category'],
                stack=i.get('stack'),
                row=i.get('row', 0)
            ))
            
        self.recipes = []
        for r in data.get('recipes', []):
            self.recipes.append(Recipe(
                id=r['id'],
                name=r['name'],
                category=r['category'],
                row=r.get('row', 0),
                time=float(r.get('time', 1.0)),
                ingredients=r.get('in', {}),
                products=r.get('out', {}),
                producers=r.get('producers', [])
            ))

class DataManager:
    def __init__(self, json_path: str):
        self.data: Optional[FactorioData] = None
        self.json_path = json_path

    def load_data(self):
        with open(self.json_path, 'r', encoding='utf-8') as f:
            raw_data = json.load(f)
            self.data = FactorioData(raw_data)
            print(f"Loaded {len(self.data.items)} items and {len(self.data.recipes)} recipes.")

    def get_recipe(self, recipe_id: str) -> Optional[Recipe]:
        if not self.data: return None
        return next((r for r in self.data.recipes if r.id == recipe_id), None)

    def get_item(self, item_id: str) -> Optional[Item]:
        if not self.data: return None
        return next((i for i in self.data.items if i.id == item_id), None)

