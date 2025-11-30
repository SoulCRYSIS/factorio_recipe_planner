import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:factorio_recipe_planner/providers/planner_provider.dart';
import 'package:factorio_recipe_planner/models/node_data.dart';
import 'package:factorio_recipe_planner/models/recipe.dart';
import 'package:factorio_recipe_planner/models/item.dart';

enum LuaExportType {
  machineItems,
  machineRecipes,
  machineEntities,
  otherItems,
  otherItemRecipes
}

class LuaExportService {
  static void copyExportToClipboard(BuildContext context, LuaExportType type) {
    final code = _generateCode(context, type);

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Nothing to export for this category (no active custom nodes found).")),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Copied ${type.name} to clipboard!")),
    );
  }

  static String _generateCode(BuildContext context, LuaExportType type) {
    final provider = Provider.of<PlannerProvider>(context, listen: false);
    final nodes = provider.nodes;

    // Helper to get formatted item name
    String getItemName(String id) {
      final name = provider.getItemName(id);
      return _formatName(name);
    }

    // Collect used custom recipes and items
    final Set<String> usedCustomRecipeIds = {};
    final Set<String> usedCustomItemIds = {};

    for (final node in nodes) {
      final data = node.key!.value as NodeData;
      if (data.isCustom) {
        usedCustomRecipeIds.add(data.recipe.id);

        data.recipe.ingredients.keys.forEach((itemId) {
          if (_isCustomItem(provider, itemId)) usedCustomItemIds.add(itemId);
        });
        data.recipe.products.keys.forEach((itemId) {
          if (_isCustomItem(provider, itemId)) usedCustomItemIds.add(itemId);
        });
      }
    }

    final customRecipesToExport = provider.customRecipes
        .where((r) => usedCustomRecipeIds.contains(r.id))
        .toList();

    final customItemsToExport = provider.customItems
        .where((i) => usedCustomItemIds.contains(i.id))
        .toList();

    final machineItems =
        customItemsToExport.where((i) => i.machine != null).toList();

    final machineRecipes = customRecipesToExport.where((r) {
      return r.products.keys
          .any((prodId) => machineItems.any((m) => m.id == prodId));
    }).toList();

    final buffer = StringBuffer();

    switch (type) {
      case LuaExportType.machineItems:
        if (machineItems.isNotEmpty) {
          for (var item in machineItems) {
            buffer.writeln(_generateMachineItem(item));
          }
        }
        break;
      case LuaExportType.machineRecipes:
        if (machineRecipes.isNotEmpty) {
          for (var recipe in machineRecipes) {
            buffer.writeln(
                _generateRecipe(recipe, getItemName, isMachineRecipe: true));
          }
        }
        break;
      case LuaExportType.machineEntities:
        if (machineItems.isNotEmpty) {
          for (var item in machineItems) {
            buffer.writeln(_generateMachineEntity(item));
          }
        }
        break;
      case LuaExportType.otherItems:
        final otherItems =
            customItemsToExport.where((i) => i.machine == null).toList();
        if (otherItems.isNotEmpty) {
          for (var item in otherItems) {
            buffer.writeln(_generateOtherItem(item));
          }
        }
        break;
      case LuaExportType.otherItemRecipes:
        final otherRecipes = customRecipesToExport
            .where((r) => !machineRecipes.contains(r))
            .toList();
        if (otherRecipes.isNotEmpty) {
          for (var recipe in otherRecipes) {
            buffer.writeln(
                _generateRecipe(recipe, getItemName, isMachineRecipe: false));
          }
        }
        break;
    }

    return buffer.toString();
  }

  static bool _isCustomItem(PlannerProvider provider, String id) {
    return provider.customItems.any((i) => i.id == id);
  }

  static String _formatName(String name) {
    return name.toLowerCase().replaceAll(' ', '-');
  }

  static String _generateMachineItem(Item item) {
    final name = _formatName(item.name);
    return '''
    {
      type = "item",
      name = "$name",
      place_result = "$name",
      icon = "__virentis__/graphics/icons/machines/$name.png",
      subgroup = "virentis-machines",
      order = "a",
      inventory_move_sound = item_sounds.mechanical_large_inventory_move,
      pick_sound = item_sounds.mechanical_large_inventory_pickup,
      drop_sound = item_sounds.mechanical_large_inventory_move,
      stack_size = ${item.stack ?? 10},
      default_import_location = "virentis",
      weight = 100 * kg,
    },''';
  }

  static String _generateMachineEntity(Item item) {
    final name = _formatName(item.name);
    final def = item.machine!;

    final craftingCategories =
        def.craftingCategories?.map((c) => '"$c"').join(', ') ?? "";
    final energyUsage = "${def.usage ?? 500}kW";
    final craftingSpeed = def.speed;
    final type = def.entityType ?? "assembling-machine";

    String energySource = "";
    if (def.type == 'burner') {
      final cats = def.fuelCategories?.map((c) => '"$c"').join(', ') ?? "";
      energySource = '''
    energy_source = {
      type = "burner",
      fuel_categories = { $cats },
      effectivity = 1,
      fuel_inventory_size = 1,
      emissions_per_minute = ${def.pollution ?? 0},
    },''';
    } else if (def.type == 'electric') {
      energySource = '''
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
    },''';
    } else {
      energySource = '''
    energy_source = {
      type = "void",
    },''';
    }

    return '''
    {
    type = "$type",
    name = "$name",
    icon = "__virentis__/graphics/icons/machines/$name.png",
    subgroup = "virentis-machines",
    order = "a",
    flags = { "placeable-neutral", "placeable-player", "player-creation" },
    circuit_wire_max_distance = base_assembling_machine.circuit_wire_max_distance,
    circuit_connector = base_assembling_machine.circuit_connector,
    energy_usage = "$energyUsage",
    $energySource
    crafting_categories = { $craftingCategories },
    crafting_speed = $craftingSpeed,
    module_slots = ${def.modules ?? 0},
    minable = {
      mining_time = 1,
      result = "$name",
    },
    collision_box = { { -1.3, -1.3 }, { 1.3, 1.3 } },
    selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } },
    damaged_trigger_effect = hit_effects.entity(),
    max_health = 500,
    dying_explosion = "steel-furnace-explosion",
    graphics_set = {
      animation = {
        layers = {
          {
            filename = "__virentis__/graphics/entities/machines/$name/$name.png",
            priority = "very-low",
            width = 380,
            height = 280,
            shift = util.by_pixel(0, 0),
            scale = 0.5,
          },
          {
            filename = "__virentis__/graphics/entities/machines/$name/$name-shadow.png",
            priority = "very-low",
            width = 380,
            height = 280,
            draw_as_shadow = true,
            shift = util.by_pixel(0, 0),
            scale = 0.5,
          },
        },
      },
      working_visualisations = {
        {
          fadeout = true,
          apply_recipe_tint = "primary",
          animation = {
            filename = "__virentis__/graphics/entities/machines/$name/$name-glow.png",
            priority = "very-low",
            width = 380,
            height = 280,
            frame_count = 16,
            line_length = 4,
            draw_as_glow = true,
            blend_mode = "additive",
            shift = util.by_pixel(0, 0),
            scale = 0.5,
            animation_speed = 0.1,
          },
        },
      },
    },
    open_sound = sounds.machine_open,
    close_sound = sounds.machine_close,
    effect_receiver = { base_effect = { productivity = ${def.baseEffect?['productivity'] ?? 0} } },
    impact_category = "metal",
    working_sound =
    {
      sound = { filename = "__base__/sound/assembling-machine-t1-1.ogg", volume = 0.45, audible_distance_modifier = 0.5 },
      fade_in_ticks = 4,
      fade_out_ticks = 20
    }
  },''';
  }

  static String _generateOtherItem(Item item) {
    final name = _formatName(item.name);
    return '''
    {
      type = "item",
      name = "$name",
      icon = "__virentis__/graphics/icons/items/foods/$name.png",
      subgroup = "virentis-foods",
      order = "a",
      spoil_ticks = 5 * minute,
      spoil_result = "spoilage",
      stack_size = ${item.stack ?? 50},
      weight = 5 * kg,
    },''';
  }

  static String _generateRecipe(Recipe recipe, String Function(String) getName,
      {required bool isMachineRecipe}) {
    final name = _formatName(recipe.name);

    final ingredients = recipe.ingredients.entries.map((e) {
      final type = "item";
      final iName = getName(e.key);
      return '{ type = "$type", name = "$iName", amount = ${e.value} }';
    }).join(',\n        ');

    final results = recipe.products.entries.map((e) {
      final type = "item";
      final pName = getName(e.key);
      return '{ type = "$type", name = "$pName", amount = ${e.value} }';
    }).join(',\n        ');

    final additionalCategories = recipe.additionalCategories.isNotEmpty
        ? 'additional_categories = { ${recipe.additionalCategories.map((c) => '"$c"').join(', ')} },'
        : '';

    return '''
    {
      type = "recipe",
      name = "$name",
      category = "${recipe.category}",
      $additionalCategories
      order = "a",
      icon = "__virentis__/graphics/icons/items/foods/$name.png",
      ingredients = {
        $ingredients
      },
      results = {
        $results
      },
      crafting_machine_tint = recipe_tints.red, 
      energy_required = ${recipe.time},
      ${isMachineRecipe ? 'enabled = false,' : 'result_is_always_fresh = true,'}
      ${isMachineRecipe ? 'surface_conditions = virentis_surface,' : ''}
    },''';
  }
}
