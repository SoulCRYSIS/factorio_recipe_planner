import 'package:json_annotation/json_annotation.dart';

part 'icon_definition.g.dart';

@JsonSerializable()
class IconDefinition {
  final String id;
  final String position; // "0px 0px"
  final String color;

  IconDefinition({required this.id, required this.position, required this.color});

  factory IconDefinition.fromJson(Map<String, dynamic> json) => _$IconDefinitionFromJson(json);
  Map<String, dynamic> toJson() => _$IconDefinitionToJson(this);

  // Helper to parse position string "-66px -132px". 
  // Note: The value in JSON is negative offset, so to get positive coordinate we multiply by -1.
  // Actually, usually CSS sprites use negative background-position. 
  // If the JSON says "-66px", it means the sprite starts at 66px in the image.
  // So I should take the absolute value.
  double get x => double.parse(position.split(' ')[0].replaceAll('px', '')).abs();
  double get y => double.parse(position.split(' ')[1].replaceAll('px', '')).abs();
}

