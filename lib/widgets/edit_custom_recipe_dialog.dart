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
  
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipe.name);
    _timeController = TextEditingController(text: widget.recipe.time.toString());
    _ingredients = Map.from(widget.recipe.ingredients);
    _products = Map.from(widget.recipe.products);
    
    // Initialize categories from both fields
    _selectedCategories.add(widget.recipe.category);
    _selectedCategories.addAll(widget.recipe.additionalCategories);
    // Remove duplicates if any (though there shouldn't be)
    _selectedCategories = _selectedCategories.toSet().toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlannerProvider>(context);
    final dataManager = Provider.of<DataManager>(context);
    final allCategories = provider.availableCraftingCategories.toList()..sort();

    // Find machines that can craft this category (ANY of selected)
    final compatibleMachines = _findProducers(provider, dataManager, _selectedCategories);

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
              
              // Unified Category Selection
              const Text("Crafting Categories:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: allCategories.map((cat) {
                  final isSelected = _selectedCategories.contains(cat);
                  return FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(cat);
                        } else {
                          _selectedCategories.remove(cat);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              if (allCategories.isEmpty)
                 const Text("No crafting categories available. Add one via Sidebar > Crafting Categories.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              if (_selectedCategories.isEmpty && allCategories.isNotEmpty)
                 const Text("Please select at least one category.", style: TextStyle(color: Colors.orange, fontSize: 10)),

              const SizedBox(height: 8),
              
              if (compatibleMachines.isNotEmpty) ...[
                const Text("Compatible Machines:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: compatibleMachines.map((m) => Tooltip(
                    message: m.name,
                    child: FactorioIcon(itemId: m.id, size: 24),
                  )).toList(),
                ),
              ] else if (_selectedCategories.isNotEmpty) ...[
                 const Text("No machines found for selected categories.", style: TextStyle(color: Colors.orange, fontSize: 12)),
              ],

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

  List<Item> _findProducers(PlannerProvider provider, DataManager dataManager, List<String> categories) {
    if (categories.isEmpty) return [];
    final allItems = [...provider.customItems, ...?dataManager.data?.items];
    return allItems.where((item) {
      if (item.machine?.craftingCategories != null) {
        // Check if machine supports ANY of the categories
        return item.machine!.craftingCategories!.any((c) => categories.contains(c));
      }
      return false;
    }).toList();
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

  void _saveRecipe() {
    if (_nameController.text.isEmpty || _products.isEmpty) return;

    String primaryCategory = 'crafting';
    List<String> additionalCategories = [];

    if (_selectedCategories.isNotEmpty) {
       primaryCategory = _selectedCategories.first;
       if (_selectedCategories.length > 1) {
         additionalCategories = _selectedCategories.sublist(1);
       }
    }

    final updatedRecipe = Recipe(
      id: widget.recipe.id,
      name: _nameController.text,
      category: primaryCategory,
      additionalCategories: additionalCategories,
      row: widget.recipe.row,
      time: double.tryParse(_timeController.text) ?? 1.0,
      ingredients: _ingredients,
      products: _products,
      producers: [], // Deprecated
    );

    final provider = Provider.of<PlannerProvider>(context, listen: false);
    provider.updateCustomRecipe(updatedRecipe);
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

    var allItems = [...provider.customItems, ...?dataManager.data?.items];
    
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
