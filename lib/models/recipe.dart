import 'package:json_annotation/json_annotation.dart';

part 'recipe.g.dart';

@JsonSerializable()
class Recipe {
  final String id;
  final String name;
  final String category;
  
  @JsonKey(defaultValue: [])
  final List<String> additionalCategories;
  
  final int row;
  final double time;
  
  @JsonKey(name: 'in', defaultValue: {})
  final Map<String, num> ingredients;
  
  @JsonKey(name: 'out', defaultValue: {})
  final Map<String, num> products;
  
  @JsonKey(defaultValue: [])
  final List<String> producers;

  // Use num for amounts because they can be int or double (e.g. 0.5)

  Recipe({
    required this.id,
    required this.name,
    required this.category,
    this.additionalCategories = const [],
    required this.row,
    required this.time,
    required this.ingredients,
    required this.products,
    required this.producers,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
  Map<String, dynamic> toJson() => _$RecipeToJson(this);
}
