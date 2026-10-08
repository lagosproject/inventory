import 'package:uuid/uuid.dart';

enum NodeType {
  place,   // Habitación, Taller, Cocina...
  storage, // Armario, Estantería, Balda, Cajón, Caja...
  item,    // Hilo, Calcetines, Bastoncillos, Destornillador...
}

class InventoryNode {
  final String id;
  String name;
  String description;
  NodeType type;
  String? parentId;
  int quantity;
  bool isFavorite;
  String? imagePath;
  DateTime updatedAt;
  DateTime lastViewedAt;
  List<InventoryNode> children;

  InventoryNode({
    String? id,
    required this.name,
    this.description = '',
    required this.type,
    this.parentId,
    this.quantity = 1,
    this.isFavorite = false,
    this.imagePath,
    DateTime? updatedAt,
    DateTime? lastViewedAt,
    List<InventoryNode>? children,
  })  : id = id ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now(),
        lastViewedAt = lastViewedAt ?? DateTime.now(),
        children = children ?? [];

  bool get isPlace => type == NodeType.place;
  bool get isStorage => type == NodeType.storage;
  bool get isItem => type == NodeType.item;

  List<InventoryNode> get subStorages =>
      children.where((c) => c.isStorage).toList();

  List<InventoryNode> get directItems =>
      children.where((c) => c.isItem).toList();

  int get totalNestedItemsCount {
    int count = directItems.fold(0, (sum, i) => sum + i.quantity);
    for (final s in subStorages) {
      count += s.totalNestedItemsCount;
    }
    return count;
  }

  int get totalNestedStoragesCount {
    int count = subStorages.length;
    for (final s in subStorages) {
      count += s.totalNestedStoragesCount;
    }
    return count;
  }

  Map<String, dynamic> toJson({bool forExport = false}) {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'parentId': parentId,
      'quantity': quantity,
      'isFavorite': isFavorite,
      if (!forExport && imagePath != null) 'imagePath': imagePath,
      'updatedAt': updatedAt.toIso8601String(),
      'lastViewedAt': lastViewedAt.toIso8601String(),
      'children': children.map((c) => c.toJson(forExport: forExport)).toList(),
    };
  }

  factory InventoryNode.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String?) ?? 'item';
    final nodeType = NodeType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => NodeType.item,
    );

    final childrenList = json['children'];
    List<InventoryNode> parsedChildren = [];
    if (childrenList != null && childrenList is List) {
      parsedChildren = childrenList
          .whereType<Map<String, dynamic>>()
          .map((childMap) => InventoryNode.fromJson(childMap))
          .toList();
    }

    return InventoryNode(
      id: json['id'] as String?,
      name: (json['name'] as String?) ?? 'Sin nombre',
      description: (json['description'] as String?) ?? '',
      type: nodeType,
      parentId: json['parentId'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      isFavorite: (json['isFavorite'] as bool?) ?? false,
      imagePath: json['imagePath'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastViewedAt: json['lastViewedAt'] != null
          ? DateTime.tryParse(json['lastViewedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      children: parsedChildren,
    );
  }

  InventoryNode copyWith({
    String? name,
    String? description,
    NodeType? type,
    String? parentId,
    int? quantity,
    bool? isFavorite,
    String? imagePath,
    List<InventoryNode>? children,
    DateTime? lastViewedAt,
  }) {
    return InventoryNode(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      quantity: quantity ?? this.quantity,
      isFavorite: isFavorite ?? this.isFavorite,
      imagePath: imagePath ?? this.imagePath,
      updatedAt: DateTime.now(),
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      children: children ?? this.children,
    );
  }
}
