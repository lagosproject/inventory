# Inventory — Gestor Jerárquico de Inventario en Árbol

> **Aplicación móvil Flutter 100% offline, local y privada.** Diseñada con arquitectura jerárquica en árbol (*Lugares $\rightarrow$ Almacenes $\rightarrow$ Sub-almacenes/Baldas/Cajas $\rightarrow$ Objetos*) inspirada en el diseño original de Figma, totalmente desacoplada de Firebase y con exportación/importación completa en JSON.

---

## 🌳 Arquitectura Jerárquica en Árbol

A diferencia de un inventario plano de tipo e-commerce, esta aplicación modela la organización física real de tus pertenencias:

```text
📍 Habitación (Place)
└── 📦 Armario (Storage)
    ├── 📦 Balda 1 (Storage)
    │   ├── 📦 Caja roja (Storage)
    │   │   └── 🏷️ Bastoncillos (Item, x50)
    │   └── 🏷️ Hilo (Item, x3)
    └── 📦 Cajón 1 (Storage)
        └── 🏷️ Calcetines (Item, x10)
```

- **📍 Place**: Raíz del entorno físico (ej: *Habitación*, *Taller*, *Cocina*, *Trastero*).
- **📦 Storage**: Mueble, estantería, balda, cajón o caja. Puede contener tanto sub-almacenes como objetos directos de forma recursiva sin límite de profundidad.
- **🏷️ Item**: Objeto final (*Bastoncillos, Calcetines, Hilo, Destornillador*...) con control rápido de cantidad/stock y notas.

---

## ✨ Características Principales

- **📱 100% Local y Privado**: Sin Firebase, sin nube y sin cuentas de usuario. Todos los datos se almacenan localmente en el dispositivo (`inventory_tree.json`).
- **🎨 Diseño Fiel a Figma**:
  - Paleta en modo oscuro profundo (`#16101E`, `#2E184D`, `#4F378B`, `#E8DEF8`).
  - Cabecera con barra de búsqueda píldora `Search in Inventory...` y botón de sincronización JSON.
  - Secciones dinámicas: **Favourites**, **Places** y **Recently viewed**.
  - Detalle de contenedor con banner lavanda, botones de acción circulares (❤️ Favorito, ✏️ Editar, 📦 Mover, 🗑️ Borrar), subsección de almacenes y subsección de objetos.
  - Detalle de objeto con contador de stock rápido `+` / `-`, notas y ruta jerárquica completa.
- **🔍 Búsqueda Global en Tiempo Real**: Busca cualquier objeto o almacén y visualiza al instante su ruta completa en el árbol (*ej: Habitación > Armario > Balda 1 > Caja roja > Bastoncillos*).
- **🔄 Importación / Exportación JSON**:
  - Exporta todo el árbol jerárquico a JSON con un toque y cópialo al portapapeles.
  - Importa árboles recibidos desde otro móvil o backup para restaurar o transferir inventarios completos.
- **🧩 Migas de Pan Interactivas (Breadcrumbs)**: Salta directamente a cualquier contenedor padre en la jerarquía.

---

## 📐 Estructura del Código

```text
lib/
├── main.dart                          # Inicialización y tema oscuro Figma
├── theme/
│   └── app_theme.dart                 # Paleta visual de Figma (colores y estilos M3)
├── models/
│   └── inventory_node.dart            # Modelo de nodo recursivo del árbol (Place, Storage, Item)
├── services/
│   └── inventory_storage_service.dart # Persistencia local JSON, búsqueda y utilidades de árbol
└── views/
    ├── common/
    │   ├── figma_components.dart      # Botones circulares, píldoras, breadcrumbs y buscador
    │   └── json_exchange_dialog.dart  # Diálogo de importar y exportar árbol JSON
    ├── dashboard/
    │   └── dashboard_view.dart        # Vista principal: Search, Favourites, Places, Recents y FAB
    ├── storage/
    │   └── storage_detail_view.dart   # Vista de contenedor: sub-almacenes y objetos
    ├── object/
    │   └── object_detail_view.dart    # Vista de objeto: contador de cantidad, notas y ruta
    └── edit/
        └── node_edit_dialog.dart      # Diálogo modal para crear/editar nodos en el árbol
```

---

## 🚀 Requisitos y Ejecución

### Requisitos
- Flutter SDK 3.22+ (probado en Flutter 3.44.0 / Dart 3.12.0)
- Android SDK 34+ / Java 17 o 21

### Ejecución
```bash
# Instalar dependencias
flutter pub get

# Ejecutar tests unitarios de la arquitectura en árbol
flutter test

# Ejecutar en móvil conectado vía ADB
flutter run

# Compilar APK de depuración
flutter build apk --debug
```

---

## 📄 Licencia

Proyecto de código abierto desarrollado para uso personal y local.
