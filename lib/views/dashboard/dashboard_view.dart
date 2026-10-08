import 'dart:io';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/inventory_node.dart';
import '../../services/inventory_storage_service.dart';
import '../../theme/app_theme.dart';
import '../common/figma_components.dart';
import '../common/json_exchange_dialog.dart';
import '../edit/node_edit_dialog.dart';
import '../storage/storage_detail_view.dart';
import '../object/object_detail_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _service = InventoryStorageService();
  final _searchController = TextEditingController();

  List<InventoryNode> _tree = [];
  List<InventoryNode> _favorites = [];
  List<InventoryNode> _recentlyViewed = [];
  List<SearchResult> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final tree = await _service.loadTree();
    final favs = await _service.getFavorites();
    final recents = await _service.getRecentlyViewed();

    if (mounted) {
      setState(() {
        _tree = tree;
        _favorites = favs;
        _recentlyViewed = recents;
        _isLoading = false;
      });
    }
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    final results = await _service.search(query);
    setState(() {
      _isSearching = true;
      _searchResults = results;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults = [];
    });
  }

  Future<void> _openJsonExchange() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => const PlaceJsonExchangeDialog(),
    );
    if (changed == true) {
      _loadData();
    }
  }

  Future<void> _exportPlace(String placeId) async {
    await showDialog(
      context: context,
      builder: (_) => PlaceJsonExchangeDialog(initialPlaceId: placeId),
    );
  }

  Future<void> _showAddSpeedDial() async {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.add,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.searchBarBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.room, color: AppTheme.lavenderText),
                ),
                title: Text(l10n.newTitle('place'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.place,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final changed = await NodeEditDialog.show(
                    context,
                    defaultType: NodeType.place,
                  );
                  if (changed == true) _loadData();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.searchBarBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2, color: AppTheme.lavenderText),
                ),
                title: Text(l10n.newTitle('storage'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.storage,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final changed = await NodeEditDialog.show(
                    context,
                    defaultType: NodeType.storage,
                  );
                  if (changed == true) _loadData();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.searchBarBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.category, color: AppTheme.lavenderText),
                ),
                title: Text(l10n.newTitle('item'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(l10n.object,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final changed = await NodeEditDialog.show(
                    context,
                    defaultType: NodeType.item,
                  );
                  if (changed == true) _loadData();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToNode(InventoryNode node) async {
    if (node.isItem) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ObjectDetailView(nodeId: node.id)),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StorageDetailView(nodeId: node.id)),
      );
    }
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppTheme.lavenderText,
                backgroundColor: AppTheme.darkCard,
                child: CustomScrollView(
                  slivers: [
                    // Header con SearchBar, selector de idioma y botón JSON
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: FigmaSearchBar(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                onClear: _clearSearch,
                                hintText: l10n.searchPlaceholder,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              tooltip: l10n.syncTooltip,
                              icon: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.searchBarBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.sync_alt, color: AppTheme.lavenderText),
                              ),
                              onPressed: _openJsonExchange,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_isSearching)
                      _buildSearchResults(l10n)
                    else ...[
                      // SECCIÓN: FAVOURITES
                      if (_favorites.isNotEmpty) _buildFavoritesSection(l10n),

                      // SECCIÓN: PLACES
                      _buildPlacesSection(l10n),

                      // SECCIÓN: RECENTLY VIEWED
                      if (_recentlyViewed.isNotEmpty) _buildRecentlyViewedSection(l10n),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 80),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSpeedDial,
        tooltip: l10n.add,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildSearchResults(AppLocalizations l10n) {
    if (_searchResults.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.search_off, size: 48, color: AppTheme.textMuted),
                const SizedBox(height: 12),
                Text(
                  '${l10n.noSearchResults}: "${_searchController.text}"',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final res = _searchResults[i];
            final n = res.node;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.searchBarBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    n.isPlace
                        ? Icons.room
                        : n.isStorage
                            ? Icons.inventory_2
                            : Icons.category,
                    color: AppTheme.lavenderText,
                  ),
                ),
                title: Text(n.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  res.pathString,
                  style: const TextStyle(color: AppTheme.lavenderText, fontSize: 12),
                ),
                trailing: n.isItem
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.searchBarBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('x${n.quantity}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    : const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                onTap: () => _navigateToNode(n),
              ),
            );
          },
          childCount: _searchResults.length,
        ),
      ),
    );
  }

  Widget _buildFavoritesSection(AppLocalizations l10n) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              l10n.favourites,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _favorites.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) {
                final fav = _favorites[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _navigateToNode(fav),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              fav.isPlace
                                  ? Icons.room
                                  : fav.isStorage
                                      ? Icons.inventory_2
                                      : Icons.category,
                              color: AppTheme.lavenderText,
                              size: 20,
                            ),
                            const Icon(Icons.favorite, color: Colors.redAccent, size: 16),
                          ],
                        ),
                        Text(
                          fav.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          fav.isItem
                              ? '${l10n.quantity}: ${fav.quantity}'
                              : l10n.objectsCount(fav.totalNestedItemsCount),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacesSection(AppLocalizations l10n) {
    final places = _tree.where((n) => n.isPlace).toList();
    final storagesInRoot = _tree.where((n) => !n.isPlace).toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.places,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final changed = await NodeEditDialog.show(
                      context,
                      defaultType: NodeType.place,
                    );
                    if (changed == true) _loadData();
                  },
                  icon: const Icon(Icons.add, size: 18, color: AppTheme.lavenderText),
                  label: Text(l10n.addPlace, style: const TextStyle(color: AppTheme.lavenderText)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (places.isEmpty && storagesInRoot.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    l10n.noPlaces,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              )
            else ...[
              // Grid o lista de Places
              for (final p in places) ...[
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: p.imagePath != null &&
                              p.imagePath!.isNotEmpty &&
                              File(p.imagePath!).existsSync()
                          ? Image.file(
                              File(p.imagePath!),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              padding: const EdgeInsets.all(12),
                              color: AppTheme.searchBarBg,
                              child: const Icon(Icons.meeting_room, color: AppTheme.lavenderText),
                            ),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    subtitle: Text(
                      '${l10n.storagesCount(p.children.length)} • ${l10n.objectsCount(p.totalNestedItemsCount)}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.file_upload_outlined, size: 20),
                          tooltip: l10n.exportPlaceTab,
                          color: AppTheme.lavenderText,
                          onPressed: () => _exportPlace(p.id),
                        ),
                        const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                      ],
                    ),
                    onTap: () => _navigateToNode(p),
                  ),
                ),
              ],

              // Storages sueltos en la raíz si los hubiera
              if (storagesInRoot.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.storage,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 8),
                for (final s in storagesInRoot) ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.searchBarBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          s.isStorage ? Icons.inventory_2 : Icons.category,
                          color: AppTheme.lavenderText,
                        ),
                      ),
                      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        l10n.objectsCount(s.totalNestedItemsCount),
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                      onTap: () => _navigateToNode(s),
                    ),
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyViewedSection(AppLocalizations l10n) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recentlyViewed,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            for (final r in _recentlyViewed) ...[
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    r.isPlace
                        ? Icons.room
                        : r.isStorage
                            ? Icons.inventory_2_outlined
                            : Icons.category_outlined,
                    color: AppTheme.lavenderText,
                    size: 20,
                  ),
                  title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    r.isPlace ? l10n.place : r.isStorage ? l10n.storage : '${l10n.object} (x${r.quantity})',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
                  onTap: () => _navigateToNode(r),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
