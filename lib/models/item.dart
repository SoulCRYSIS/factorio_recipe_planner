import 'package:json_annotation/json_annotation.dart';

part 'item.g.dart';

@JsonSerializable()
class MachineDefinition {
  final double speed;
  final int? modules;
  final String? type; // "burner", "electric", etc.
  final List<String>? fuelCategories;
  final List<String>? craftingCategories; // New field
  final double? usage;
  final double? pollution;
  final List<int>? size; // [width, height]
  final Map<String, double>? baseEffect; // { "productivity": 0.5 }
  final String? entityType;

  MachineDefinition({
    required this.speed,
    this.modules,
    this.type,
    this.fuelCategories,
    this.craftingCategories,
    this.usage,
    this.pollution,
    this.size,
    this.baseEffect,
    this.entityType,
  });

  factory MachineDefinition.fromJson(Map<String, dynamic> json) => _$MachineDefinitionFromJson(json);
  Map<String, dynamic> toJson() => _$MachineDefinitionToJson(this);
}

@JsonSerializable()
class Item {
  final String id;
  final String name;
  final String category;
  final int? stack; // Stack can be null for some items/fluids
  final int row;
  final String? iconId; // For custom items to point to an existing icon
  final String? imageBase64; // For custom items with uploaded image
  final MachineDefinition? machine;

  Item({
    required this.id,
    required this.name,
    required this.category,
    this.stack,
    required this.row,
    this.iconId,
    this.imageBase64,
    this.machine,
  });

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
  Map<String, dynamic> toJson() => _$ItemToJson(this);
}
