import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/planner_provider.dart';
import '../services/data_manager.dart';
import '../models/recipe.dart';
import '../models/item.dart';
import 'factorio_icon.dart';

class AddCustomRecipeDialog extends StatefulWidget {
  const AddCustomRecipeDialog({super.key});

  @override
  State<AddCustomRecipeDialog> createState() => _AddCustomRecipeDialogState();
}

class _AddCustomRecipeDialogState extends State<AddCustomRecipeDialog> {
  final _nameController = TextEditingController();
  final _timeController = TextEditingController(text: "1.0");

  final Map<String, double> _ingredients = {};
  final Map<String, double> _products = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("New Custom Recipe"),
      content: SizedBox(
        width: 500,
        height: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: "Recipe Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _timeController,
                decoration: const InputDecoration(
                    labelText: "Time (s)", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildSection("Ingredients", _ingredients),
              const Divider(),
              _buildSection("Products", _products),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _createRecipe,
          child: const Text("Create"),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Map<String, double> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showItemPicker((item, amount) {
                setState(() {
                  items[item.id] = amount;
                });
              }),
            ),
          ],
        ),
        ...items.entries.map((e) {
          final provider = Provider.of<PlannerProvider>(context, listen: false);
          final name = provider.getItemName(e.key);
          return ListTile(
            leading: FactorioIcon(itemId: e.key),
            title: Text(name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("${e.value}"),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 16),
                  onPressed: () => setState(() => items.remove(e.key)),
                )
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showItemPicker(Function(Item, double) onSelected) {
    showDialog(
      context: context,
      builder: (ctx) => _ItemPickerDialog(onSelected: onSelected),
    );
  }

  void _createRecipe() {
    if (_nameController.text.isEmpty || _products.isEmpty) return;

    final recipe = Recipe(
      id: const Uuid().v4(),
      name: _nameController.text,
      category: 'custom',
      row: 0,
      time: double.tryParse(_timeController.text) ?? 1.0,
      ingredients: _ingredients,
      products: _products,
      producers: [],
    );

    final provider = Provider.of<PlannerProvider>(context, listen: false);
    provider.addCustomRecipe(recipe);
    provider.addRecipeNode(recipe, isCustom: true);
    Navigator.pop(context);
  }
}

class _ItemPickerDialog extends StatefulWidget {
  final Function(Item, double) onSelected;
  const _ItemPickerDialog({required this.onSelected});

  @override
  State<_ItemPickerDialog> createState() => _ItemPickerDialogState();
}

class _ItemPickerDialogState extends State<_ItemPickerDialog> {
  final _searchController = TextEditingController();
  final _amountController = TextEditingController(text: "1");

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    final provider = Provider.of<PlannerProvider>(context, listen: false);

    final allItems = [...provider.customItems, ...?dataManager.data?.items];

    return AlertDialog(
      title: const Text("Select Item"),
      content: SizedBox(
        width: 300,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                  hintText: "Search...", prefixIcon: Icon(Icons.search)),
              onChanged: (val) => setState(() {}),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: "Amount"),
              keyboardType: TextInputType.number,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: allItems.length,
                itemBuilder: (ctx, i) {
                  final item = allItems[i];
                  if (_searchController.text.isNotEmpty &&
                      !item.name
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase())) {
                    return const SizedBox.shrink();
                  }
                  return ListTile(
                    leading: FactorioIcon(itemId: item.id),
                    title: Text(item.name),
                    onTap: () {
                      widget.onSelected(
                          item, double.tryParse(_amountController.text) ?? 1.0);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
