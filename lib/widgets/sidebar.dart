import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../services/data_manager.dart';
import '../models/node_data.dart';
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

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final provider = Provider.of<PlannerProvider>(context);

    // Combine standard recipes and custom recipes
    final allRecipes = [
      ...provider.customRecipes,
      ...?dataManager.data?.recipes,
    ];

    final filteredRecipes = _searchQuery.isEmpty
        ? allRecipes
        : allRecipes
            .where((r) =>
                r.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    // Limit initial display if search is empty to avoid huge list rendering lag if needed,
    // but ListView.builder is efficient. Factorio has ~1000 recipes.

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.add, size: 16),
              tooltip: "New Item",
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (ctx) => const AddCustomItemDialog());
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

        // Search Bar
        Padding(
          padding: const EdgeInsets.all(8.0),
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
