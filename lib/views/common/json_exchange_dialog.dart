import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final text = _importController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Por favor, pega el JSON de un Lugar');
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
          content: Text('¡Lugar "${importedPlace.name}" importado con éxito!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'El JSON no corresponde a un Lugar válido o está mal formateado.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              tabs: const [
                Tab(icon: Icon(Icons.file_upload_outlined), text: 'Exportar Lugar'),
                Tab(icon: Icon(Icons.file_download_outlined), text: 'Importar Lugar'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExportTab(),
                  _buildImportTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_places.isEmpty) {
      return const Center(
        child: Text(
          'No hay lugares creados para exportar.',
          style: TextStyle(color: AppTheme.textMuted),
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
            decoration: const InputDecoration(
              labelText: 'Lugar a exportar',
              labelStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
          const Text(
            'Contenido JSON listo para compartir (sin fotos pesadas, 100% transferible):',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
                      const SnackBar(
                        content: Text('¡JSON del lugar copiado al portapapeles!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
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
                  label: const Text('Copiar JSON'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar', style: TextStyle(color: AppTheme.lavenderText)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pega el JSON de un Lugar para añadirlo a tu inventario sin modificar tus otros lugares:',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
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
                label: const Text('Pegar', style: TextStyle(color: AppTheme.lavenderText)),
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
                label: const Text('Añadir Lugar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
