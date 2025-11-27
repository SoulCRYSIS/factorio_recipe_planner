// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Item _$ItemFromJson(Map<String, dynamic> json) => Item(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      stack: (json['stack'] as num?)?.toInt(),
      row: (json['row'] as num).toInt(),
      iconId: json['iconId'] as String?,
    );

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'stack': instance.stack,
      'row': instance.row,
      'iconId': instance.iconId,
    };
