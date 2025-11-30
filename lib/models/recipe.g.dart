// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Recipe _$RecipeFromJson(Map<String, dynamic> json) => Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      additionalCategories: (json['additionalCategories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      row: (json['row'] as num).toInt(),
      time: (json['time'] as num).toDouble(),
      ingredients: (json['in'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as num),
          ) ??
          {},
      products: (json['out'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as num),
          ) ??
          {},
      producers: (json['producers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$RecipeToJson(Recipe instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'additionalCategories': instance.additionalCategories,
      'row': instance.row,
      'time': instance.time,
      'in': instance.ingredients,
      'out': instance.products,
      'producers': instance.producers,
    };
