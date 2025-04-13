import 'dart:convert';
import 'dart:io';
import 'package:cesi_zen/models/emotion_item.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
// Importe ou définis les modèles ici
// import 'package:cesi_zen/models/base_emotion.dart';
// import 'package:cesi_zen/models/specific_emotion.dart';
// import 'package:cesi_zen/models/emotion_log_entry.dart';

// Définis les classes BaseEmotion, SpecificEmotion, EmotionLogEntry ici si non importées

class EmotionService {
  static const String _baseEmotionsFile = 'base_emotions.json';
  static const String _specificEmotionsFile = 'specific_emotions.json';
  static const String _logEntriesFile = 'emotion_log.json';
  final _uuid = Uuid();

  // --- Helpers pour accès fichier (similaires aux autres services) ---
  // Helper pour obtenir le chemin du répertoire de documents
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Helper pour obtenir une référence au fichier local
  Future<File> _localFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }
  Future<List<dynamic>> _readJsonFile(String fileName, {List<dynamic>? defaultData}) async {
      try {
        final file = await _localFile(fileName);
        if (!await file.exists()) {
           print("Fichier $fileName non trouvé.");
           if (defaultData != null) {
              print("Création de $fileName avec les données par défaut.");
              await _writeJsonFile(fileName, defaultData);
              return defaultData;
           }
           return [];
        }
        final content = await file.readAsString();
        if (content.isEmpty) return [];
        return json.decode(content) as List<dynamic>;
      } catch(e) { print("Erreur lecture $fileName: $e"); return []; }
   }
   Future<File> _writeJsonFile(String fileName, List<dynamic> data) async {
       final file = await _localFile(fileName);
       return file.writeAsString(json.encode(data));
   }

  // --- Gestion des Définitions d'Émotions ---

  Future<List<BaseEmotion>> getBaseEmotions() async {
    final List<dynamic> jsonList = await _readJsonFile(_baseEmotionsFile, defaultData: _defaultBaseEmotions);
    try {
      return jsonList.map((j) => BaseEmotion.fromJson(j)).toList();
    } catch (e) { print("Erreur parsing base emotions: $e"); return []; }
  }

  Future<List<SpecificEmotion>> getSpecificEmotions() async {
    final List<dynamic> jsonList = await _readJsonFile(_specificEmotionsFile, defaultData: _defaultSpecificEmotions);
     try {
       return jsonList.map((j) => SpecificEmotion.fromJson(j)).toList();
     } catch (e) { print("Erreur parsing specific emotions: $e"); return []; }
  }

  // Helper pour filtrer les émotions spécifiques par émotion de base
  Future<List<SpecificEmotion>> getSpecificEmotionsForBase(String baseEmotionId) async {
      final allSpecific = await getSpecificEmotions();
      return allSpecific.where((se) => se.baseEmotionId == baseEmotionId).toList();
  }

  Future<File> _saveBaseEmotions(List<BaseEmotion> emotions) async {
     final List<Map<String, dynamic>> jsonList = emotions.map((e) => e.toJson()).toList();
     return _writeJsonFile(_baseEmotionsFile, jsonList);
  }
   Future<File> _saveSpecificEmotions(List<SpecificEmotion> emotions) async {
     final List<Map<String, dynamic>> jsonList = emotions.map((e) => e.toJson()).toList();
     return _writeJsonFile(_specificEmotionsFile, jsonList);
  }

 // --- Méthodes CRUD pour BaseEmotion ---
 Future<bool> addBaseEmotion(String name) async {
    try {
      final emotions = await getBaseEmotions();
      // Vérifie si le nom existe déjà (insensible à la casse)
       if (emotions.any((e) => e.name.toLowerCase() == name.toLowerCase())) {
          print("Erreur: L'émotion de base '$name' existe déjà.");
          return false; // Ou lancer une exception/retourner un message spécifique
       }
      final newEmotion = BaseEmotion(id: _uuid.v4(), name: name);
      emotions.add(newEmotion);
      await _saveBaseEmotions(emotions);
      return true;
    } catch (e) { print("Erreur ajout base emotion: $e"); return false; }
 }

 Future<bool> updateBaseEmotion(BaseEmotion updatedEmotion) async {
    try {
       final emotions = await getBaseEmotions();
       final index = emotions.indexWhere((e) => e.id == updatedEmotion.id);
       if (index != -1) {
           // Vérifie si le nouveau nom existe déjà (pour une autre émotion)
           if (emotions.any((e) => e.id != updatedEmotion.id && e.name.toLowerCase() == updatedEmotion.name.toLowerCase())) {
              print("Erreur: Le nom '${updatedEmotion.name}' est déjà utilisé par une autre émotion de base.");
              return false;
           }
          emotions[index] = updatedEmotion;
          await _saveBaseEmotions(emotions);
          return true;
       }
       return false; // Non trouvée
    } catch (e) { print("Erreur màj base emotion: $e"); return false; }
 }

 Future<bool> deleteBaseEmotion(String baseEmotionId) async {
    try {
       // Vérification importante: l'émotion de base est-elle utilisée ?
       final specificEmotions = await getSpecificEmotions();
       if (specificEmotions.any((se) => se.baseEmotionId == baseEmotionId)) {
          print("Erreur: Impossible de supprimer l'émotion de base '$baseEmotionId' car elle est utilisée par des émotions spécifiques.");
          return false; // Empêche la suppression
       }

       final emotions = await getBaseEmotions();
       final initialLength = emotions.length;
       emotions.removeWhere((e) => e.id == baseEmotionId);
       if (emotions.length < initialLength) {
          await _saveBaseEmotions(emotions);
          return true;
       }
       return false; // Non trouvée
    } catch (e) { print("Erreur suppression base emotion: $e"); return false; }
 }

 // --- Méthodes CRUD pour SpecificEmotion ---
 Future<bool> addSpecificEmotion(String name, String baseEmotionId) async {
     try {
        final emotions = await getSpecificEmotions();
         // Vérifie si le nom existe déjà DANS CETTE base émotion
        if (emotions.any((e) => e.baseEmotionId == baseEmotionId && e.name.toLowerCase() == name.toLowerCase())) {
           print("Erreur: L'émotion spécifique '$name' existe déjà pour cette émotion de base.");
           return false;
        }
        final newEmotion = SpecificEmotion(id: _uuid.v4(), name: name, baseEmotionId: baseEmotionId);
        emotions.add(newEmotion);
        await _saveSpecificEmotions(emotions);
        return true;
     } catch (e) { print("Erreur ajout specific emotion: $e"); return false; }
 }

  Future<bool> updateSpecificEmotion(SpecificEmotion updatedEmotion) async {
      try {
         final emotions = await getSpecificEmotions();
         final index = emotions.indexWhere((e) => e.id == updatedEmotion.id);
         if (index != -1) {
            // Vérifie si le nouveau nom existe déjà pour la même émotion de base (mais pour un ID différent)
             if (emotions.any((e) => e.id != updatedEmotion.id && e.baseEmotionId == updatedEmotion.baseEmotionId && e.name.toLowerCase() == updatedEmotion.name.toLowerCase())) {
                print("Erreur: Le nom '${updatedEmotion.name}' est déjà utilisé par une autre émotion spécifique de cette catégorie.");
                return false;
             }
            emotions[index] = updatedEmotion;
            await _saveSpecificEmotions(emotions);
            return true;
         }
         return false; // Non trouvée
      } catch (e) { print("Erreur màj specific emotion: $e"); return false; }
  }

 Future<bool> deleteSpecificEmotion(String specificEmotionId) async {
     try {
         final emotions = await getSpecificEmotions();
         final initialLength = emotions.length;
         emotions.removeWhere((e) => e.id == specificEmotionId);
         if (emotions.length < initialLength) {
            await _saveSpecificEmotions(emotions);
            return true;
         }
         return false; // Non trouvée
     } catch (e) { print("Erreur suppression specific emotion: $e"); return false; }
 }

  // --- Gestion des Entrées de Journal Utilisateur ---

  // Récupère les entrées pour un utilisateur spécifique, avec filtre de date optionnel
  Future<List<EmotionLogEntry>> getLogEntries(String userId, {DateTime? startDate, DateTime? endDate}) async {
      final List<dynamic> jsonList = await _readJsonFile(_logEntriesFile, defaultData: []);
      try {
          List<EmotionLogEntry> allEntries = jsonList.map((j) => EmotionLogEntry.fromJson(j)).toList();
          // Filtre par utilisateur
          List<EmotionLogEntry> userEntries = allEntries.where((entry) => entry.userId == userId).toList();

          // Filtre par date si spécifié
          if (startDate != null) {
              userEntries = userEntries.where((entry) => !entry.timestamp.isBefore(startDate)).toList();
          }
          if (endDate != null) {
             // Pour inclure toute la journée du endDate, on va jusqu'à la fin de cette journée
             DateTime endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
             userEntries = userEntries.where((entry) => !entry.timestamp.isAfter(endOfDay)).toList();
          }

          // Trie par date décroissante (plus récent en premier)
          userEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return userEntries;

      } catch (e) { print("Erreur parsing/filtering log entries: $e"); return []; }
  }

  // Ajoute une nouvelle entrée au journal
  Future<bool> addLogEntry({
      required String userId,
      required String specificEmotionId,
      required String baseEmotionId,
      DateTime? timestamp, // Optionnel, utilise maintenant si non fourni
      String? notes,
  }) async {
      try {
          final entries = (await _readJsonFile(_logEntriesFile, defaultData: [])).whereType<Map<String, dynamic>>().toList();
          final newEntry = EmotionLogEntry(
             id: _uuid.v4(),
             userId: userId,
             specificEmotionId: specificEmotionId,
             baseEmotionId: baseEmotionId,
             timestamp: timestamp ?? DateTime.now(), // Utilise l'heure actuelle par défaut
             notes: notes,
          );
          entries.add(newEntry.toJson()); // Ajoute le nouvel objet JSON
          await _writeJsonFile(_logEntriesFile, entries);
          print("Entrée de journal ajoutée: ${newEntry.id}");
          return true;
      } catch (e) { print("Erreur ajout entrée journal: $e"); return false; }
  }

  // Met à jour une entrée existante
  Future<bool> updateLogEntry(EmotionLogEntry updatedEntry) async {
     try {
          final entries = (await _readJsonFile(_logEntriesFile, defaultData: [])).whereType<Map<String, dynamic>>().toList();
          final index = entries.indexWhere((entry) => entry['id'] == updatedEntry.id);

          if (index != -1) {
              // Vérifie si l'utilisateur correspond (sécurité simple)
              if (entries[index]['userId'] != updatedEntry.userId) {
                 print("Erreur: Tentative de modification d'une entrée d'un autre utilisateur.");
                 return false;
              }
              entries[index] = updatedEntry.toJson(); // Remplace l'entrée
              await _writeJsonFile(_logEntriesFile, entries);
              print("Entrée de journal mise à jour: ${updatedEntry.id}");
              return true;
          }
          print("Entrée de journal non trouvée pour mise à jour: ${updatedEntry.id}");
          return false;
     } catch (e) { print("Erreur màj entrée journal: $e"); return false; }
  }

   // Supprime une entrée par son ID (et vérifie l'userId)
   Future<bool> deleteLogEntry(String entryId, String userId) async {
       try {
           final entries = (await _readJsonFile(_logEntriesFile, defaultData: [])).whereType<Map<String, dynamic>>().toList();
           final initialLength = entries.length;

           // Trouve l'index en vérifiant l'ID ET l'userId
           final index = entries.indexWhere((entry) => entry['id'] == entryId && entry['userId'] == userId);

           if (index != -1) {
              entries.removeAt(index); // Supprime l'entrée
               if (entries.length < initialLength) {
                   await _writeJsonFile(_logEntriesFile, entries);
                   print("Entrée de journal supprimée: $entryId");
                   return true;
               }
           }
           print("Entrée de journal non trouvée ou non autorisée pour suppression: $entryId");
           return false;
       } catch (e) { print("Erreur suppression entrée journal: $e"); return false; }
   }


  // --- Données par défaut pour les émotions (si fichiers non trouvés) ---
  final List<Map<String, dynamic>> _defaultBaseEmotions = [
      {"id": "be1", "name": "Joie"}, {"id": "be2", "name": "Colère"}, {"id": "be3", "name": "Peur"},
      {"id": "be4", "name": "Tristesse"}, {"id": "be5", "name": "Surprise"}, {"id": "be6", "name": "Dégoût"}
  ];
  final List<Map<String, dynamic>> _defaultSpecificEmotions = [
      {"id": "se1", "name": "Fierté", "baseEmotionId": "be1"}, {"id": "se2", "name": "Contentement", "baseEmotionId": "be1"},
      {"id": "se3", "name": "Enchantement", "baseEmotionId": "be1"}, {"id": "se4", "name": "Excitation", "baseEmotionId": "be1"},
      {"id": "se5", "name": "Émerveillement", "baseEmotionId": "be1"}, {"id": "se6", "name": "Gratitude", "baseEmotionId": "be1"},
      {"id": "se7", "name": "Frustration", "baseEmotionId": "be2"}, {"id": "se8", "name": "Irritation", "baseEmotionId": "be2"},
      {"id": "se9", "name": "Rage", "baseEmotionId": "be2"}, {"id": "se10", "name": "Ressentiment", "baseEmotionId": "be2"},
      {"id": "se11", "name": "Agacement", "baseEmotionId": "be2"}, {"id": "se12", "name": "Hostilité", "baseEmotionId": "be2"},
      {"id": "se13", "name": "Inquiétude", "baseEmotionId": "be3"}, {"id": "se14", "name": "Anxiété", "baseEmotionId": "be3"},
      {"id": "se15", "name": "Terreur", "baseEmotionId": "be3"}, {"id": "se16", "name": "Appréhension", "baseEmotionId": "be3"},
      {"id": "se17", "name": "Panique", "baseEmotionId": "be3"}, {"id": "se18", "name": "Crainte", "baseEmotionId": "be3"},
      {"id": "se19", "name": "Chagrin", "baseEmotionId": "be4"}, {"id": "se20", "name": "Mélancolie", "baseEmotionId": "be4"},
      {"id": "se21", "name": "Abattement", "baseEmotionId": "be4"}, {"id": "se22", "name": "Désespoir", "baseEmotionId": "be4"},
      {"id": "se23", "name": "Solitude", "baseEmotionId": "be4"}, {"id": "se24", "name": "Dépression", "baseEmotionId": "be4"},
      {"id": "se25", "name": "Étonnement", "baseEmotionId": "be5"}, {"id": "se26", "name": "Stupéfaction", "baseEmotionId": "be5"},
      {"id": "se27", "name": "Sidération", "baseEmotionId": "be5"}, {"id": "se28", "name": "Incrédulité", "baseEmotionId": "be5"},
      {"id": "se29", "name": "Émerveillement", "baseEmotionId": "be5"}, {"id": "se30", "name": "Confusion", "baseEmotionId": "be5"},
      {"id": "se31", "name": "Répulsion", "baseEmotionId": "be6"}, {"id": "se32", "name": "Déplaisir", "baseEmotionId": "be6"},
      {"id": "se33", "name": "Nausée", "baseEmotionId": "be6"}, {"id": "se34", "name": "Dédain", "baseEmotionId": "be6"},
      {"id": "se35", "name": "Horreur", "baseEmotionId": "be6"}, {"id": "se36", "name": "Dégoût profond", "baseEmotionId": "be6"}
  ];

}