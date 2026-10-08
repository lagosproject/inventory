import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/l10n/app_localizations.dart';
import 'package:inventory/models/inventory_node.dart';

void main() {
  group('Inventory Tree Hierarchical Architecture Tests', () {
    test('Hierarchical nesting: Place -> Storage -> SubStorage -> Item', () {
      final bastoncillos = InventoryNode(
        name: 'Bastoncillos',
        description: 'Caja de algodón',
        type: NodeType.item,
        quantity: 100,
      );

      final hilo = InventoryNode(
        name: 'Hilo negro',
        type: NodeType.item,
        quantity: 2,
      );

      final calcetines = InventoryNode(
        name: 'Calcetines',
        type: NodeType.item,
        quantity: 6,
      );

      final cajaRoja = InventoryNode(
        name: 'Caja roja',
        type: NodeType.storage,
        children: [bastoncillos],
      );

      final balda1 = InventoryNode(
        name: 'Balda 1',
        type: NodeType.storage,
        children: [cajaRoja, hilo],
      );

      final cajon1 = InventoryNode(
        name: 'Cajón 1',
        type: NodeType.storage,
        children: [calcetines],
      );

      final armario = InventoryNode(
        name: 'Armario principal',
        type: NodeType.storage,
        children: [balda1, cajon1],
      );

      final habitacion = InventoryNode(
        name: 'Habitación',
        type: NodeType.place,
        children: [armario],
      );

      // Verificación de relaciones de árbol
      expect(habitacion.isPlace, isTrue);
      expect(armario.isStorage, isTrue);
      expect(bastoncillos.isItem, isTrue);

      // Verificación de conteo recursivo en cada nivel del árbol
      expect(cajaRoja.totalNestedItemsCount, 100);
      expect(balda1.totalNestedItemsCount, 102); // 100 bastoncillos + 2 hilos
      expect(cajon1.totalNestedItemsCount, 6);   // 6 calcetines
      expect(armario.totalNestedItemsCount, 108); // 102 en balda1 + 6 en cajon1
      expect(habitacion.totalNestedItemsCount, 108);

      expect(armario.subStorages.length, 2); // Balda 1 y Cajón 1
    });

    test('Full JSON tree serialization and reconstitution', () {
      final treeNode = InventoryNode(
        name: 'Armario',
        type: NodeType.storage,
        children: [
          InventoryNode(
            name: 'Balda 1',
            type: NodeType.storage,
            children: [
              InventoryNode(
                name: 'Caja',
                type: NodeType.storage,
                children: [
                  InventoryNode(
                    name: 'Bastoncillos',
                    type: NodeType.item,
                    quantity: 50,
                    isFavorite: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final jsonMap = treeNode.toJson();
      final jsonStr = jsonEncode(jsonMap);
      final decodedMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final reconstituted = InventoryNode.fromJson(decodedMap);

      expect(reconstituted.name, 'Armario');
      expect(reconstituted.subStorages.length, 1);
      final balda = reconstituted.subStorages.first;
      expect(balda.name, 'Balda 1');
      expect(balda.subStorages.length, 1);
      final caja = balda.subStorages.first;
      expect(caja.name, 'Caja');
      expect(caja.directItems.length, 1);
      final bastoncillos = caja.directItems.first;
      expect(bastoncillos.name, 'Bastoncillos');
      expect(bastoncillos.quantity, 50);
      expect(bastoncillos.isFavorite, isTrue);
    });

    test('Favorite and quantity mutability', () {
      final item = InventoryNode(
        name: 'Pilas AA',
        type: NodeType.item,
        quantity: 4,
      );

      expect(item.isFavorite, isFalse);
      item.isFavorite = true;
      expect(item.isFavorite, isTrue);

      item.quantity += 2;
      expect(item.quantity, 6);
    });

    test('ImagePath is persisted locally but omitted when exporting JSON', () {
      final nodeWithImage = InventoryNode(
        name: 'Taladro percutor',
        type: NodeType.item,
        imagePath: '/data/user/0/com.example.inventory/files/inventory_images/img_123.jpg',
      );

      // Persistencia local conserva la ruta de imagen
      final localJson = nodeWithImage.toJson(forExport: false);
      expect(localJson['imagePath'], contains('img_123.jpg'));
      final reconstitutedLocal = InventoryNode.fromJson(localJson);
      expect(reconstitutedLocal.imagePath, contains('img_123.jpg'));

      // Exportación limpia omite la ruta local de la foto
      final exportJson = nodeWithImage.toJson(forExport: true);
      expect(exportJson.containsKey('imagePath'), isFalse);
    });

    test('AppLocalizations supports English, Spanish, and French', () {
      final locEn = AppLocalizations(const Locale('en'));
      final locEs = AppLocalizations(const Locale('es'));
      final locFr = AppLocalizations(const Locale('fr'));

      expect(locEn.appTitle, 'Inventory');
      expect(locEs.appTitle, 'Inventario');
      expect(locFr.appTitle, 'Inventaire');

      expect(locEn.places, 'Places');
      expect(locEs.places, 'Lugares');
      expect(locFr.places, 'Lieux');

      expect(locEn.favourites, 'Favourites');
      expect(locEs.favourites, 'Favoritos');
      expect(locFr.favourites, 'Favoris');

      expect(locEn.storagesCount(3), '3 storages');
      expect(locEs.storagesCount(3), '3 almacenes');
      expect(locFr.storagesCount(3), '3 rangements');
    });
  });
}
