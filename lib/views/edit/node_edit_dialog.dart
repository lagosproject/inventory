import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/inventory_node.dart';
import '../../services/image_storage_service.dart';
import '../../services/inventory_storage_service.dart';
import '../../theme/app_theme.dart';
import '../common/figma_components.dart';

class NodeEditDialog extends StatefulWidget {
  final InventoryNode? nodeToEdit;
  final String? defaultParentId;
  final NodeType defaultType;

  const NodeEditDialog({
    super.key,
    this.nodeToEdit,
    this.defaultParentId,
    this.defaultType = NodeType.storage,
  });

  static Future<bool?> show(
    BuildContext context, {
    InventoryNode? nodeToEdit,
    String? defaultParentId,
    NodeType defaultType = NodeType.storage,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: NodeEditDialog(
          nodeToEdit: nodeToEdit,
          defaultParentId: defaultParentId,
          defaultType: defaultType,
        ),
      ),
    );
  }

  @override
  State<NodeEditDialog> createState() => _NodeEditDialogState();
}

class _NodeEditDialogState extends State<NodeEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = InventoryStorageService();
  final _imageService = ImageStorageService();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late NodeType _selectedType;
  late int _quantity;
  String? _selectedParentId;
  String? _imagePath;
  List<Map<String, String>> _storageOptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final node = widget.nodeToEdit;
    _nameController = TextEditingController(text: node?.name ?? '');
    _descController = TextEditingController(text: node?.description ?? '');
    _selectedType = node?.type ?? widget.defaultType;
    _quantity = node?.quantity ?? 1;
    _selectedParentId = node?.parentId ?? widget.defaultParentId;
    _imagePath = node?.imagePath;
    _loadStorageOptions();
  }

  Future<void> _pickImage() async {
    await showImagePickerSheet(
      context,
      hasExistingImage: _imagePath != null && _imagePath!.isNotEmpty,
      onSelectSource: (source) async {
        final savedPath = await _imageService.pickAndSaveImage(source: source);
        if (savedPath != null) {
          setState(() {
            _imagePath = savedPath;
          });
        }
      },
      onRemove: () {
        setState(() {
          _imagePath = null;
        });
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadStorageOptions() async {
    final tree = await _service.loadTree();
    final options = <Map<String, String>>[];

    // Añadir opción de raíz (sin padre)
    options.add({'id': '', 'name': '🏠 Raíz (Lugar o mueble principal)'});

    void traverse(InventoryNode n, String prefix) {
      // Un nodo no puede ser su propio padre
      if (widget.nodeToEdit != null && n.id == widget.nodeToEdit!.id) return;

      // Solo places y storages pueden contener cosas
      if (n.isPlace || n.isStorage) {
        final icon = n.isPlace ? '📍' : '📦';
        options.add({
          'id': n.id,
          'name': '$prefix$icon ${n.name}',
        });
        for (final child in n.children) {
          traverse(child, '$prefix   ');
        }
      }
    }

    for (final root in tree) {
      traverse(root, '');
    }

    if (mounted) {
      setState(() {
        _storageOptions = options;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final parentId = (_selectedParentId == null || _selectedParentId!.isEmpty)
        ? null
        : _selectedParentId;

    if (widget.nodeToEdit == null) {
      // Crear nuevo
      final newNode = InventoryNode(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        type: _selectedType,
        parentId: parentId,
        quantity: _selectedType == NodeType.item ? _quantity : 1,
        imagePath: _imagePath,
      );
      await _service.addNode(newNode, targetParentId: parentId);
    } else {
      // Editar existente
      final node = widget.nodeToEdit!;
      node.name = _nameController.text.trim();
      node.description = _descController.text.trim();
      node.quantity = _selectedType == NodeType.item ? _quantity : 1;
      node.imagePath = _imagePath;
      await _service.updateNode(node);

      if (parentId != widget.nodeToEdit!.parentId) {
        await _service.moveNode(node.id, parentId);
      }
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.nodeToEdit != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing
                      ? 'Editar ${_typeName(_selectedType)}'
                      : 'Añadir nuevo elemento',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selector de tipo (solo si es nuevo)
            if (!isEditing) ...[
              SegmentedButton<NodeType>(
                segments: const [
                  ButtonSegment(
                    value: NodeType.place,
                    label: Text('Lugar'),
                    icon: Icon(Icons.room),
                  ),
                  ButtonSegment(
                    value: NodeType.storage,
                    label: Text('Almacén'),
                    icon: Icon(Icons.inventory_2),
                  ),
                  ButtonSegment(
                    value: NodeType.item,
                    label: Text('Objeto'),
                    icon: Icon(Icons.category),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (set) {
                  setState(() {
                    _selectedType = set.first;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Campo Nombre
            TextFormField(
              controller: _nameController,
              autofocus: !isEditing,
              decoration: InputDecoration(
                labelText: 'Nombre',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                hintText: _selectedType == NodeType.place
                    ? 'Ej: Habitación, Garaje, Cocina'
                    : _selectedType == NodeType.storage
                        ? 'Ej: Armario, Balda 2, Caja roja'
                        : 'Ej: Bastoncillos, Calcetines, Hilo',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Selector de Contenedor Padre
            if (_selectedType != NodeType.place) ...[
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedParentId ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Ubicación / Contenedor padre',
                    labelStyle: TextStyle(color: AppTheme.textMuted),
                  ),
                  dropdownColor: AppTheme.darkCard,
                  items: _storageOptions.map((opt) {
                    return DropdownMenuItem<String>(
                      value: opt['id'],
                      child: Text(
                        opt['name']!,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedParentId = val;
                    });
                  },
                ),
              const SizedBox(height: 16),
            ],

            // Cantidad si es Ítem
            if (_selectedType == NodeType.item) ...[
              Row(
                children: [
                  const Text(
                    'Cantidad:',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppTheme.lavenderText),
                    onPressed: () {
                      if (_quantity > 1) {
                        setState(() => _quantity--);
                      }
                    },
                  ),
                  Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.lavenderText),
                    onPressed: () {
                      setState(() => _quantity++);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Campo Descripción
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notas / Descripción',
                labelStyle: TextStyle(color: AppTheme.textMuted),
                hintText: 'Detalles, color, especificaciones...',
              ),
            ),
            // Selector / Vista previa de imagen
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.searchBarBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _imagePath != null &&
                              _imagePath!.isNotEmpty &&
                              File(_imagePath!).existsSync()
                          ? Image.file(
                              File(_imagePath!),
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 54,
                              height: 54,
                              color: AppTheme.darkCard,
                              child: const Icon(
                                Icons.add_a_photo_outlined,
                                color: AppTheme.lavenderText,
                              ),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _imagePath != null ? 'Foto adjuntada' : 'Añadir imagen',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _imagePath != null
                                ? 'Toca para cambiar o eliminar'
                                : 'Tomar foto o elegir de la galería',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _imagePath != null ? Icons.edit : Icons.chevron_right,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón Guardar
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isEditing ? 'Guardar Cambios' : 'Crear ${_typeName(_selectedType)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeName(NodeType t) {
    switch (t) {
      case NodeType.place:
        return 'Lugar';
      case NodeType.storage:
        return 'Almacén / Mueble';
      case NodeType.item:
        return 'Objeto';
    }
  }
}
