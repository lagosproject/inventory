import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../models/inventory_node.dart';

Future<void> showImagePickerSheet(
  BuildContext context, {
  required ValueChanged<ImageSource> onSelectSource,
  VoidCallback? onRemove,
  bool hasExistingImage = false,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet(
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
              l10n.coverImage,
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
                child: const Icon(Icons.photo_camera, color: AppTheme.lavenderText),
              ),
              title: Text(l10n.takePhotoCamera),
              onTap: () {
                Navigator.pop(ctx);
                onSelectSource(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.searchBarBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: AppTheme.lavenderText),
              ),
              title: Text(l10n.chooseFromGallery),
              onTap: () {
                Navigator.pop(ctx);
                onSelectSource(ImageSource.gallery);
              },
            ),
            if (hasExistingImage && onRemove != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.searchBarBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
                title: Text(l10n.removePhoto,
                    style: const TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  onRemove();
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class FigmaActionCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const FigmaActionCircle({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: backgroundColor ?? AppTheme.primaryPurple,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: iconColor ?? Colors.white,
            size: size * 0.5,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

class FigmaPillBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;

  const FigmaPillBadge({
    super.key,
    required this.text,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.searchBarBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppTheme.lavenderText),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: AppTheme.lavenderText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FigmaSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;

  const FigmaSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText = 'Search in Inventory...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.searchBarBg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 15),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}

class BreadcrumbBar extends StatelessWidget {
  final List<InventoryNode> path;
  final void Function(InventoryNode node) onNodeTap;

  const BreadcrumbBar({
    super.key,
    required this.path,
    required this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < path.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
              ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: i == path.length - 1 ? null : () => onNodeTap(path[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  path[i].name,
                  style: TextStyle(
                    fontSize: 12,
                    color: i == path.length - 1
                        ? Colors.white
                        : AppTheme.lavenderText,
                    fontWeight: i == path.length - 1
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class NodeBannerWithImage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData defaultIcon;
  final String? imagePath;
  final VoidCallback onPickImage;

  const NodeBannerWithImage({
    super.key,
    required this.title,
    this.subtitle,
    required this.defaultIcon,
    this.imagePath,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null &&
        imagePath!.isNotEmpty &&
        javaFileExists(imagePath!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          if (hasImage)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(javaFile(imagePath!)),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(blurRadius: 8, color: Colors.black87),
                        ],
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.black87),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.lavenderBanner,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(
                    defaultIcon,
                    size: 56,
                    color: AppTheme.darkCard,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.darkBackground,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.darkBackground.withValues(alpha: 0.75),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Botón para cambiar / añadir foto
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: (hasImage ? Colors.black54 : AppTheme.primaryPurple).withValues(alpha: 0.8),
              shape: const CircleBorder(),
              child: IconButton(
                icon: Icon(
                  hasImage ? Icons.camera_alt : Icons.add_a_photo_outlined,
                  size: 20,
                  color: Colors.white,
                ),
                tooltip: hasImage
                    ? AppLocalizations.of(context).changePhoto
                    : AppLocalizations.of(context).coverImage,
                onPressed: onPickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool javaFileExists(String path) {
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  File javaFile(String path) => File(path);
}
