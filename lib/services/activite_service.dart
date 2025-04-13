import 'dart:convert';
import 'dart:io';
import 'package:cesi_zen/models/activite_item.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
// Importe le modèle RelaxationActivity
// import 'package:cesi_zen/models/relaxation_activity.dart';

// Définis la classe RelaxationActivity ici si non importée

class RelaxationService {
  static const String _fileName = 'relaxation_activities.json';
  final _uuid = Uuid();

  // --- Helpers Fichier (à copier/adapter depuis tes autres services) ---
  // --- Helpers pour accès fichier (similaires aux autres services) ---
  // Helper pour obtenir le chemin du répertoire de documents
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Helper pour obtenir une référence au fichier local
  Future<File> _localFile() async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }
  Future<List<dynamic>> _readJsonFile({List<dynamic>? defaultData}) async {
    // Logique pour lire le JSON, le créer avec defaultData si absent
     try {
        final file = await _localFile();
        if (!await file.exists()) {
           print("Fichier $_fileName non trouvé.");
           if (defaultData != null) {
              print("Création de $_fileName avec les données par défaut.");
              await _writeJsonFile(defaultData);
              return defaultData;
           }
           return [];
        }
        final content = await file.readAsString();
        if (content.isEmpty) return [];
        return json.decode(content) as List<dynamic>;
      } catch(e) { print("Erreur lecture $_fileName: $e"); return []; }
  }
  Future<File> _writeJsonFile(List<dynamic> data) async {
     final file = await _localFile();
     return file.writeAsString(json.encode(data));
   }
  // --- Fin Helpers ---

  // Récupère toutes les activités
  Future<List<RelaxationActivity>> getActivities() async {
    final List<dynamic> jsonList = await _readJsonFile(defaultData: _defaultActivities);
    try {
      return jsonList.map((j) => RelaxationActivity.fromJson(j)).toList();
    } catch (e) { print("Erreur parsing activités: $e"); return []; }
  }

  // --- Méthodes Admin ---
  Future<bool> addActivity(RelaxationActivity newActivityData) async {
     // Note: on pourrait passer les champs séparément, mais passer l'objet est plus simple
     // si on crée l'objet dans le formulaire admin d'abord.
     try {
        final activities = await getActivities();
        // Crée l'activité finale avec un nouvel ID unique
        final activityToAdd = RelaxationActivity(
           id: _uuid.v4(), // Génère le nouvel ID ici
           title: newActivityData.title,
           description: newActivityData.description,
           category: newActivityData.category,
           imageUrl: newActivityData.imageUrl,
           durationEstimate: newActivityData.durationEstimate
        );
        activities.add(activityToAdd);
        await _writeJsonFile(activities.map((a) => a.toJson()).toList());
        return true;
     } catch(e) { print("Erreur ajout activité: $e"); return false; }
  }

  Future<bool> updateActivity(RelaxationActivity updatedActivity) async {
      try {
          final activities = await getActivities();
          final index = activities.indexWhere((a) => a.id == updatedActivity.id);
          if (index != -1) {
             activities[index] = updatedActivity; // Remplace
             await _writeJsonFile(activities.map((a) => a.toJson()).toList());
             return true;
          }
          return false; // Non trouvée
      } catch (e) { print("Erreur màj activité: $e"); return false; }
  }

  Future<bool> deleteActivity(String activityId) async {
     try {
         final activities = await getActivities();
         final initialLength = activities.length;
         activities.removeWhere((a) => a.id == activityId);
         if (activities.length < initialLength) {
            await _writeJsonFile(activities.map((a) => a.toJson()).toList());
            return true;
         }
         return false; // Non trouvée
     } catch (e) { print("Erreur suppression activité: $e"); return false; }
  }

  // --- Données par Défaut ---
  final List<Map<String, dynamic>> _defaultActivities = [
    {"id": "act-uuid-1", "title": "Respiration Carrée", "description": "Inspirez pendant 4 secondes, retenez pendant 4 secondes, expirez pendant 4 secondes, retenez pendant 4 secondes. Répétez plusieurs fois pour calmer le système nerveux.", "category": "Pleine conscience", "imageUrl": 'https://axophysio.com/wp-content/uploads/2021/02/respiration-bienfaits-scaled.jpg', "durationEstimate": "5 min"},
    {"id": "act-uuid-2", "title": "Marche en Nature", "description": "Prenez le temps de marcher dans un parc, une forêt ou près de l'eau. Concentrez-vous sur les sons, les odeurs et les sensations autour de vous.", "category": "Nature", "imageUrl": "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?q=80&w=1742&auto=format&fit=crop", "durationEstimate": "30+ min"}, // Exemple URL
    {"id": "act-uuid-3", "title": "Coloriage / Dessin", "description": "Prenez des crayons de couleur et un cahier de coloriage pour adultes ou une feuille blanche. Laissez votre créativité s'exprimer sans jugement.", "category": "Créatif", "imageUrl": 'https://rdvludique.fr/wp-content/uploads/2020/05/Article-coloriage-Marion-barraud.jpg', "durationEstimate": "15-30 min"}
 ];
}