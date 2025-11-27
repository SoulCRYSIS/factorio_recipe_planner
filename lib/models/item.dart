import 'package:json_annotation/json_annotation.dart';

part 'item.g.dart';

@JsonSerializable()
class Item {
  final String id;
  final String name;
  final String category;
  final int? stack; // Stack can be null for some items/fluids
  final int row;
  final String? iconId; // For custom items to point to an existing icon

  Item({
    required this.id,
    required this.name,
    required this.category,
    this.stack,
    required this.row,
    this.iconId,
  });

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
  Map<String, dynamic> toJson() => _$ItemToJson(this);
}

