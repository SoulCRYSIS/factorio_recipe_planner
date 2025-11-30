import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart'; // For XFile
import 'dart:convert';
import '../providers/planner_provider.dart';
import '../models/item.dart';

class AddCustomItemDialog extends StatefulWidget {
  const AddCustomItemDialog({super.key});

  @override
  State<AddCustomItemDialog> createState() => _AddCustomItemDialogState();
}

class _AddCustomItemDialogState extends State<AddCustomItemDialog> {
  final _nameController = TextEditingController();
  String? _imageBase64;
  bool _isLoadingImage = false;
  bool _isDragging = false;
  bool _cropMipmap = true;

  // Machine Properties
  bool _isMachine = false;
  final _speedController = TextEditingController(text: "1.0");
  final _productivityController = TextEditingController(text: "0"); // Percent
  final _usageController = TextEditingController();
  final _pollutionController = TextEditingController();
  
  String _machineType = "electric";
  final List<String> _machineTypes = ["electric", "burner"];
  
  final List<String> _selectedFuelCategories = [];
  final List<String> _selectedCraftingCategories = [];

  @override
  void dispose() {
    _nameController.dispose();
    _speedController.dispose();
    _productivityController.dispose();
    _usageController.dispose();
    _pollutionController.dispose();
    super.dispose();
  }

  Future<void> _processFile(XFile file) async {
    setState(() => _isLoadingImage = true);
    try {
      final bytes = await file.readAsBytes();
      
      final img.Image? original = img.decodeImage(bytes);
      if (original != null) {
        img.Image processed;
        
        if (_cropMipmap && original.width >= 64 && original.height >= 64) {
          // Crop top-left 64x64
          processed = img.copyCrop(original, x: 0, y: 0, width: 64, height: 64);
        } else {
          // Resize to 64x64
          processed = img.copyResize(original, width: 64, height: 64);
        }
        
        final pngBytes = img.encodePng(processed);
        
        setState(() {
          _imageBase64 = base64Encode(pngBytes);
        });
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
    } finally {
      setState(() => _isLoadingImage = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _processFile(image);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlannerProvider>(context);
    final availableFuelCategories = provider.availableFuelCategories.toList()..sort();
    final availableCraftingCategories = provider.availableCraftingCategories.toList()..sort();

    return AlertDialog(
      title: const Text("New Custom Item"),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Item Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              
              // Image Upload Section
              // Mipmap Toggle
              Row(
                children: [
                  Checkbox(
                    value: _cropMipmap, 
                    onChanged: (val) => setState(() => _cropMipmap = val ?? false)
                  ),
                  const Flexible(
                    child: Text(
                      "Crop Top-Left 64x64 (Mipmap mode)", 
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
      
              if (_imageBase64 != null)
                 Column(
                   children: [
                     Container(
                       decoration: BoxDecoration(
                         border: Border.all(color: Colors.grey),
                         borderRadius: BorderRadius.circular(4),
                       ),
                       padding: const EdgeInsets.all(8),
                       child: Image.memory(
                         base64Decode(_imageBase64!),
                         width: 64,
                         height: 64,
                         fit: BoxFit.contain,
                       ),
                     ),
                     TextButton(
                       onPressed: () => setState(() => _imageBase64 = null), 
                       child: const Text("Remove Icon", style: TextStyle(color: Colors.red))
                     )
                   ],
                 )
              else
                 DropTarget(
                   onDragDone: (detail) {
                     if (detail.files.isNotEmpty) {
                       _processFile(detail.files.first);
                     }
                   },
                   onDragEntered: (detail) => setState(() => _isDragging = true),
                   onDragExited: (detail) => setState(() => _isDragging = false),
                   child: GestureDetector(
                     onTap: _isLoadingImage ? null : _pickImage,
                     child: Container(
                       height: 100,
                       alignment: Alignment.center,
                       decoration: BoxDecoration(
                         color: _isDragging ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
                         border: Border.all(
                           color: _isDragging ? Colors.blue : Colors.grey[400]!,
                           width: 2,
                           style: BorderStyle.solid,
                         ),
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: _isLoadingImage 
                         ? const CircularProgressIndicator()
                         : Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: const [
                               Icon(Icons.cloud_upload, size: 32, color: Colors.grey),
                               SizedBox(height: 8),
                               Text("Drag & Drop Icon", style: TextStyle(color: Colors.grey)),
                             ],
                           ),
                     ),
                   ),
                 ),
                 
              const SizedBox(height: 16),
              const Divider(),
              
              // Machine Toggle
              SwitchListTile(
                title: const Text("Is this a Machine?"),
                value: _isMachine,
                onChanged: (val) => setState(() => _isMachine = val),
              ),
              
              if (_isMachine) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _speedController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Speed", border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _productivityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Productivity %", border: OutlineInputBorder(), suffixText: "%"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _machineType,
                  decoration: const InputDecoration(labelText: "Energy Type", border: OutlineInputBorder()),
                  items: _machineTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                  onChanged: (val) => setState(() => _machineType = val!),
                ),
                const SizedBox(height: 8),

                // Crafting Categories
                const Text("Crafting Categories:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: availableCraftingCategories.map((cat) {
                    final isSelected = _selectedCraftingCategories.contains(cat);
                    return FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCraftingCategories.add(cat);
                          } else {
                            _selectedCraftingCategories.remove(cat);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (availableCraftingCategories.isEmpty)
                   const Text("No crafting categories available. Add one via Sidebar > Crafting Categories.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                
                const SizedBox(height: 8),
                
                if (_machineType == 'burner') ...[
                  const Text("Fuel Categories:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: availableFuelCategories.map((cat) {
                      final isSelected = _selectedFuelCategories.contains(cat);
                      return FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedFuelCategories.add(cat);
                            } else {
                              _selectedFuelCategories.remove(cat);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  if (availableFuelCategories.isEmpty)
                    const Text("No fuel categories available. Add one via settings/menu.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
                
                const SizedBox(height: 8),
                Row(
                  children: [
                     Expanded(
                      child: TextField(
                        controller: _usageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Usage (kW)", border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _pollutionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Pollution/m", border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              
              MachineDefinition? machineDef;
              if (_isMachine) {
                 final productivity = (double.tryParse(_productivityController.text) ?? 0) / 100.0;
                 machineDef = MachineDefinition(
                   speed: double.tryParse(_speedController.text) ?? 1.0,
                   type: _machineType,
                   fuelCategories: _machineType == 'burner' ? _selectedFuelCategories : null,
                   craftingCategories: _selectedCraftingCategories,
                   usage: double.tryParse(_usageController.text),
                   pollution: double.tryParse(_pollutionController.text),
                   baseEffect: productivity > 0 ? {'productivity': productivity} : null,
                   entityType: 'assembling-machine', // Default
                 );
              }

              final newItem = Item(
                id: const Uuid().v4(),
                name: _nameController.text,
                category: 'custom',
                row: 0,
                imageBase64: _imageBase64,
                machine: machineDef,
              );
              Provider.of<PlannerProvider>(context, listen: false).addCustomItem(newItem);
              Navigator.pop(context, newItem);
            }
          },
          child: const Text("Create"),
        ),
      ],
    );
  }
}
