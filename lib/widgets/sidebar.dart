import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../services/data_manager.dart';
import 'factorio_icon.dart';
import 'add_custom_item_dialog.dart';
import 'add_custom_recipe_dialog.dart';

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
        : allRecipes.where((r) => r.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    // Limit initial display if search is empty to avoid huge list rendering lag if needed,
    // but ListView.builder is efficient. Factorio has ~1000 recipes.
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[200],
          child: Row(
            children: const [
              Icon(Icons.list),
              SizedBox(width: 8),
              Text("Recipes", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        
        // Buttons for custom content
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context, 
                      builder: (ctx) => const AddCustomItemDialog()
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("New Item", style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                     showDialog(
                      context: context, 
                      builder: (ctx) => const AddCustomRecipeDialog()
                    );
                  },
                  icon: const Icon(Icons.add_link, size: 16),
                  label: const Text("New Recipe", style: TextStyle(fontSize: 11)),
                   style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        
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

              return ListTile(
                leading: iconId != null 
                    ? FactorioIcon(itemId: iconId) 
                    : const Icon(Icons.settings),
                title: Text(
                  recipe.name, 
                  overflow: TextOverflow.ellipsis,
                  style: isCustom ? const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold) : null,
                ),
                subtitle: Text(
                  "${recipe.category} • ${recipe.time}s", 
                  style: const TextStyle(fontSize: 10)
                ),
                dense: true,
                tileColor: isCustom ? Colors.purple.shade50 : null,
                onTap: () {
                  provider.addRecipeNode(recipe, isCustom: isCustom);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

