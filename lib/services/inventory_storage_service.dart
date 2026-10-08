import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/inventory_node.dart';

class SearchResult {
  final InventoryNode node;
  final String pathString;
  const SearchResult({required this.node, required this.pathString});
}

class InventoryStorageService {
  static const String _storageFileName = 'inventory_tree.json';
  static final InventoryStorageService _instance = InventoryStorageService._internal();

  factory InventoryStorageService() => _instance;
  InventoryStorageService._internal();

  File? _fileCache;

  Future<File> _getFile() async {
    if (_fileCache != null) return _fileCache!;
    final directory = await getApplicationDocumentsDirectory();
    _fileCache = File('${directory.path}/$_storageFileName');
    return _fileCache!;
  }

  /// Carga todo el árbol de inventario (nodos raíz: Places y Storages principales).
  Future<List<InventoryNode>> loadTree() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        final defaultTree = _createDefaultTree();
        await saveTree(defaultTree);
        return defaultTree;
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];

      final dynamic decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((m) => InventoryNode.fromJson(m))
            .toList();
      } else if (decoded is Map<String, dynamic>) {
        return [InventoryNode.fromJson(decoded)];
      }
      return [];
    } catch (e) {
      debugPrint('Error al cargar árbol de inventario: $e');
      return _createDefaultTree();
    }
  }

  /// Guarda el árbol completo a disco.
  Future<void> saveTree(List<InventoryNode> tree) async {
    final file = await _getFile();
    const encoder = JsonEncoder.withIndent('  ');
    final jsonStr = encoder.convert(tree.map((n) => n.toJson()).toList());
    await file.writeAsString(jsonStr);
  }

  /// Busca un nodo por su ID recursivamente.
  InventoryNode? findNode(List<InventoryNode> nodes, String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
      final found = findNode(node.children, id);
      if (found != null) return found;
    }
    return null;
  }

  /// Obtiene la ruta completa (migas de pan) hasta el nodo.
  List<InventoryNode> getNodePath(List<InventoryNode> rootNodes, String targetId) {
    List<InventoryNode> path = [];
    _findPathRecursive(rootNodes, targetId, path);
    return path;
  }

  bool _findPathRecursive(List<InventoryNode> currentNodes, String targetId, List<InventoryNode> currentPath) {
    for (final node in currentNodes) {
      currentPath.add(node);
      if (node.id == targetId) return true;
      if (_findPathRecursive(node.children, targetId, currentPath)) return true;
      currentPath.removeLast();
    }
    return false;
  }

  /// Añade un nuevo nodo (si parentId es null se añade a la raíz).
  Future<void> addNode(InventoryNode node, {String? targetParentId}) async {
    final tree = await loadTree();
    node.parentId = targetParentId;

    if (targetParentId == null || targetParentId.isEmpty) {
      tree.add(node);
    } else {
      final parent = findNode(tree, targetParentId);
      if (parent != null) {
        parent.children.add(node);
        parent.updatedAt = DateTime.now();
      } else {
        tree.add(node);
      }
    }
    await saveTree(tree);
  }

  /// Actualiza los datos de un nodo existente.
  Future<void> updateNode(InventoryNode updatedNode) async {
    final tree = await loadTree();
    _replaceNodeRecursive(tree, updatedNode);
    await saveTree(tree);
  }

  bool _replaceNodeRecursive(List<InventoryNode> nodes, InventoryNode updatedNode) {
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i].id == updatedNode.id) {
        nodes[i] = updatedNode;
        return true;
      }
      if (_replaceNodeRecursive(nodes[i].children, updatedNode)) return true;
    }
    return false;
  }

  /// Elimina un nodo y todos sus hijos.
  Future<void> deleteNode(String id) async {
    final tree = await loadTree();
    _deleteNodeRecursive(tree, id);
    await saveTree(tree);
  }

  bool _deleteNodeRecursive(List<InventoryNode> nodes, String id) {
    final initialLength = nodes.length;
    nodes.removeWhere((n) => n.id == id);
    if (nodes.length < initialLength) return true;

    for (final node in nodes) {
      if (_deleteNodeRecursive(node.children, id)) return true;
    }
    return false;
  }

  /// Mueve un nodo a otro padre (o a la raíz).
  Future<void> moveNode(String nodeId, String? newParentId) async {
    final tree = await loadTree();
    final node = findNode(tree, nodeId);
    if (node == null) return;

    // Desconectar del padre actual
    _deleteNodeRecursive(tree, nodeId);

    // Conectar al nuevo padre
    node.parentId = newParentId;
    node.updatedAt = DateTime.now();

    if (newParentId == null) {
      tree.add(node);
    } else {
      final newParent = findNode(tree, newParentId);
      if (newParent != null) {
        newParent.children.add(node);
      } else {
        tree.add(node);
      }
    }

    await saveTree(tree);
  }

  /// Alterna el estado de favorito.
  Future<InventoryNode?> toggleFavorite(String id) async {
    final tree = await loadTree();
    final node = findNode(tree, id);
    if (node != null) {
      node.isFavorite = !node.isFavorite;
      node.updatedAt = DateTime.now();
      await saveTree(tree);
    }
    return node;
  }

  /// Registra que un nodo ha sido visitado recientemente.
  Future<void> markRecentlyViewed(String id) async {
    final tree = await loadTree();
    final node = findNode(tree, id);
    if (node != null) {
      node.lastViewedAt = DateTime.now();
      await saveTree(tree);
    }
  }

  /// Modifica la cantidad de un ítem.
  Future<InventoryNode?> changeItemQuantity(String id, int delta) async {
    final tree = await loadTree();
    final node = findNode(tree, id);
    if (node != null) {
      node.quantity = (node.quantity + delta).clamp(0, 999999);
      node.updatedAt = DateTime.now();
      await saveTree(tree);
    }
    return node;
  }

  /// Obtiene todos los favoritos de todo el árbol.
  Future<List<InventoryNode>> getFavorites() async {
    final tree = await loadTree();
    List<InventoryNode> favorites = [];
    _collectFavorites(tree, favorites);
    return favorites;
  }

  void _collectFavorites(List<InventoryNode> nodes, List<InventoryNode> result) {
    for (final node in nodes) {
      if (node.isFavorite) result.add(node);
      _collectFavorites(node.children, result);
    }
  }

  /// Obtiene los elementos vistos recientemente.
  Future<List<InventoryNode>> getRecentlyViewed({int limit = 6}) async {
    final tree = await loadTree();
    List<InventoryNode> allNodes = [];
    _collectAllNodes(tree, allNodes);
    allNodes.sort((a, b) => b.lastViewedAt.compareTo(a.lastViewedAt));
    return allNodes.take(limit).toList();
  }

  /// Obtiene todos los lugares (Places) raíz.
  Future<List<InventoryNode>> getPlaces() async {
    final tree = await loadTree();
    return tree.where((n) => n.isPlace).toList();
  }

  void _collectAllNodes(List<InventoryNode> nodes, List<InventoryNode> result) {
    for (final node in nodes) {
      result.add(node);
      _collectAllNodes(node.children, result);
    }
  }

  /// Obtiene todos los posibles contenedores para el selector de padre.
  Future<List<InventoryNode>> getAllContainers() async {
    final tree = await loadTree();
    List<InventoryNode> containers = [];
    _collectContainers(tree, containers);
    return containers;
  }

  void _collectContainers(List<InventoryNode> nodes, List<InventoryNode> result) {
    for (final node in nodes) {
      if (node.isPlace || node.isStorage) {
        result.add(node);
      }
      _collectContainers(node.children, result);
    }
  }

  /// Búsqueda global en el árbol. Retorna lista de SearchResult.
  Future<List<SearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final tree = await loadTree();
    final q = query.toLowerCase();
    List<SearchResult> results = [];

    void searchRecursive(List<InventoryNode> nodes) {
      for (final node in nodes) {
        final matches = node.name.toLowerCase().contains(q) ||
            node.description.toLowerCase().contains(q);
        if (matches) {
          final path = getNodePath(tree, node.id);
          final pathStr = path.map((n) => n.name).join(' > ');
          results.add(SearchResult(node: node, pathString: pathStr));
        }
        searchRecursive(node.children);
      }
    }

    searchRecursive(tree);
    return results;
  }

  /// Exporta el árbol completo a JSON formateado (sin rutas locales de imágenes).
  Future<String> exportTreeToJson() async {
    final tree = await loadTree();
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(tree.map((n) => n.toJson(forExport: true)).toList());
  }

  /// Exporta un Lugar específico y todo su árbol jerárquico a JSON limpio.
  Future<String?> exportPlaceToJson(String placeId) async {
    final tree = await loadTree();
    final place = findNode(tree, placeId);
    if (place == null) return null;
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(place.toJson(forExport: true));
  }

  /// Importa un Lugar desde JSON y lo añade al inventario sin sobrescribir nada.
  /// Si ya existe un Lugar con el mismo nombre, se añade el sufijo "(importado)".
  Future<InventoryNode?> importPlaceFromJson(String jsonString) async {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      Map<String, dynamic> placeMap;
      if (decoded is Map<String, dynamic>) {
        placeMap = decoded;
      } else if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
        placeMap = decoded.first as Map<String, dynamic>;
      } else {
        return null;
      }

      final rawPlace = InventoryNode.fromJson(placeMap);
      rawPlace.type = NodeType.place;
      rawPlace.parentId = null;

      // Regenerar todos los IDs para garantizar unicidad absoluta
      final cleanPlace = _regenerateIds(rawPlace, null);

      final currentTree = await loadTree();

      // Comprobar colisión de nombres
      final existingNames = currentTree
          .where((n) => n.isPlace)
          .map((n) => n.name.trim().toLowerCase())
          .toSet();
      if (existingNames.contains(cleanPlace.name.trim().toLowerCase())) {
        cleanPlace.name = '${cleanPlace.name} (importado)';
      }

      currentTree.add(cleanPlace);
      await saveTree(currentTree);
      return cleanPlace;
    } catch (e) {
      debugPrint('Error al importar Lugar desde JSON: $e');
      return null;
    }
  }

  /// Importa un árbol completo desde JSON con soporte para reemplazar o anexar.
  Future<bool> importTreeFromJson(String jsonString, {bool replaceExisting = false}) async {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      List<InventoryNode> importedRoots = [];

      if (decoded is List) {
        importedRoots = decoded
            .whereType<Map<String, dynamic>>()
            .map((m) => InventoryNode.fromJson(m))
            .toList();
      } else if (decoded is Map<String, dynamic>) {
        importedRoots = [InventoryNode.fromJson(decoded)];
      } else {
        return false;
      }

      if (replaceExisting) {
        await saveTree(importedRoots);
      } else {
        final remapped = importedRoots.map((root) => _regenerateIds(root)).toList();
        final currentTree = await loadTree();
        currentTree.addAll(remapped);
        await saveTree(currentTree);
      }
      return true;
    } catch (e) {
      debugPrint('Error importTreeFromJson: $e');
      return false;
    }
  }

  InventoryNode _regenerateIds(InventoryNode node, [String? newParentId]) {
    final newId = const Uuid().v4();
    final children = node.children
        .map((child) => _regenerateIds(child, newId))
        .toList();

    return InventoryNode(
      id: newId,
      name: node.name,
      description: node.description,
      type: node.type,
      parentId: newParentId,
      quantity: node.quantity,
      isFavorite: node.isFavorite,
      updatedAt: DateTime.now(),
      lastViewedAt: DateTime.now(),
      children: children,
    );
  }

  /// Árbol inicial de ejemplo según la estructura descrita por Pablo.
  List<InventoryNode> _createDefaultTree() {
    final habitacion = InventoryNode(
      id: const Uuid().v4(),
      name: 'Habitación',
      description: 'Dormitorio principal con armarios y estanterías.',
      type: NodeType.place,
    );

    final armario = InventoryNode(
      id: const Uuid().v4(),
      name: 'Armario',
      description: 'Armario de ropa y almacenaje.',
      type: NodeType.storage,
      parentId: habitacion.id,
      isFavorite: true,
    );

    final balda1 = InventoryNode(
      id: const Uuid().v4(),
      name: 'Balda 1',
      description: 'Balda superior para cajas y libros.',
      type: NodeType.storage,
      parentId: armario.id,
    );

    final cajaRoja = InventoryNode(
      id: const Uuid().v4(),
      name: 'Caja roja',
      description: 'Caja organizadora con objetos pequeños.',
      type: NodeType.storage,
      parentId: balda1.id,
      isFavorite: true,
    );

    final bastoncillos = InventoryNode(
      id: const Uuid().v4(),
      name: 'Bastoncillos',
      description: 'Paquete de bastoncillos de algodón.',
      type: NodeType.item,
      quantity: 50,
      parentId: cajaRoja.id,
    );

    final libro = InventoryNode(
      id: const Uuid().v4(),
      name: 'Libro de Flutter',
      description: 'Manual de arquitectura y desarrollo móvil.',
      type: NodeType.item,
      quantity: 1,
      parentId: balda1.id,
    );

    final cajon1 = InventoryNode(
      id: const Uuid().v4(),
      name: 'Cajón 1',
      description: 'Cajón de calcetines y costura.',
      type: NodeType.storage,
      parentId: armario.id,
    );

    final hilo = InventoryNode(
      id: const Uuid().v4(),
      name: 'Hilo',
      description: 'Bobina de hilo para coser.',
      type: NodeType.item,
      quantity: 3,
      parentId: cajon1.id,
    );

    final calcetines = InventoryNode(
      id: const Uuid().v4(),
      name: 'Calcetines',
      description: 'Calcetines negros de deporte.',
      type: NodeType.item,
      quantity: 10,
      parentId: cajon1.id,
    );

    // Jerarquía
    cajaRoja.children = [bastoncillos];
    balda1.children = [libro, cajaRoja];
    cajon1.children = [hilo, calcetines];
    armario.children = [balda1, cajon1];
    habitacion.children = [armario];

    // Segundo lugar: Taller
    final taller = InventoryNode(
      id: const Uuid().v4(),
      name: 'Taller',
      description: 'Zona de bricolaje y herramientas.',
      type: NodeType.place,
    );

    final cajaHerramientas = InventoryNode(
      id: const Uuid().v4(),
      name: 'Caja de herramientas',
      description: 'Maletín negro con herramientas manuales.',
      type: NodeType.storage,
      parentId: taller.id,
    );

    final destornillador = InventoryNode(
      id: const Uuid().v4(),
      name: 'Destornillador Phillips',
      description: 'Destornillador de estrella mango rojo.',
      type: NodeType.item,
      quantity: 2,
      parentId: cajaHerramientas.id,
    );

    cajaHerramientas.children = [destornillador];
    taller.children = [cajaHerramientas];

    return [habitacion, taller];
  }
}
