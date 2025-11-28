import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../providers/planner_provider.dart';

class FactorioIcon extends StatelessWidget {
  final String itemId;
  final double size;

  const FactorioIcon({super.key, required this.itemId, this.size = 32.0});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context);
    // We use listen: false because we assume item definitions don't change rapidly, 
    // but if we want to support editing custom items, we might need listen: true.
    // Let's stick to default (listen: true) for safety.
    final plannerProvider = Provider.of<PlannerProvider>(context);
    
    if (!dataManager.isLoaded) {
      return SizedBox(width: size, height: size, child: const Padding(
        padding: EdgeInsets.all(4.0),
        child: CircularProgressIndicator(strokeWidth: 2),
      ));
    }

    // Resolve effective icon ID
    String effectiveIconId = itemId;
    
    // Check custom items
    try {
      final customItem = plannerProvider.customItems.firstWhere((i) => i.id == itemId);
      
      if (customItem.imageBase64 != null) {
         return Image.memory(
           base64Decode(customItem.imageBase64!),
           width: size,
           height: size,
           fit: BoxFit.contain,
         );
      }

      if (customItem.iconId != null) {
        effectiveIconId = customItem.iconId!;
      }
    } catch (_) {
      // Not a custom item, or not found in custom list
    }

    final iconDef = dataManager.getIconDefinition(effectiveIconId);
    if (iconDef == null) {
      // Check if it is a custom item in the future
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(Icons.question_mark, size: size * 0.8, color: Colors.grey[700]),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SpritePainter(
          image: dataManager.spritesheet!,
          x: iconDef.x,
          y: iconDef.y,
        ),
      ),
    );
  }
}

class _SpritePainter extends CustomPainter {
  final ui.Image image;
  final double x;
  final double y;

  _SpritePainter({required this.image, required this.x, required this.y});

  @override
  void paint(Canvas canvas, Size size) {
    // Assuming 64x64 size based on observation of 66px grid stride.
    const double spriteSize = 64.0;
    
    final src = Rect.fromLTWH(x, y, spriteSize, spriteSize);
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Use filterQuality: FilterQuality.medium for better downscaling
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(_SpritePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.x != x || oldDelegate.y != y;
  }
}
