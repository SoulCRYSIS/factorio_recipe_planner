import 'package:flutter/material.dart';
import '../models/node_data.dart';
import 'factorio_icon.dart';
import 'edit_custom_recipe_dialog.dart';

class RecipeNode extends StatelessWidget {
  final NodeData nodeData;

  const RecipeNode({super.key, required this.nodeData});

  @override
  Widget build(BuildContext context) {
    final recipe = nodeData.recipe;
    
    return GestureDetector(
      onTap: () {
        // Open edit dialog if it's a custom recipe
        if (nodeData.isCustom) {
          showDialog(
            context: context,
            builder: (ctx) => EditCustomRecipeDialog(recipe: recipe),
          );
        } else {
          // Maybe show info for base recipes? For now, do nothing or show snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cannot edit base game recipes."), duration: Duration(seconds: 1)),
          );
        }
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: nodeData.isCustom ? Colors.purple.shade50 : Colors.grey.shade200,
          border: Border.all(
            color: nodeData.isCustom ? Colors.purple : Colors.blueGrey,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ingredients (Inputs) - displayed at top
            if (recipe.ingredients.isNotEmpty) ...[
              Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: recipe.ingredients.entries.map((e) {
                  return Tooltip(
                    message: "${e.key}: ${e.value}",
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FactorioIcon(itemId: e.key, size: 20),
                        Text("${e.value}", style: const TextStyle(fontSize: 9)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const Divider(height: 8),
            ],
      
            // Title
            Text(
              recipe.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text("${recipe.time}s", style: const TextStyle(fontSize: 9, color: Colors.grey)),
            
            // Producers
            if (recipe.producers.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 2,
                children: recipe.producers.map((id) => FactorioIcon(itemId: id, size: 12)).toList(),
              ),
            ],
      
            const Divider(height: 8),
      
            // Products (Outputs) - displayed at bottom
            Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: recipe.products.entries.map((e) {
                return Tooltip(
                  message: "${e.key}: ${e.value}",
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FactorioIcon(itemId: e.key, size: 28),
                      Text("${e.value}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
