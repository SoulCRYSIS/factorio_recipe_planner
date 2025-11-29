import 'recipe.dart';

class NodeData {
  final String id; // Unique instance ID (UUID)
  Recipe recipe;
  final bool isCustom;

  NodeData({required this.id, required this.recipe, this.isCustom = false});
  
  @override
  bool operator ==(Object other) => other is NodeData && other.id == id;
  
  @override
  int get hashCode => id.hashCode;
}
