import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:graphview/GraphView.dart';
import '../providers/planner_provider.dart';
import '../models/node_data.dart';
import '../widgets/recipe_node.dart';
import '../widgets/sidebar.dart';
import '../services/lua_export_service.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Factorio Recipe Planner"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<PlannerProvider>(context, listen: false).refreshLayout();
            },
            tooltip: "Refresh Graph",
          ),
          PopupMenuButton<LayeringStrategy>(
            icon: const Icon(Icons.layers),
            tooltip: "Layering Strategy",
            onSelected: (strategy) {
              Provider.of<PlannerProvider>(context, listen: false).setLayeringStrategy(strategy);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: LayeringStrategy.longestPath, child: Text("Longest Path")),
              PopupMenuItem(value: LayeringStrategy.coffmanGraham, child: Text("Coffman Graham")),
              PopupMenuItem(value: LayeringStrategy.networkSimplex, child: Text("Network Simplex")),
              PopupMenuItem(value: LayeringStrategy.topDown, child: Text("Top Down")),
            ],
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.rotate_90_degrees_ccw),
            tooltip: "Orientation",
            onSelected: (orientation) {
              Provider.of<PlannerProvider>(context, listen: false).setOrientation(orientation);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM, child: Text("Top -> Bottom")),
              const PopupMenuItem(value: SugiyamaConfiguration.ORIENTATION_BOTTOM_TOP, child: Text("Bottom -> Top")),
              const PopupMenuItem(value: SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT, child: Text("Left -> Right")),
              const PopupMenuItem(value: SugiyamaConfiguration.ORIENTATION_RIGHT_LEFT, child: Text("Right -> Left")),
            ],
          ),
          
          // Code Export Menu
          PopupMenuButton<LuaExportType>(
            icon: const Icon(Icons.code),
            tooltip: "Copy Game Code",
            onSelected: (type) => LuaExportService.copyExportToClipboard(context, type),
            itemBuilder: (context) => const [
              PopupMenuItem(value: LuaExportType.machineItems, child: Text("Copy Machine Items")),
              PopupMenuItem(value: LuaExportType.machineRecipes, child: Text("Copy Machine Recipes")),
              PopupMenuItem(value: LuaExportType.machineEntities, child: Text("Copy Machine Entities")),
              PopupMenuDivider(),
              PopupMenuItem(value: LuaExportType.otherItems, child: Text("Copy Other Items")),
              PopupMenuItem(value: LuaExportType.otherItemRecipes, child: Text("Copy Other Item Recipes")),
            ],
          ),

          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _export(context),
            tooltip: "Export JSON",
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _import(context),
            tooltip: "Import JSON",
          ),
        ],
      ),
      body: Row(
        children: [
          // Canvas Area
          Expanded(
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
                
                return GraphView.builder(
                  graph: provider.graph,
                  animated: false,
                  autoZoomToFit: true,
                  centerGraph: true,
                  algorithm: SugiyamaAlgorithm(provider.builder),
                  paint: Paint()
                    ..color = Colors.grey.shade400
                    ..strokeWidth = 2
                    ..style = PaintingStyle.stroke,
                  builder: (Node node) {
                    final data = node.key!.value as NodeData;
                    return RecipeNode(
                      nodeData: data,
                    );
                  },
                );
              },
            ),
          ),
          
          const SizedBox(
            width: 280,
            child: Sidebar(),
          ),
        ],
      ),
    );
  }

  void _export(BuildContext context) {
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

  void _import(BuildContext context) {
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
