import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/inventory_node.dart';
import '../../services/image_storage_service.dart';
import '../../services/inventory_storage_service.dart';
import '../../theme/app_theme.dart';
import '../common/figma_components.dart';
import '../common/json_exchange_dialog.dart';
import '../edit/node_edit_dialog.dart';
import '../object/object_detail_view.dart';

class StorageDetailView extends StatefulWidget {
  final String nodeId;

  const StorageDetailView({
    super.key,
    required this.nodeId,
  });

  @override
  State<StorageDetailView> createState() => _StorageDetailViewState();
}

class _StorageDetailViewState extends State<StorageDetailView> {
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
      if (n.id == _node!.id) return;
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
            itemCount: storages.length + 1,
            itemBuilder: (ctx, i) {
              if (i == 0) {
                final isCurrent = _node!.parentId == null;
                return ListTile(
                  leading: const Icon(Icons.home, color: AppTheme.lavenderText),
                  title: Text('🏠 ${l10n.rootLevel}', style: const TextStyle(color: Colors.white)),
                  trailing: isCurrent ? const Icon(Icons.check, color: AppTheme.lavenderText) : null,
                  onTap: () => Navigator.pop(ctx, ''),
                );
              }
              final s = storages[i - 1];
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

    if (selected != null) {
      final newParent = selected.isEmpty ? null : selected;
      if (newParent != _node!.parentId) {
        await _service.moveNode(_node!.id, newParent);
        _loadNode();
      }
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

  Future<void> _addNewChild(NodeType type) async {
    final changed = await NodeEditDialog.show(
      context,
      defaultParentId: _node!.id,
      defaultType: type,
    );
    if (changed == true) {
      _loadNode();
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

  Future<void> _exportThisPlace() async {
    if (_node == null || !_node!.isPlace) return;
    await showDialog(
      context: context,
      builder: (_) => PlaceJsonExchangeDialog(initialPlaceId: _node!.id),
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
        appBar: AppBar(title: Text(l10n.storage)),
        body: Center(
          child: Text(l10n.emptyContainer, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    final parentName = _path.length > 1
        ? _path[_path.length - 2].name
        : (_node!.isPlace ? l10n.place : l10n.rootLevel);

    final subStorages = _node!.subStorages;
    final directItems = _node!.directItems;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(_node!.isPlace ? l10n.place : l10n.storage),
        actions: [
          if (_node!.isPlace)
            IconButton(
              icon: const Icon(Icons.file_upload_outlined),
              tooltip: l10n.exportPlaceTab,
              onPressed: _exportThisPlace,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner superior con soporte de imagen estilo Figma
            NodeBannerWithImage(
              title: _node!.name,
              subtitle: _node!.description.isNotEmpty ? _node!.description : null,
              defaultIcon: _node!.isPlace
                  ? Icons.meeting_room_rounded
                  : Icons.inventory_2_rounded,
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
            const SizedBox(height: 20),

            // Badge / Ubicación Padre
            Align(
              alignment: Alignment.center,
              child: FigmaPillBadge(
                icon: Icons.place_outlined,
                text: 'In $parentName',
              ),
            ),
            const SizedBox(height: 16),

            // Migas de pan
            if (_path.length > 1) ...[
              BreadcrumbBar(
                path: _path,
                onNodeTap: (target) {
                  if (target.id != _node!.id) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StorageDetailView(nodeId: target.id),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],

            // SECCIÓN: STORAGES
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.storage} (${subStorages.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addNewChild(NodeType.storage),
                  icon: const Icon(Icons.add, size: 18, color: AppTheme.lavenderText),
                  label: Text(l10n.add, style: const TextStyle(color: AppTheme.lavenderText)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (subStorages.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Center(
                  child: Text(
                    l10n.emptyContainer,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subStorages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final s = subStorages[i];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.searchBarBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.inventory_2_outlined, color: AppTheme.lavenderText),
                      ),
                      title: Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        '${l10n.objectsCount(s.totalNestedItemsCount)} • ${l10n.storagesCount(s.subStorages.length)}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StorageDetailView(nodeId: s.id),
                          ),
                        );
                        _loadNode();
                      },
                    ),
                  );
                },
              ),

            const SizedBox(height: 28),

            // SECCIÓN: ITEMS (Objetos contenidos)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.object} (${directItems.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addNewChild(NodeType.item),
                  icon: const Icon(Icons.add, size: 18, color: AppTheme.lavenderText),
                  label: Text(l10n.add, style: const TextStyle(color: AppTheme.lavenderText)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (directItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Center(
                  child: Text(
                    l10n.emptyContainer,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: directItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final it = directItems[i];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.searchBarBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.category_outlined, color: AppTheme.lavenderText),
                      ),
                      title: Text(
                        it.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        it.description.isNotEmpty ? it.description : '${l10n.quantity}: ${it.quantity}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.searchBarBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'x${it.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.lavenderText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                        ],
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ObjectDetailView(nodeId: it.id),
                          ),
                        );
                        _loadNode();
                      },
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
