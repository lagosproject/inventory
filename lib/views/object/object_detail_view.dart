import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/inventory_node.dart';
import '../../services/image_storage_service.dart';
import '../../services/inventory_storage_service.dart';
import '../../theme/app_theme.dart';
import '../common/figma_components.dart';
import '../edit/node_edit_dialog.dart';

class ObjectDetailView extends StatefulWidget {
  final String nodeId;

  const ObjectDetailView({
    super.key,
    required this.nodeId,
  });

  @override
  State<ObjectDetailView> createState() => _ObjectDetailViewState();
}

class _ObjectDetailViewState extends State<ObjectDetailView> {
  final _service = InventoryStorageService();
  final _imageService = ImageStorageService();
  InventoryNode? _node;
  List<InventoryNode> _path = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNode();
  }

  Future<void> _loadNode() async {
    final tree = await _service.loadTree();
    final node = _service.findNode(tree, widget.nodeId);
    if (node != null) {
      await _service.markRecentlyViewed(widget.nodeId);
      final path = _service.getNodePath(tree, widget.nodeId);
      if (mounted) {
        setState(() {
          _node = node;
          _path = path;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_node == null) return;
    await _service.toggleFavorite(_node!.id);
    setState(() {
      _node!.isFavorite = !_node!.isFavorite;
    });
  }

  Future<void> _changeQuantity(int delta) async {
    if (_node == null) return;
    final newQty = _node!.quantity + delta;
    if (newQty < 0) return;
    setState(() {
      _node!.quantity = newQty;
    });
    await _service.updateNode(_node!);
  }

  Future<void> _editNode() async {
    if (_node == null) return;
    final changed = await NodeEditDialog.show(
      context,
      nodeToEdit: _node,
    );
    if (changed == true) {
      _loadNode();
    }
  }

  Future<void> _moveNode() async {
    if (_node == null) return;
    final l10n = AppLocalizations.of(context);
    final tree = await _service.loadTree();
    final storages = <InventoryNode>[];

    void collectContainers(InventoryNode n) {
      if (n.isPlace || n.isStorage) {
        storages.add(n);
        for (final child in n.children) {
          collectContainers(child);
        }
      }
    }

    for (final r in tree) {
      collectContainers(r);
    }

    if (!mounted) return;

    final selected = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(l10n.selectContainer, style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: storages.length,
            itemBuilder: (ctx, i) {
              final s = storages[i];
              final isCurrent = s.id == _node!.parentId;
              return ListTile(
                leading: Icon(
                  s.isPlace ? Icons.room : Icons.inventory_2,
                  color: isCurrent ? AppTheme.lavenderText : AppTheme.textMuted,
                ),
                title: Text(
                  s.name,
                  style: TextStyle(
                    color: isCurrent ? AppTheme.lavenderText : Colors.white,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  s.isPlace ? l10n.place : l10n.storage,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                trailing: isCurrent ? const Icon(Icons.check, color: AppTheme.lavenderText) : null,
                onTap: () => Navigator.pop(ctx, s.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: const TextStyle(color: AppTheme.lavenderText)),
          ),
        ],
      ),
    );

    if (selected != null && selected != _node!.parentId) {
      await _service.moveNode(_node!.id, selected);
      _loadNode();
    }
  }

  Future<void> _deleteNode() async {
    if (_node == null) return;
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(l10n.deleteConfirmTitle, style: const TextStyle(color: Colors.white)),
        content: Text(
          l10n.deleteConfirmMessage(_node!.name),
          style: const TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: const TextStyle(color: AppTheme.lavenderText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteNode(_node!.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _pickImage() async {
    if (_node == null) return;
    await showImagePickerSheet(
      context,
      hasExistingImage: _node!.imagePath != null && _node!.imagePath!.isNotEmpty,
      onSelectSource: (source) async {
        final savedPath = await _imageService.pickAndSaveImage(source: source);
        if (savedPath != null) {
          setState(() {
            _node!.imagePath = savedPath;
          });
          await _service.updateNode(_node!);
        }
      },
      onRemove: () async {
        if (_node!.imagePath != null) {
          await _imageService.deleteImage(_node!.imagePath);
          setState(() {
            _node!.imagePath = null;
          });
          await _service.updateNode(_node!);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_node == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.object)),
        body: Center(
          child: Text(l10n.emptyContainer, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    final parentPath = _path.length > 1
        ? _path.sublist(0, _path.length - 1).map((n) => n.name).join(' > ')
        : l10n.rootLevel;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.object),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner superior con soporte de foto estilo Figma
            NodeBannerWithImage(
              title: _node!.name,
              defaultIcon: Icons.category_rounded,
              imagePath: _node!.imagePath,
              onPickImage: _pickImage,
            ),
            const SizedBox(height: 20),

            // Botones circulares de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FigmaActionCircle(
                  icon: _node!.isFavorite ? Icons.favorite : Icons.favorite_border,
                  iconColor: _node!.isFavorite ? Colors.redAccent : Colors.white,
                  tooltip: l10n.favourites,
                  onTap: _toggleFavorite,
                ),
                const SizedBox(width: 16),
                FigmaActionCircle(
                  icon: Icons.edit_outlined,
                  tooltip: l10n.edit,
                  onTap: _editNode,
                ),
                const SizedBox(width: 16),
                FigmaActionCircle(
                  icon: Icons.drive_file_move_outlined,
                  tooltip: l10n.move,
                  onTap: _moveNode,
                ),
                const SizedBox(width: 16),
                FigmaActionCircle(
                  icon: Icons.delete_outline,
                  iconColor: Colors.redAccent,
                  backgroundColor: AppTheme.searchBarBg,
                  tooltip: l10n.delete,
                  onTap: _deleteNode,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Badge / Ubicación Padre
            Align(
              alignment: Alignment.center,
              child: FigmaPillBadge(
                icon: Icons.place_outlined,
                text: 'In $parentPath',
                onTap: () {
                  if (_path.length > 1) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            const SizedBox(height: 28),

            // Contador de cantidad (Stock)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.quantity,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.searchBarBg,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.remove, size: 28),
                        onPressed: () => _changeQuantity(-1),
                      ),
                      Text(
                        '${_node!.quantity}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add, size: 28),
                        onPressed: () => _changeQuantity(1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notas / Descripción
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.notes,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _node!.description.isNotEmpty
                        ? _node!.description
                        : l10n.noNotes,
                    style: TextStyle(
                      color: _node!.description.isNotEmpty
                          ? Colors.white
                          : AppTheme.textMuted.withValues(alpha: 0.7),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Migas de pan completas
            if (_path.isNotEmpty) ...[
              Text(
                '${l10n.locationPath}:',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 8),
              BreadcrumbBar(
                path: _path,
                onNodeTap: (target) {
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
