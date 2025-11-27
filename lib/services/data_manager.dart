import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../models/factorio_data.dart';
import '../models/item.dart';
import '../models/recipe.dart';
import '../models/icon_definition.dart';

class DataManager {
  FactorioData? _data;
  ui.Image? _spritesheet;
  
  FactorioData? get data => _data;
  ui.Image? get spritesheet => _spritesheet;

  bool get isLoaded => _data != null && _spritesheet != null;

  Future<void> loadData() async {
    // Load JSON
    final jsonString = await rootBundle.loadString('assets/data.json');
    final jsonMap = json.decode(jsonString);
    _data = FactorioData.fromJson(jsonMap);

    // Load Image
    final data = await rootBundle.load('assets/icons.webp');
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    _spritesheet = frame.image;
  }

  Item? getItem(String id) {
    try {
      return _data?.items.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }

  Recipe? getRecipe(String id) {
    try {
      return _data?.recipes.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  IconDefinition? getIconDefinition(String id) {
    try {
      return _data?.icons.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }
}

