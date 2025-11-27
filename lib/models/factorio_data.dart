import 'package:json_annotation/json_annotation.dart';
import 'category.dart';
import 'icon_definition.dart';
import 'item.dart';
import 'recipe.dart';

part 'factorio_data.g.dart';

@JsonSerializable()
class FactorioData {
  final Map<String, String> version;
  final List<Category> categories;
  final List<IconDefinition> icons;
  final List<Item> items;
  final List<Recipe> recipes;

  FactorioData({
    required this.version,
    required this.categories,
    required this.icons,
    required this.items,
    required this.recipes,
  });

  factory FactorioData.fromJson(Map<String, dynamic> json) => _$FactorioDataFromJson(json);
  Map<String, dynamic> toJson() => _$FactorioDataToJson(this);
}

