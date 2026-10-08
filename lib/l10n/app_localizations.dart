import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get languageCode => locale.languageCode;

  // General & App
  String get appTitle => _t('Inventory', 'Inventario', 'Inventaire');
  String get searchPlaceholder => _t('Search in Inventory...', 'Buscar en el inventario...', 'Rechercher dans l\'inventaire...');
  String get favourites => _t('Favourites', 'Favoritos', 'Favoris');
  String get places => _t('Places', 'Lugares', 'Lieux');
  String get recentlyViewed => _t('Recently viewed', 'Vistos recientemente', 'Récemment consultés');
  String get addPlace => _t('Add Place', 'Añadir Lugar', 'Ajouter un lieu');
  String get noFavourites => _t('No favorite containers yet', 'No hay contenedores favoritos aún', 'Aucun conteneur favori pour l\'instant');
  String get noPlaces => _t('No places created yet', 'No hay lugares creados aún', 'Aucun lieu créé pour le moment');
  String get noRecents => _t('No recently viewed containers', 'No hay contenedores vistos recientemente', 'Aucun conteneur récemment consulté');
  String get noSearchResults => _t('No items or containers match', 'Ningún objeto o almacén coincide', 'Aucun objet ou conteneur ne correspond');
  String get emptyContainer => _t('This container is empty', 'Este contenedor está vacío', 'Ce conteneur est vide');

  // Node types
  String get place => _t('Place', 'Lugar', 'Lieu');
  String get storage => _t('Storage', 'Almacén', 'Rangement');
  String get object => _t('Object', 'Objeto', 'Objet');

  // Quantities
  String storagesCount(int count) => _t('$count storages', '$count almacenes', '$count rangements');
  String objectsCount(int count) => _t('$count objects', '$count objetos', '$count objets');
  String get units => _t('units', 'unidades', 'unités');

  // Actions
  String get close => _t('Close', 'Cerrar', 'Fermer');
  String get cancel => _t('Cancel', 'Cancelar', 'Annuler');
  String get save => _t('Save', 'Guardar', 'Enregistrer');
  String get add => _t('Add', 'Añadir', 'Ajouter');
  String get edit => _t('Edit', 'Editar', 'Modifier');
  String get delete => _t('Delete', 'Eliminar', 'Supprimer');
  String get move => _t('Move', 'Mover', 'Déplacer');
  String get copyJson => _t('Copy JSON', 'Copiar JSON', 'Copier le JSON');
  String get paste => _t('Paste', 'Pegar', 'Coller');
  String get selectContainer => _t('Select container', 'Seleccionar contenedor', 'Sélectionner le conteneur');
  String get moveHere => _t('Move here', 'Mover aquí', 'Déplacer ici');
  String get rootLevel => _t('Root level (Place)', 'Nivel raíz (Lugar)', 'Niveau racine (Lieu)');

  // Languages
  String get language => _t('Language', 'Idioma', 'Langue');
  String get selectLanguage => _t('Select Language', 'Seleccionar Idioma', 'Choisir la langue');
  String get english => 'English';
  String get spanish => 'Español';
  String get french => 'Français';

  // Photo bottom sheet
  String get changePhoto => _t('Change photo', 'Cambiar foto', 'Changer la photo');
  String get takePhotoCamera => _t('Take photo (Camera)', 'Hacer foto (Cámara)', 'Prendre une photo (Appareil)');
  String get chooseFromGallery => _t('Choose from gallery', 'Elegir de la galería', 'Choisir depuis la galerie');
  String get removePhoto => _t('Remove photo', 'Eliminar foto', 'Supprimer la photo');
  String get coverImage => _t('Cover image / photo', 'Imagen de portada / foto', 'Image de couverture / photo');

  // JSON Sync Dialog
  String get syncTooltip => _t('Export / Import Places', 'Exportar / Importar Lugares', 'Exporter / Importer des lieux');
  String get exportPlaceTab => _t('Export Place', 'Exportar Lugar', 'Exporter le lieu');
  String get importPlaceTab => _t('Import Place', 'Importar Lugar', 'Importer le lieu');
  String get placeToExport => _t('Place to export', 'Lugar a exportar', 'Lieu à exporter');
  String get exportNotice => _t(
    'JSON content ready to share (lightweight, photos excluded, 100% portable):',
    'Contenido JSON listo para compartir (sin fotos pesadas, 100% transferible):',
    'Contenu JSON prêt à être partagé (léger, photos exclues, 100% portable) :',
  );
  String get importNotice => _t(
    'Paste a Place JSON snippet to add it without modifying other places:',
    'Pega el JSON de un Lugar para añadirlo a tu inventario sin modificar tus otros lugares:',
    'Collez le JSON d\'un lieu pour l\'ajouter sans modifier vos autres lieux :',
  );
  String get invalidJson => _t('Invalid JSON or missing node data', 'Formato JSON no válido o datos incompletos', 'Format JSON invalide ou données manquantes');
  String get importSuccess => _t('Place imported successfully!', '¡Lugar importado con éxito!', 'Lieu importé avec succès !');
  String get copiedToClipboard => _t('JSON copied to clipboard', 'JSON copiado al portapapeles', 'JSON copié dans le presse-papiers');
  String get importedSuffix => _t('(imported)', '(importado)', '(importé)');

  // Details & Edit
  String get notes => _t('Notes', 'Notas', 'Notes');
  String get noNotes => _t('No notes provided', 'Sin notas añadidas', 'Aucune note ajoutée');
  String get locationPath => _t('Location in tree', 'Ubicación en el árbol', 'Emplacement dans l\'arbre');
  String get quantity => _t('Quantity', 'Cantidad', 'Quantité');
  String get deleteConfirmTitle => _t('Confirm deletion', 'Confirmar eliminación', 'Confirmer la suppression');
  String deleteConfirmMessage(String name) => _t(
    'Are you sure you want to delete "$name" and all its contents?',
    '¿Seguro que deseas eliminar "$name" y todo su contenido?',
    'Êtes-vous sûr de vouloir supprimer "$name" et tout son contenu ?',
  );

  // Creation & Editing
  String newTitle(String type) {
    if (type == 'place') return _t('New Place', 'Nuevo Lugar', 'Nouveau Lieu');
    if (type == 'storage') return _t('New Storage', 'Nuevo Almacén', 'Nouveau Rangement');
    return _t('New Object', 'Nuevo Objeto', 'Nouvel Objet');
  }

  String editTitle(String type) {
    if (type == 'place') return _t('Edit Place', 'Editar Lugar', 'Modifier le Lieu');
    if (type == 'storage') return _t('Edit Storage', 'Editar Almacén', 'Modifier le Rangement');
    return _t('Edit Object', 'Editar Objeto', 'Modifier l\'Objet');
  }

  String get nameLabel => _t('Name', 'Nombre', 'Nom');
  String get descriptionLabel => _t('Description / Notes', 'Descripción / Notas', 'Description / Notes');
  String get nameRequired => _t('Please enter a name', 'Por favor, introduce un nombre', 'Veuillez entrer un nom');
  String get parentStorageLabel => _t('Parent container', 'Contenedor padre', 'Conteneur parent');

  String _t(String en, String es, String fr) {
    if (locale.languageCode == 'es') return es;
    if (locale.languageCode == 'fr') return fr;
    return en;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
