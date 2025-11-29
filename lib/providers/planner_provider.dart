import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:uuid/uuid.dart';
import '../models/node_data.dart';
import '../models/recipe.dart';
import '../models/item.dart';
import '../services/data_manager.dart';

import '../models/project_model.dart';

class PlannerProvider extends ChangeNotifier {
  final Graph graph = Graph()..isTree = false;
  final SugiyamaConfiguration builder = SugiyamaConfiguration();
  final DataManager _dataManager;

  // We keep track of added nodes to iterate easily.
  final List<Node> _nodes = [];

  final List<Recipe> _customRecipes = [];
  final List<Item> _customItems = [];
  final Set<String> _customFuelCategories = {};
  Set<String>? _cachedBaseFuelCategories;

  List<Recipe> get customRecipes => _customRecipes;
  List<Item> get customItems => _customItems;
  List<Node> get nodes => _nodes;

  Set<String> get availableFuelCategories {
    if (_cachedBaseFuelCategories == null) {
      _cachedBaseFuelCategories = {};
      if (_dataManager.data != null) {
        for (var item in _dataManager.data!.items) {
          if (item.machine?.fuelCategories != null) {
            _cachedBaseFuelCategories!.addAll(item.machine!.fuelCategories!);
          }
        }
      }
    }
    return {..._cachedBaseFuelCategories!, ..._customFuelCategories};
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _autoSaveTimer;
  String? _currentDocId;
  String _projectName = "Untitled Project";

  String? get currentDocId => _currentDocId;
  String get projectName => _projectName;

  PlannerProvider(this._dataManager) {
    builder
      ..layeringStrategy = LayeringStrategy.longestPath
      ..nodeSeparation = (50)
      ..levelSeparation = (100)
      ..orientation = (SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM);
  }

  void refreshLayout() {
    notifyListeners();
  }

  void loadProject(ProjectModel project) {
    _currentDocId = project.id;
    _projectName = project.name;

    // Import data safely
    try {
      // Use jsonEncode to convert Map<String, dynamic> back to JSON string for importFromJson
      // importFromJson expects a String
      final jsonString = jsonEncode(project.data);
      importFromJson(jsonString);
    } catch (e) {
      print("Error loading project data: $e");
      clearBoard(shouldSave: false);
    }
  }

  // REMOVED populateAllRecipes to avoid performance issues.
  // Users must add recipes manually or via a search dialog.

  void addRecipeNode(Recipe recipe, {bool isCustom = false}) {
    // Toggle logic: If a node with this recipe already exists, remove it instead
    final existingNode = _nodes.firstWhere(
      (n) {
        final data = n.key!.value as NodeData;
        return data.recipe.id == recipe.id && data.isCustom == isCustom;
      },
      orElse: () => Node.Id(null), // Dummy node for check
    );

    if (existingNode.key?.value != null) {
      removeNode(existingNode);
      return; // Stop here if removed
    }

    // Otherwise add it
    final nodeData =
        NodeData(id: const Uuid().v4(), recipe: recipe, isCustom: isCustom);
    final node = Node.Id(nodeData);

    graph.addNode(node);
    _nodes.add(node);

    _autoConnect(node, nodeData);

    _scheduleAutoSave();
    notifyListeners();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _saveToFirestore);
  }

