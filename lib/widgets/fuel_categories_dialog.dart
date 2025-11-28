import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';

class FuelCategoriesDialog extends StatefulWidget {
  const FuelCategoriesDialog({super.key});

  @override
  State<FuelCategoriesDialog> createState() => _FuelCategoriesDialogState();
}

class _FuelCategoriesDialogState extends State<FuelCategoriesDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlannerProvider>(context);
    final allCategories = provider.availableFuelCategories.toList()..sort();

    return AlertDialog(
      title: const Text("Fuel Categories"),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: "New Category Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      provider.addFuelCategory(_controller.text.trim());
                      _controller.clear();
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: allCategories.length,
                itemBuilder: (context, index) {
                  final category = allCategories[index];
                  // Can only delete custom added ones logic?
                  // The provider.deleteFuelCategory only removes from _customFuelCategories.
                  // If it's a base category, delete won't really do anything visually if we merge lists.
                  // So we should check if it's custom.
                  // But PlannerProvider.availableFuelCategories merges them.
                  // I'll just show delete button for all, and provider handles it safely (only removing from custom list).
                  // Ideally we distinguish visually.
                  
                  // Optimization: Check if it's in custom list to show delete button enabled?
                  // But I don't have direct access to _customFuelCategories from here without exposing it.
                  // I'll just let user try to delete.
                  
                  return ListTile(
                    title: Text(category),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                         provider.deleteFuelCategory(category);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
      ],
    );
  }
}

