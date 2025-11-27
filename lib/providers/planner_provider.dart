import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:uuid/uuid.dart';
import '../models/node_data.dart';
import '../models/recipe.dart';
import '../models/item.dart';
import '../services/data_manager.dart';

class PlannerProvider extends ChangeNotifier {
  final Graph graph = Graph()..isTree = false;
  final SugiyamaConfiguration builder = SugiyamaConfiguration();
  final DataManager _dataManager;
  
  // We keep track of added nodes to iterate easily.
  final List<Node> _nodes = [];
  
  final List<Recipe> _customRecipes = [];
  final List<Item> _customItems = [];

  List<Recipe> get customRecipes => _customRecipes;
  List<Item> get customItems => _customItems;
  List<Node> get nodes => _nodes;

  PlannerProvider(this._dataManager) {
    builder
      ..nodeSeparation = (50)
      ..levelSeparation = (100)
      ..orientation = (SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM);
      
    // Initial population (delayed to avoid slowing down constructor)
    // We don't call this in constructor because it would freeze startup.
    // Better to let user add them or add a specific "Populate All" button.
    // But the user specifically asked for it to happen at start.
    // I will implement a method to populate all and call it from main.
  }
  
  void populateAllRecipes() {
    if (_dataManager.data == null) return;
    
    // We use a batch approach or just add all.
    for (final recipe in _dataManager.data!.recipes.sublist(0, 500)) {
      
      // --- FILTERING LOGIC START ---
      // Skip recycling recipes (usually have "recycling" in name or category)
      if (recipe.category.contains('recycling') || recipe.name.toLowerCase().contains('recycling')) {
        continue;
      }
      
      // Skip barrelling/unbarrelling recipes (high volume, clutters graph)
      if (recipe.name.toLowerCase().contains('barrel')) {
        continue;
      }
      // --- FILTERING LOGIC END ---

      final nodeData = NodeData(id: const Uuid().v4(), recipe: recipe, isCustom: false);
      final node = Node.Id(nodeData);
      
      graph.addNode(node);
      _nodes.add(node);
    }
    
    // Bulk Connect (O(N^2) is unavoidable for fully connected graph check without spatial index, 
    // but we can optimize by indexing products/ingredients).
    _bulkConnect();
    
    notifyListeners();
  }
  
  void _bulkConnect() {
    // Build a map of Product -> List<Node> for faster lookup
    final Map<String, List<Node>> productMap = {};
    
    for (final node in _nodes) {
      final data = node.key!.value as NodeData;
      for (final product in data.recipe.products.keys) {
        productMap.putIfAbsent(product, () => []).add(node);
      }
    }
    
    // Now iterate all nodes and connect their ingredients to producers
    for (final node in _nodes) {
      final data = node.key!.value as NodeData;
      for (final ingredient in data.recipe.ingredients.keys) {
        if (productMap.containsKey(ingredient)) {
          for (final producerNode in productMap[ingredient]!) {
             if (producerNode != node) {
               // We don't need to check containsEdge if we are building from scratch and logic is unique
               // But to be safe:
               // (Accessing edges list is O(E), so try to avoid excessive checks if possible)
               // GraphView doesn't have a fast hash lookup for edges.
               // However, since we are doing this in bulk, we can assume no duplicates if we iterate clearly.
               graph.addEdge(producerNode, node);
             }
          }
        }
      }
    }
  }

  void addRecipeNode(Recipe recipe, {bool isCustom = false}) {
    final nodeData = NodeData(id: const Uuid().v4(), recipe: recipe, isCustom: isCustom);
    final node = Node.Id(nodeData);
    
    graph.addNode(node);
    _nodes.add(node);
    
    _autoConnect(node, nodeData);
    
    notifyListeners();
  }

