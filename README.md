# Inventory — Hierarchical Tree Inventory Manager

[![Build Android APK](https://github.com/lagosproject/Inventory/actions/workflows/build-apk.yml/badge.svg)](https://github.com/lagosproject/Inventory/actions/workflows/build-apk.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)

> **100% offline, local, and privacy-focused Flutter mobile application.** Built with a recursive hierarchical tree architecture (*Places $\rightarrow$ Storages $\rightarrow$ Sub-storages / Shelves / Boxes $\rightarrow$ Items*) inspired by Figma designs, fully decoupled from Firebase, with granular Place-level JSON exchange and local photo attachment support.

---

## 🌳 Hierarchical Tree Architecture

Unlike flat e-commerce inventory apps, **Inventory** accurately models the real physical organization of your belongings:

```text
📍 Room (Place)
└── 📦 Wardrobe (Storage)
    ├── 📦 Shelf 1 (Storage)
    │   ├── 📦 Red Box (Storage)
    │   │   └── 🏷️ Cotton Swabs (Item, x50)
    │   └── 🏷️ Thread (Item, x3)
    └── 📦 Drawer 1 (Storage)
        └── 🏷️ Socks (Item, x10)
```

- **📍 Place**: Root physical zone or room (e.g., *Bedroom*, *Workshop*, *Kitchen*, *Storage Room*).
- **📦 Storage**: Furniture, shelving unit, shelf, drawer, or box. Storages can recursively contain other storages as well as items without any arbitrary depth limits.
- **🏷️ Item**: Leaf object (*Cotton Swabs, Screwdriver, Cable, Socks*...) with quick stock controls (`+` / `-`), custom quantities, and descriptive notes.

---

## ✨ Key Features

- **📱 100% Offline & Private**: Zero cloud dependencies, zero telemetry, and no user accounts required. All inventory state is persisted locally on the device filesystem (`inventory_tree.json`).
- **📤 Granular Place Export & Import**:
  - Export any individual **Place** (e.g., just your *Workshop* or *Kitchen*) to a lightweight, formatted JSON snippet with a single tap.
  - Import shared JSON places non-destructively: new places are appended into your local inventory without overwriting existing data.
  - Automatic collision resolution: appends `(importado)` if a place name matches, and generates fresh UUIDs across all imported subtree nodes to prevent ID conflicts.
- **📷 Local Photo Attachments**:
  - Attach photos to **Places**, **Storages**, and **Items** using either the live **Camera** or photo **Gallery**.
  - Images are stored safely in internal app storage (`inventory_images/`).
  - **Zero JSON leakage**: Local image file paths are strictly stripped from JSON exports (`forExport: true`), ensuring exported files remain lightweight text that can be shared across devices.
- **🎨 Figma Dark Mode Aesthetics**:
  - Deep violet color palette (`#16101E`, `#2E184D`, `#4F378B`, `#E8DEF8`).
  - Pill search bar `Search in Inventory...` with JSON sync modal button.
  - Interactive sections: **Favourites**, **Places**, and **Recently viewed**.
  - Circular action buttons (❤️ Favorite, ✏️ Edit, 📦 Move across tree, 🗑️ Delete).
  - Clean responsive modals and cover banners with image gradient overlays.
- **🌐 Automatic Multilingual Support (English, Spanish & French)**: Full internationalization across all views, modals, counters, and actions. The app automatically recognizes the user's device system language (Spanish, French, or English as default fallback).
- **🔍 Real-Time Global Tree Search**: Search any item or container across your entire collection and instantly view its full breadcrumb path (e.g., *Room > Wardrobe > Shelf 1 > Red Box > Cotton Swabs*).
- **🧩 Interactive Breadcrumbs**: Tap any parent level to navigate up the container hierarchy effortlessly.

---

## 🏗️ Project Architecture

```text
lib/
├── main.dart                          # App initialization, providers, and theme bootstrap
├── theme/
│   └── app_theme.dart                 # Figma dark color palette and Material 3 design tokens
├── models/
│   └── inventory_node.dart            # Recursive tree node model (Place, Storage, Item) with export sanitization
├── services/
│   ├── inventory_storage_service.dart # Local JSON persistence, Place export/import, search engine, and tree traversals
│   └── image_storage_service.dart     # Camera/gallery image picker and local file management
└── views/
    ├── common/
    │   ├── figma_components.dart      # Action buttons, image banner overlays, bottom sheets, and badges
    │   └── json_exchange_dialog.dart  # Responsive tabbed dialog for Place export and non-destructive import
    ├── dashboard/
    │   └── dashboard_view.dart        # Main dashboard: Search, Favourites, Places, Recents, and Speed Dial FAB
    ├── storage/
    │   └── storage_detail_view.dart   # Storage inspection: nested sub-storages and direct items
    ├── object/
    │   └── object_detail_view.dart    # Item inspection: quick quantity counter, notes, and breadcrumb path
    └── edit/
        └── node_edit_dialog.dart      # Modal dialog for creating and editing nodes with photo previews
```

---

## ⚙️ Development & Testing

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.22+ (tested on Flutter 3.44.0 / Dart 3.12.0)
- Android SDK 34+ / JDK 17 or 21

### Commands
```bash
# Get Flutter dependencies
flutter pub get

# Run code analysis
flutter analyze

# Run unit tests
flutter test

# Run app on connected device / emulator
flutter run

# Build release APK locally
flutter build apk --release
```

---

## 🤖 Continuous Integration & Pre-built APKs

This repository includes a automated GitHub Actions CI pipeline ([`.github/workflows/build-apk.yml`](.github/workflows/build-apk.yml)) that:
1. Runs code analysis (`flutter analyze`) and unit test validation (`flutter test`) on every push and pull request.
2. Compiles an Android release APK (`flutter build apk --release`).
3. Signs the release APK with the standard Android debug certificate, producing a **sideloadable, installable APK** that works on physical Android phones without requiring private developer keystores or encountering signature errors.
4. Uploads the generated APK as a workflow artifact (`Inventory-app-release`) ready for download and testing.

---

## 📄 License

This project is open-source software licensed under the MIT License.
