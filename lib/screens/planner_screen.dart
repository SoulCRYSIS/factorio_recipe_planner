import 'package:factorio_recipe_planner/widgets/recipe_node.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:graphview/GraphView.dart';
import '../providers/planner_provider.dart';
import '../models/node_data.dart';
import '../widgets/sidebar.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Factorio Recipe Planner"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              Provider.of<PlannerProvider>(context, listen: false).clearBoard();
            },
            tooltip: "Clear Board",
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'load_all') {
                _confirmLoadAll(context);
              } else if (value == 'clear') {
                 Provider.of<PlannerProvider>(context, listen: false).clearBoard();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'load_all',
                  child: Text('Load All Base Recipes'),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Text('Clear Board'),
                ),
              ];
            },
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
                    minScale: 0.01,
                    maxScale: 5.0,
                    child: GraphView(
                      graph: provider.graph,
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

  void _confirmLoadAll(BuildContext context) {
     showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Load All Recipes?"),
        content: const Text("This will load 1000+ recipes. It may take a few seconds and lag the browser."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Show a loading indicator or snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Loading recipes... please wait."))
              );
              
              // Use Future.delayed to allow snackbar to show
              Future.delayed(const Duration(milliseconds: 100), () {
                 Provider.of<PlannerProvider>(context, listen: false).populateAllRecipes();
              });
            },
            child: const Text("Load All"),
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