  Future<void> _saveToFirestore() async {
    final json = exportToJson();
    final data = jsonDecode(json);

    try {
      if (_currentDocId == null) {
        final doc = await _firestore.collection('plans').add({
          'name': _projectName,
          'data': data,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _currentDocId = doc.id;
      } else {
        await _firestore.collection('plans').doc(_currentDocId).update({
          'name': _projectName,
          'data': data,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      print('Auto-saved to Firestore: $_currentDocId');
    } catch (e) {
      print('Error saving to Firestore: $e');
    }
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
              edge.source == existingNode && edge.destination == newNode);

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
              edge.source == newNode && edge.destination == existingNode);

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
    _scheduleAutoSave();
    notifyListeners();
  }

  void clearBoard({bool shouldSave = true}) {
    // Create a copy of the list to avoid concurrent modification issues if we were iterating
    final nodesToRemove = List<Node>.from(_nodes);
    for (final node in nodesToRemove) {
      graph.removeNode(node);
    }
    _nodes.clear();
    if (shouldSave) _scheduleAutoSave();
    notifyListeners();
  }

  void addCustomItem(Item item) {
    _customItems.insert(0, item); // Add to beginning of list
    _scheduleAutoSave();
    notifyListeners();
  }
  
  void updateCustomItem(Item item) {
    final index = _customItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _customItems[index] = item;
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void deleteCustomItem(String itemId) {
    _customItems.removeWhere((item) => item.id == itemId);
    // Also remove any custom recipes that use this item? Or keep them but they might break?
    // For safety, we won't cascade delete recipes, but visual bugs might occur if recipe uses deleted item.
    // Actually, best to leave recipes, they will just show missing icon or name.
    _scheduleAutoSave();
    notifyListeners();
  }

  void addCustomRecipe(Recipe recipe) {
    _customRecipes.insert(0, recipe); // Add to beginning of list
    _scheduleAutoSave();
    notifyListeners();
  }

  void updateCustomRecipe(Recipe recipe) {
    final index = _customRecipes.indexWhere((r) => r.id == recipe.id);
    if (index != -1) {
      _customRecipes[index] = recipe;
      
      // Update the recipe in any nodes that use it AND refresh connections
      for (final node in _nodes) {
         final data = node.key!.value as NodeData;
         if (data.isCustom && data.recipe.id == recipe.id) {
             // Update the recipe reference in NodeData
             data.recipe = recipe;
             
             // Remove existing edges for this node
             final edgesToRemove = graph.edges.where((e) => e.source == node || e.destination == node).toList();
             for (final edge in edgesToRemove) {
               graph.removeEdge(edge);
             }
             
             // Re-run auto-connect
             // Note: _autoConnect checks BOTH directions (in and out)
             _autoConnect(node, data);
         }
      }
      
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void deleteCustomRecipe(String recipeId) {
    final recipe = _customRecipes.firstWhere((r) => r.id == recipeId, orElse: () => Recipe(id: '', name: '', category: '', row: 0, time: 0, ingredients: {}, products: {}, producers: []));
    if (recipe.id == '') return;

    // Remove nodes using this recipe first
    final nodesToRemove = _nodes.where((n) {
      final data = n.key!.value as NodeData;
      return data.isCustom && data.recipe.id == recipeId;
    }).toList();

    for (final node in nodesToRemove) {
      graph.removeNode(node);
      _nodes.remove(node);
    }

    _customRecipes.removeWhere((r) => r.id == recipeId);
    _scheduleAutoSave();
    notifyListeners();
  }

  void addFuelCategory(String category) {
    if (!_customFuelCategories.contains(category)) {
      _customFuelCategories.add(category);
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void deleteFuelCategory(String category) {
    if (_customFuelCategories.contains(category)) {
      _customFuelCategories.remove(category);
      _scheduleAutoSave();
      notifyListeners();
    }
    // Note: Cannot delete base game fuel categories, and we don't track them here to delete.
    // If user wants to 'hide' them, that's a different feature.
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
      'customFuelCategories': _customFuelCategories.toList(),
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
      _customFuelCategories.clear();

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
      
      if (data['customFuelCategories'] != null) {
        for (var c in data['customFuelCategories']) {
          _customFuelCategories.add(c);
        }
      }

      if (data['nodes'] != null) {
        for (var n in data['nodes']) {
          final String recipeId = n['recipeId'];
          final bool isCustom = n['isCustom'] ?? false;

          Recipe? recipe;
          if (isCustom) {
            recipe = _customRecipes.firstWhere((r) => r.id == recipeId,
                orElse: () => throw Exception("Custom recipe not found"));
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

  void createNewProject(String name) {
    _currentDocId = null;
    _projectName = name;
    clearBoard(
        shouldSave:
            false); // Clear local state without overwriting anything yet
    _saveToFirestore(); // Create initial doc
  }
}
