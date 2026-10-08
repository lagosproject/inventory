import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../models/inventory_node.dart';
import '../../services/inventory_storage_service.dart';
import '../../theme/app_theme.dart';

class PlaceJsonExchangeDialog extends StatefulWidget {
  final String? initialPlaceId;
  final bool openInImportTab;

  const PlaceJsonExchangeDialog({
    super.key,
    this.initialPlaceId,
    this.openInImportTab = false,
  });

  @override
  State<PlaceJsonExchangeDialog> createState() => _PlaceJsonExchangeDialogState();
}

class _PlaceJsonExchangeDialogState extends State<PlaceJsonExchangeDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = InventoryStorageService();
  final _importController = TextEditingController();

  List<InventoryNode> _places = [];
  String? _selectedPlaceId;
  String _exportedJson = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.openInImportTab ? 1 : 0,
    );
    _selectedPlaceId = widget.initialPlaceId;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final places = await _service.getPlaces();
    if (_selectedPlaceId == null && places.isNotEmpty) {
      _selectedPlaceId = places.first.id;
    }

    String json = '';
    if (_selectedPlaceId != null) {
      json = await _service.exportPlaceToJson(_selectedPlaceId!) ?? '';
    }

    if (mounted) {
      setState(() {
        _places = places;
        _exportedJson = json;
        _isLoading = false;
      });
    }
  }

  Future<void> _onPlaceSelected(String? newId) async {
    if (newId == null || newId == _selectedPlaceId) return;
    setState(() {
      _selectedPlaceId = newId;
      _isLoading = true;
    });
    final json = await _service.exportPlaceToJson(newId) ?? '';
    if (mounted) {
      setState(() {
        _exportedJson = json;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleImport() async {
    final l10n = AppLocalizations.of(context);
    final text = _importController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = l10n.invalidJson);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final importedPlace = await _service.importPlaceFromJson(text);
    if (!mounted) return;

    if (importedPlace != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.importSuccess} ("${importedPlace.name}")'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.invalidJson;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      backgroundColor: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.92,
        height: 560,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.lavenderText,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.lavenderText,
              tabs: [
                Tab(icon: const Icon(Icons.file_upload_outlined), text: l10n.exportPlaceTab),
                Tab(icon: const Icon(Icons.file_download_outlined), text: l10n.importPlaceTab),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExportTab(l10n),
                  _buildImportTab(l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTab(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_places.isEmpty) {
      return Center(
        child: Text(
          l10n.noPlaces,
          style: const TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedPlaceId,
            dropdownColor: AppTheme.darkCard,
            decoration: InputDecoration(
              labelText: l10n.placeToExport,
              labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            items: _places.map((p) {
              return DropdownMenuItem<String>(
                value: p.id,
                child: Text(
                  '📍 ${p.name}',
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _onPlaceSelected,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.exportNotice,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.searchBarBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _exportedJson,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _exportedJson));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.copiedToClipboard),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(l10n.copyJson),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close, style: const TextStyle(color: AppTheme.lavenderText)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportTab(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.importNotice,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TextField(
              controller: _importController,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                hintText: '{\n  "name": "Taller",\n  "type": "place",\n  "children": [...]\n}',
                hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.5)),
                fillColor: AppTheme.searchBarBg,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              TextButton.icon(
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    _importController.text = data!.text!;
                  }
                },
                icon: const Icon(Icons.paste, size: 18, color: AppTheme.lavenderText),
                label: Text(l10n.paste, style: const TextStyle(color: AppTheme.lavenderText)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addPlace),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
