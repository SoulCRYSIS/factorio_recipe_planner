import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../services/data_manager.dart';
import '../models/recipe.dart';
import '../models/item.dart';
import 'factorio_icon.dart';

class EditCustomRecipeDialog extends StatefulWidget {
  final Recipe recipe;
  const EditCustomRecipeDialog({super.key, required this.recipe});

  @override
  State<EditCustomRecipeDialog> createState() => _EditCustomRecipeDialogState();
}

class _EditCustomRecipeDialogState extends State<EditCustomRecipeDialog> {
  late TextEditingController _nameController;
  late TextEditingController _timeController;

  late Map<String, double> _ingredients;
  late Map<String, double> _products;
  late List<String> _producers;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipe.name);
    _timeController = TextEditingController(text: widget.recipe.time.toString());
    _ingredients = Map.from(widget.recipe.ingredients);
    _products = Map.from(widget.recipe.products);
    _producers = List.from(widget.recipe.producers);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Custom Recipe"),
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
              const Divider(),
              _buildProducerSection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
             // Confirm delete
             showDialog(
               context: context,
               builder: (ctx) => AlertDialog(
                 title: const Text("Delete Recipe?"),
                 content: const Text("This cannot be undone."),
                 actions: [
                   TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                   TextButton(onPressed: () {
                     Provider.of<PlannerProvider>(context, listen: false).deleteCustomRecipe(widget.recipe.id);
                     Navigator.pop(ctx); // Close confirm
                     Navigator.pop(context); // Close edit dialog
                   }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
                 ],
               )
             );
          }, 
          child: const Text("Delete", style: TextStyle(color: Colors.red))
        ),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _saveRecipe,
          child: const Text("Save"),
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

  Widget _buildProducerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Producers (Machines)", style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showMachinePicker(),
            ),
          ],
        ),
        ..._producers.map((id) {
          final provider = Provider.of<PlannerProvider>(context, listen: false);
          final name = provider.getItemName(id);
          return ListTile(
            leading: FactorioIcon(itemId: id),
            title: Text(name),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 16),
              onPressed: () => setState(() => _producers.remove(id)),
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

  void _showMachinePicker() {
    showDialog(
      context: context,
      builder: (ctx) => _ItemPickerDialog(
        onSelected: (item, _) {
          setState(() {
            if (!_producers.contains(item.id)) {
              _producers.add(item.id);
            }
          });
        },
        onlyMachines: true,
      ),
    );
  }

  void _saveRecipe() {
    if (_nameController.text.isEmpty || _products.isEmpty) return;

    final updatedRecipe = Recipe(
      id: widget.recipe.id, // Keep same ID
      name: _nameController.text,
      category: 'custom',
      row: widget.recipe.row,
      time: double.tryParse(_timeController.text) ?? 1.0,
      ingredients: _ingredients,
      products: _products,
      producers: _producers,
    );

    final provider = Provider.of<PlannerProvider>(context, listen: false);
    provider.updateCustomRecipe(updatedRecipe);
    Navigator.pop(context);
  }
}

class _ItemPickerDialog extends StatefulWidget {
  final Function(Item, double) onSelected;
  final bool onlyMachines;
  const _ItemPickerDialog({required this.onSelected, this.onlyMachines = false});

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

    var allItems = [...provider.customItems, ...?dataManager.data?.items];
    
    if (widget.onlyMachines) {
      allItems = allItems.where((i) => i.machine != null).toList();
    }

    return AlertDialog(
      title: Text(widget.onlyMachines ? "Select Machine" : "Select Item"),
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
            if (!widget.onlyMachines)
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

