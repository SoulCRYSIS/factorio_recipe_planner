import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:graphview/GraphView.dart';
import '../providers/planner_provider.dart';
import '../models/node_data.dart';
import '../services/data_manager.dart';
import '../widgets/recipe_node.dart';
import '../widgets/sidebar.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final _graphKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Factorio Recipe Planner"),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () {
              // Force re-center by replacing the graphview key or similar?
              // GraphView doesn't have an easy "center" method exposed on the controller yet.
              // But we can clear and re-add (heavy) or just notify listeners to refresh layout?
              // Let's try simply notifying the provider which triggers rebuild.
              // This re-runs the layout algorithm.
              Provider.of<PlannerProvider>(context, listen: false).refreshLayout();
            },
            tooltip: "Recenter Layout",
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _export,
            tooltip: "Export JSON",
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _import,
            tooltip: "Import JSON",
          ),
        ],
      ),
      body: Row(
        children: [
          // Canvas Area
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: Consumer<PlannerProvider>(
                builder: (context, provider, child) {
                  if (provider.nodes.isEmpty) {
                    return const Center(
                      child: Text(
                        "Add a recipe from the sidebar to start",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }
                  
                  return InteractiveViewer(
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(1000),
                    minScale: 0.1,
                    maxScale: 5.0,
                    child: GraphView(
                      key: _graphKey,
                      graph: provider.graph,
                      toggleAnimationDuration: Duration.zero,
                      algorithm: SugiyamaAlgorithm(provider.builder),
                      paint: Paint()
                        ..color = Colors.grey.shade400
                        ..strokeWidth = 2
                        ..style = PaintingStyle.stroke,
                      builder: (Node node) {
                        final data = node.key!.value as NodeData;
                        return RecipeNode(
                          nodeData: data,
                          onTap: () => _confirmDelete(context, node, data),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Sidebar Area
          const VerticalDivider(width: 1),
          const SizedBox(
            width: 320,
            child: Sidebar(),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Node node, NodeData data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Remove ${data.recipe.name}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Provider.of<PlannerProvider>(context, listen: false).removeNode(node);
              Navigator.pop(ctx);
            },
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _export() {
    final json = Provider.of<PlannerProvider>(context, listen: false).exportToJson();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Export JSON"),
        content: SelectableText(json),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  void _import() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Import JSON"),
        content: TextField(
          controller: controller,
          maxLines: 10,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              try {
                Provider.of<PlannerProvider>(context, listen: false).importFromJson(controller.text);
                Navigator.pop(ctx);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Import"),
          ),
        ],
      ),
    );
  }
}

class _AddBaseRecipeDialog extends StatefulWidget {
  @override
  State<_AddBaseRecipeDialog> createState() => _AddBaseRecipeDialogState();
}

class _AddBaseRecipeDialogState extends State<_AddBaseRecipeDialog> {
  final _searchController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context, listen: false);
    // Filter recipes based on search
    final recipes = dataManager.data?.recipes ?? [];
    
    // Simple efficient filtering for display
    final filtered = _searchController.text.isEmpty 
      ? recipes.take(100).toList() 
      : recipes.where((r) => r.name.toLowerCase().contains(_searchController.text.toLowerCase())).take(100).toList();

    return AlertDialog(
      title: const Text("Add Base Recipe"),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search recipes...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final recipe = filtered[i];
                  return ListTile(
                    title: Text(recipe.name),
                    subtitle: Text(recipe.category),
                    onTap: () {
                      Provider.of<PlannerProvider>(context, listen: false).addRecipeNode(recipe);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
      ],
    );
  }
}



