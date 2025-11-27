// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'factorio_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FactorioData _$FactorioDataFromJson(Map<String, dynamic> json) => FactorioData(
      version: Map<String, String>.from(json['version'] as Map),
      categories: (json['categories'] as List<dynamic>)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
      icons: (json['icons'] as List<dynamic>)
          .map((e) => IconDefinition.fromJson(e as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List<dynamic>)
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList(),
      recipes: (json['recipes'] as List<dynamic>)
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FactorioDataToJson(FactorioData instance) =>
    <String, dynamic>{
      'version': instance.version,
      'categories': instance.categories,
      'icons': instance.icons,
      'items': instance.items,
      'recipes': instance.recipes,
    };
