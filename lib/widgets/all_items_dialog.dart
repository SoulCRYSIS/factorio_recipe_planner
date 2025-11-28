import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../providers/planner_provider.dart';
import 'factorio_icon.dart';
import 'edit_custom_item_dialog.dart';

class AllItemsDialog extends StatefulWidget {
  const AllItemsDialog({super.key});

  @override
  State<AllItemsDialog> createState() => _AllItemsDialogState();
}

class _AllItemsDialogState extends State<AllItemsDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    final plannerProvider = Provider.of<PlannerProvider>(context);
    
    // Combine all items
    final baseItems = dataManager.data?.items ?? [];
    final customItems = plannerProvider.customItems;
    final allItems = [...customItems, ...baseItems];

    // Filter
    final filteredItems = _searchQuery.isEmpty
        ? allItems
        : allItems.where((i) => i.name.toLowerCase().contains(_searchQuery)).toList();

    return AlertDialog(
      title: const Text("All Items List"),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: "Search Items",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(child: Text("No items found"))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 100,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (ctx, i) {
                        final item = filteredItems[i];
                        final isCustom = customItems.contains(item);

                        return Stack(
                          children: [
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: isCustom ? () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => EditCustomItemDialog(item: item),
                                  );
                                } : null, // Do nothing for base items or maybe show info?
                                child: Card(
                                  color: isCustom ? Colors.purple.shade50 : null,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        FactorioIcon(itemId: item.id, size: 48),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.name,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 10, fontWeight: isCustom ? FontWeight.bold : null),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (isCustom)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 12),
                                  onPressed: () {
                                    _confirmDelete(context, plannerProvider, item.id, item.name);
                                  },
                                ),
                              ),
                          ],
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

  void _confirmDelete(BuildContext context, PlannerProvider provider, String itemId, String itemName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete $itemName?"),
        content: const Text("This cannot be undone. Items used in recipes may show as missing."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              provider.deleteCustomItem(itemId);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
