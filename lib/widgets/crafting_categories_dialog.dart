import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';

class CraftingCategoriesDialog extends StatefulWidget {
  const CraftingCategoriesDialog({super.key});

  @override
  State<CraftingCategoriesDialog> createState() => _CraftingCategoriesDialogState();
}

class _CraftingCategoriesDialogState extends State<CraftingCategoriesDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlannerProvider>(context);
    final allCategories = provider.availableCraftingCategories.toList()..sort();

    return AlertDialog(
      title: const Text("Crafting Categories"),
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
                      provider.addCraftingCategory(_controller.text.trim());
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
                  return ListTile(
                    title: Text(category),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                         provider.deleteCraftingCategory(category);
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

