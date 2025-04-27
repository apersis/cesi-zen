import 'dart:convert';
import 'dart:io';
import 'package:cesi_zen/models/info_item.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
// Importe le modèle InfoItem
// import 'package:cesi_zen/models/info_item.dart';

// Définis la classe InfoItem ici si non importée

class InfoService {
  static const String _fileName = 'info_items.json';
  final _uuid = Uuid();

  // --- Helpers Fichier (à copier/adapter) ---
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
  // Helper pour obtenir une référence au fichier local
  Future<File> _localFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }
  Future<List<dynamic>> _readJsonFile({List<dynamic>? defaultData}) async {
    String fileName = _fileName;
    try {
      final file = await _localFile(fileName);
      if (!await file.exists()) {
          print("Fichier $fileName non trouvé.");
          if (defaultData != null) {
            print("Création de $fileName avec les données par défaut.");
            await _writeJsonFile(defaultData);
            return defaultData;
          }
          return [];
      }
      final content = await file.readAsString();
      if (content.isEmpty) return [];
      return json.decode(content) as List<dynamic>;
    } catch(e) { print("Erreur lecture $fileName: $e"); return []; }
  }
  Future<File> _writeJsonFile(List<dynamic> data) async {
    String fileName = _fileName;
    final file = await _localFile(fileName);
    return file.writeAsString(json.encode(data));
  }
  // --- Fin Helpers ---

  // Récupère tous les items d'info
  Future<List<InfoItem>> getInfoItems() async {
    final List<dynamic> jsonList = await _readJsonFile(defaultData: _defaultInfoItems);
    try {
      // Trie les items par titre par défaut
      var items = jsonList.map((j) => InfoItem.fromJson(j)).toList();
      items.sort((a, b) => a.title.compareTo(b.title));
      return items;
    } catch (e) { print("Erreur parsing info items: $e"); return []; }
  }

  // --- Méthodes Admin ---
  Future<bool> addInfoItem(InfoItem newItemData) async {
    try {
      final items = await getInfoItems();
      // Vérifie si le titre ou le path existe déjà (optionnel mais recommandé)
      if (items.any((i) => i.title.toLowerCase() == newItemData.title.toLowerCase())) {
         print("Erreur: Titre déjà existant."); return false;
      }
       if (items.any((i) => i.routePath == newItemData.routePath)) {
         print("Erreur: Chemin de route déjà existant."); return false;
      }

      final itemToAdd = InfoItem(
        id: _uuid.v4(), // Génère ID
        title: newItemData.title,
        description: newItemData.description,
        routePath: newItemData.routePath,
        iconName: newItemData.iconName,
      );
      items.add(itemToAdd);
      await _writeJsonFile(items.map((i) => i.toJson()).toList());
      return true;
    } catch (e) { print("Erreur ajout info item: $e"); return false; }
  }

  Future<bool> updateInfoItem(InfoItem updatedItem) async {
     try {
        final items = await getInfoItems();
        final index = items.indexWhere((i) => i.id == updatedItem.id);
        if (index != -1) {
             // Vérifications d'unicité (optionnel)
            if (items.any((i) => i.id != updatedItem.id && i.title.toLowerCase() == updatedItem.title.toLowerCase())) {
                print("Erreur: Titre déjà existant."); return false;
            }
            if (items.any((i) => i.id != updatedItem.id && i.routePath == updatedItem.routePath)) {
                print("Erreur: Chemin de route déjà existant."); return false;
            }
           items[index] = updatedItem;
           await _writeJsonFile(items.map((i) => i.toJson()).toList());
           return true;
        }
        return false; // Non trouvé
     } catch (e) { print("Erreur màj info item: $e"); return false; }
  }

  Future<bool> deleteInfoItem(String itemId) async {
     try {
        final items = await getInfoItems();
        final initialLength = items.length;
        items.removeWhere((i) => i.id == itemId);
        if (items.length < initialLength) {
           await _writeJsonFile(items.map((i) => i.toJson()).toList());
           return true;
        }
        return false; // Non trouvé
     } catch (e) { print("Erreur suppression info item: $e"); return false; }
  }

  // --- Données par Défaut ---
  final List<Map<String, dynamic>> _defaultInfoItems = [
    {"id": "info-uuid-1", "title": "Diagnostic Stress", "description": "Évaluez votre niveau de stress récent (Échelle Holmes & Rahe).", "routePath": "diagnostics", "iconName": "quiz"},
    {"id": "info-uuid-2", "title": "Tracker d'Émotions", "description": "Enregistrez et consultez l'historique de vos émotions.", "routePath": "emotion_tracker", "iconName": "sentiment_satisfied"},
    {"id": "info-uuid-3", "title": "Activités de Détente", "description": "Découvrez des activités pour vous relaxer.", "routePath": "relaxation_activities", "iconName": "spa"},
    {"id": "info-uuid-4", "title": "Exercice Respiration", "description": "Pratiquez des exercices de respiration guidés.", "routePath": "breath", "iconName": "self_improvement"}
  ];
}