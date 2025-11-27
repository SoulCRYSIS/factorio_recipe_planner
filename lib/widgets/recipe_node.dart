import 'package:flutter/material.dart';
import '../models/node_data.dart';
import 'factorio_icon.dart';

class RecipeNode extends StatelessWidget {
  final NodeData nodeData;
  final VoidCallback? onTap;

  const RecipeNode({super.key, required this.nodeData, this.onTap});

  @override
  Widget build(BuildContext context) {
    final recipe = nodeData.recipe;
    
    return GestureDetector(
      onTap: onTap,
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
              const Text("In", style: TextStyle(fontSize: 9, color: Colors.grey)),
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

            const Divider(height: 8),

            // Products (Outputs) - displayed at bottom
            const Text("Out", style: TextStyle(fontSize: 9, color: Colors.grey)),
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

