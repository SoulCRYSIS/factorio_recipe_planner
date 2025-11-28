// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MachineDefinition _$MachineDefinitionFromJson(Map<String, dynamic> json) =>
    MachineDefinition(
      speed: (json['speed'] as num).toDouble(),
      modules: (json['modules'] as num?)?.toInt(),
      type: json['type'] as String?,
      fuelCategories: (json['fuelCategories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      usage: (json['usage'] as num?)?.toDouble(),
      pollution: (json['pollution'] as num?)?.toDouble(),
      size: (json['size'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      baseEffect: (json['baseEffect'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      entityType: json['entityType'] as String?,
    );

Map<String, dynamic> _$MachineDefinitionToJson(MachineDefinition instance) =>
    <String, dynamic>{
      'speed': instance.speed,
      'modules': instance.modules,
      'type': instance.type,
      'fuelCategories': instance.fuelCategories,
      'usage': instance.usage,
      'pollution': instance.pollution,
      'size': instance.size,
      'baseEffect': instance.baseEffect,
      'entityType': instance.entityType,
    };

Item _$ItemFromJson(Map<String, dynamic> json) => Item(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      stack: (json['stack'] as num?)?.toInt(),
      row: (json['row'] as num).toInt(),
      iconId: json['iconId'] as String?,
      imageBase64: json['imageBase64'] as String?,
      machine: json['machine'] == null
          ? null
          : MachineDefinition.fromJson(json['machine'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'stack': instance.stack,
      'row': instance.row,
      'iconId': instance.iconId,
      'imageBase64': instance.imageBase64,
      'machine': instance.machine,
    };
