import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../services/data_manager.dart';
import '../models/node_data.dart';
import '../models/item.dart';
import 'factorio_icon.dart';
import 'add_custom_item_dialog.dart';
import 'add_custom_recipe_dialog.dart';
import 'all_items_dialog.dart';
import 'fuel_categories_dialog.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String _searchQuery = "";
  final Set<String> _selectedCategories = {};
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final provider = Provider.of<PlannerProvider>(context);

    // Combine standard recipes and custom recipes
    final allRecipes = [
      ...provider.customRecipes,
      ...?dataManager.data?.recipes,
    ];

    // Extract all unique categories
    final allCategories = allRecipes.map((r) => r.category).toSet().toList()..sort();

    // Initialize selection if first run
    if (!_initialized && allCategories.isNotEmpty) {
      _selectedCategories.addAll(allCategories);
      _initialized = true;
    }
    // Also ensure new categories are added if data changes (e.g. custom recipe added with new category)
    // But we don't want to re-select everything if user deselected some.
    // For simplicity, we'll just rely on manual filtering, but if a new category appears it won't be selected by default if we strictly filter?
    // Actually, "Select All" usually implies "Everything".
    // Let's handle this in the filter dialog.

    final filteredRecipes = allRecipes.where((r) {
      final matchesSearch = _searchQuery.isEmpty ||
          r.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategories.contains(r.category);
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.add, size: 16),
              tooltip: "New Item",
              onPressed: () async {
                final newItem = await showDialog<Item>(
                    context: context,
                    builder: (ctx) => const AddCustomItemDialog());
                
                if (newItem != null && mounted) {
                   // Chain to Add Recipe Dialog
                   showDialog(
                     context: context,
                     builder: (ctx) => AddCustomRecipeDialog(initialProduct: newItem)
                   );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_link, size: 16),
              tooltip: "New Recipe",
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (ctx) => const AddCustomRecipeDialog());
              },
            ),
            IconButton(
              icon: const Icon(Icons.local_gas_station, size: 20),
              tooltip: "Fuel Categories",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const FuelCategoriesDialog(),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.grid_view, size: 20),
              tooltip: "View All Items",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const AllItemsDialog(),
                );
              },
            ),
          ],
        ),

        // Search Bar & Filter
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: "Search recipes...",
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: _selectedCategories.length != allCategories.length ? Colors.blue : null,
                ),
                tooltip: "Filter by Category",
                onPressed: () => _showFilterDialog(allCategories),
              ),
            ],
          ),
        ),

        // Recipe List
        Expanded(
          child: ListView.builder(
            itemCount: filteredRecipes.length,
            itemBuilder: (ctx, index) {
              final recipe = filteredRecipes[index];

              // Find a suitable icon (first product)
              String? iconId;
              if (recipe.products.isNotEmpty) {
                iconId = recipe.products.keys.first;
              }

              final bool isCustom = provider.customRecipes.contains(recipe);

              // Check if this recipe is already on the board (simple check)
              final isOnBoard = provider.nodes.any((node) {
                if (node.key?.value is NodeData) {
                  final data = node.key!.value as NodeData;
                  return data.recipe.id == recipe.id &&
                      data.isCustom == isCustom;
                }
                return false;
              });

              return ListTile(
                leading: iconId != null
                    ? FactorioIcon(itemId: iconId)
                    : const Icon(Icons.settings),
                title: Text(
                  recipe.name,
                  overflow: TextOverflow.ellipsis,
                  style: isCustom
                      ? const TextStyle(
                          color: Colors.purple, fontWeight: FontWeight.bold)
                      : null,
                ),
                subtitle: Text("${recipe.category} • ${recipe.time}s",
                    style: const TextStyle(fontSize: 10)),
                dense: true,
                tileColor: isOnBoard
                    ? Colors.green.withOpacity(0.1)
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOnBoard)
                      const Icon(Icons.check, color: Colors.green, size: 16),
                    if (isCustom) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red, size: 16),
                        onPressed: () {
                          _confirmDelete(
                              context, provider, recipe.id, recipe.name);
                        },
                      ),
                    ]
                  ],
                ),
                onTap: () {
                  // Add to graph on click
                  provider.addRecipeNode(recipe, isCustom: isCustom);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFilterDialog(List<String> allCategories) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Filter Categories"),
              content: SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            setStateDialog(() {
                              _selectedCategories.addAll(allCategories);
                            });
                            // Also update main state
                            this.setState(() {});
                          }, 
                          child: const Text("Select All")
                        ),
                        TextButton(
                          onPressed: () {
                            setStateDialog(() {
                              _selectedCategories.clear();
                            });
                            this.setState(() {});
                          }, 
                          child: const Text("Unselect All")
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        children: allCategories.map((cat) {
                          return CheckboxListTile(
                            title: Text(cat),
                            value: _selectedCategories.contains(cat),
                            dense: true,
                            onChanged: (val) {
                              setStateDialog(() {
                                if (val == true) {
                                  _selectedCategories.add(cat);
                                } else {
                                  _selectedCategories.remove(cat);
                                }
                              });
                              // Force rebuild of sidebar list immediately
                              this.setState(() {}); 
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Done"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, PlannerProvider provider,
      String recipeId, String recipeName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete $recipeName?"),
        content: const Text(
            "This will remove the recipe and any nodes using it on the board."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              provider.deleteCustomRecipe(recipeId);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
