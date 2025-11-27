import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/planner_provider.dart';
import '../services/data_manager.dart';
import '../models/item.dart';
import 'factorio_icon.dart';

class AddCustomItemDialog extends StatefulWidget {
  const AddCustomItemDialog({super.key});

  @override
  State<AddCustomItemDialog> createState() => _AddCustomItemDialogState();
}

class _AddCustomItemDialogState extends State<AddCustomItemDialog> {
  final _nameController = TextEditingController();
  String? _selectedIconId;
  
  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    // Just take first 200 for now to avoid lag
    final icons = dataManager.data?.items.take(200).toList() ?? []; 
    
    return AlertDialog(
      title: const Text("New Custom Item"),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Item Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text("Select Icon (Top 200):"),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6, 
                  crossAxisSpacing: 4, 
                  mainAxisSpacing: 4
                ),
                itemCount: icons.length,
                itemBuilder: (ctx, i) {
                  final item = icons[i];
                  return InkWell(
                    onTap: () => setState(() => _selectedIconId = item.id),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: _selectedIconId == item.id 
                          ? BoxDecoration(
                              border: Border.all(color: Colors.orange, width: 2),
                              borderRadius: BorderRadius.circular(4),
                            ) 
                          : null,
                      child: FactorioIcon(itemId: item.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              final newItem = Item(
                id: const Uuid().v4(),
                name: _nameController.text,
                category: 'custom',
                row: 0,
                iconId: _selectedIconId,
              );
              Provider.of<PlannerProvider>(context, listen: false).addCustomItem(newItem);
              Navigator.pop(context);
            }
          },
          child: const Text("Create"),
        ),
      ],
    );
  }
}