  void _autoConnect(Node newNode, NodeData newData) {
    for (final existingNode in _nodes) {
      if (existingNode == newNode) continue;
      
      final existingData = existingNode.key!.value as NodeData;
      
      // Check 1: Existing (Output) -> New (Input)
      // Does existing recipe produce something the new recipe needs?
      // NOTE: Factorio recipes can be cyclic (e.g. kovarex enrichment, or mixed outputs).
      // A -> B -> A cycle will cause Sugiyama layout to potentially loop or crash if not handled.
      // GraphView's Sugiyama usually handles cycles by reversing edges temporarily, 
      // but let's try to avoid trivial direct cycles A<->A if possible, though graph.addEdge doesn't prevent it.
      
      for (final product in existingData.recipe.products.keys) {
        if (newData.recipe.ingredients.containsKey(product)) {
          // Avoid duplicate edges
          final hasEdge = graph.edges.any((edge) => 
            edge.source == existingNode && edge.destination == newNode
          );
          
          // Avoid self-loops (A->A) which are common in some processes (e.g. Kovarex)
          if (existingNode == newNode) continue;

          if (!hasEdge) {
             graph.addEdge(existingNode, newNode);
          }
        }
      }

      // Check 2: New (Output) -> Existing (Input)
      // Does new recipe produce something the existing recipe needs?
      for (final product in newData.recipe.products.keys) {
        if (existingData.recipe.ingredients.containsKey(product)) {
           final hasEdge = graph.edges.any((edge) => 
            edge.source == newNode && edge.destination == existingNode
           );
           
           if (existingNode == newNode) continue;

           if (!hasEdge) {
            graph.addEdge(newNode, existingNode);
          }
        }
      }
    }
  }

  void removeNode(Node node) {
    graph.removeNode(node);
    _nodes.remove(node);
    notifyListeners();
  }

  void clearBoard() {
    // Create a copy of the list to avoid concurrent modification issues if we were iterating
    final nodesToRemove = List<Node>.from(_nodes);
    for (final node in nodesToRemove) {
      graph.removeNode(node);
    }
    _nodes.clear();
    notifyListeners();
  }

  void addCustomItem(Item item) {
    _customItems.add(item);
    notifyListeners();
  }

  void addCustomRecipe(Recipe recipe) {
    _customRecipes.add(recipe);
    notifyListeners();
  }
  
  // Helper to find item name
  String getItemName(String id) {
    // Check custom items first
    try {
      return _customItems.firstWhere((i) => i.id == id).name;
    } catch (_) {
      // Then data manager
      return _dataManager.getItem(id)?.name ?? id;
    }
  }
  
  // Simple Export/Import implementation
  String exportToJson() {
    final Map<String, dynamic> data = {
      'customItems': _customItems.map((i) => i.toJson()).toList(),
      'customRecipes': _customRecipes.map((r) => r.toJson()).toList(),
      'nodes': _nodes.map((n) {
        final nd = n.key!.value as NodeData;
        return {
          'id': nd.id,
          'recipeId': nd.recipe.id,
          'isCustom': nd.isCustom,
        };
      }).toList(),
    };
    return jsonEncode(data);
  }

  void importFromJson(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      
      clearBoard();
      _customItems.clear();
      _customRecipes.clear();

      if (data['customItems'] != null) {
        for (var i in data['customItems']) {
          _customItems.add(Item.fromJson(i));
        }
      }
      
      if (data['customRecipes'] != null) {
        for (var r in data['customRecipes']) {
          _customRecipes.add(Recipe.fromJson(r));
        }
      }

      if (data['nodes'] != null) {
        for (var n in data['nodes']) {
          final String recipeId = n['recipeId'];
          final bool isCustom = n['isCustom'] ?? false;
          
          Recipe? recipe;
          if (isCustom) {
            recipe = _customRecipes.firstWhere((r) => r.id == recipeId, orElse: () => throw Exception("Custom recipe not found"));
          } else {
            recipe = _dataManager.getRecipe(recipeId);
          }
          
          if (recipe != null) {
            // We use addRecipeNode which triggers auto-connect. 
            // However, if we want to exact restore the graph connections instead of auto-connecting,
            // we might need to store edges in JSON.
            // For now, "auto-arrange" and "auto-connect" logic implies reconstructing connections based on logic is fine.
            // But sequential addition might result in different connections if logic depends on order?
            // My autoConnect is symmetric (checks both ways), so order shouldn't matter for final connectivity set.
            addRecipeNode(recipe, isCustom: isCustom);
          }
        }
      }
      notifyListeners();
    } catch (e) {
      print("Error importing JSON: $e");
      // Rethrow or handle error UI
    }
  }
}

