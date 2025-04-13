import 'dart:convert';
import 'dart:io';
import 'package:cesi_zen/models/diagnostic_item.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
// Importe tes modèles si tu les as mis dans des fichiers séparés
// import 'package:cesi_zen/models/diagnostic_item.dart';
// import 'package:cesi_zen/models/diagnosis_result.dart';

// Colle ici les définitions des classes DiagnosticItem et DiagnosisResult
// si tu ne les as pas mises dans des fichiers séparés.
// class DiagnosticItem { ... }
// class DiagnosisResult { ... }

class DiagnosticService {
  static const String _itemsFileName = 'diagnostic_items.json';
  static const String _resultsFileName = 'diagnosis_results.json';
  final _uuid = Uuid(); // Instance pour générer des IDs

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

  // Helper pour écrire les items dans le fichier JSON
  Future<File> _saveItems(List<DiagnosticItem> items) async {
    final file = await _localFile(_itemsFileName);
    // Convertit la liste d'objets en liste de Maps JSON
    final List<Map<String, dynamic>> jsonList = items.map((item) => item.toJson()).toList();
    final String jsonString = json.encode(jsonList);
    print("Sauvegarde des items de diagnostic...");
    return file.writeAsString(jsonString);
  }

  // Helper pour écrire les résultats dans le fichier JSON
  Future<File> _saveResults(List<DiagnosisResult> results) async {
    final file = await _localFile(_resultsFileName);
    final List<Map<String, dynamic>> jsonList = results.map((result) => result.toJson()).toList();
    final String jsonString = json.encode(jsonList);
     print("Sauvegarde des résultats de diagnostic...");
    return file.writeAsString(jsonString);
  }

  Future<bool> addItem(String description, int weight) async {
    try {
      final items = await getItems(); // Lit les items actuels
      final newItem = DiagnosticItem(
        id: _uuid.v4(), // Génère un ID unique
        description: description,
        weight: weight,
      );
      items.add(newItem); // Ajoute le nouvel item
      await _saveItems(items); // Sauvegarde la liste complète
      return true;
    } catch (e) {
      print("Erreur lors de l'ajout de l'item: $e");
      return false;
    }
  }

  Future<bool> updateItem(DiagnosticItem updatedItem) async {
    try {
      final items = await getItems();
      final index = items.indexWhere((item) => item.id == updatedItem.id); // Trouve l'item par ID
      if (index != -1) {
        items[index] = updatedItem; // Remplace l'ancien item par le nouveau
        await _saveItems(items);
        return true;
      }
      print("Item non trouvé pour mise à jour: ${updatedItem.id}");
      return false; // Item non trouvé
    } catch (e) {
      print("Erreur lors de la mise à jour de l'item ${updatedItem.id}: $e");
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      final items = await getItems();
      final initialLength = items.length;
      items.removeWhere((item) => item.id == itemId); // Supprime l'item par ID
      if (items.length < initialLength) { // Vérifie si la suppression a eu lieu
        await _saveItems(items);
        return true;
      }
      print("Item non trouvé pour suppression: $itemId");
      return false; // Item non trouvé
    } catch (e) {
      print("Erreur lors de la suppression de l'item $itemId: $e");
      return false;
    }
  }

  // --- Méthodes d'Écriture pour les Résultats ---

  Future<bool> addResult(int minScore, int maxScore, String title, String text, int? risk) async {
     try {
        final results = await getResults();
        final newResult = DiagnosisResult(
           id: _uuid.v4(),
           minScore: minScore,
           maxScore: maxScore,
           diagnosisTitle: title,
           diagnosisText: text,
           riskPercentage: risk
        );
        results.add(newResult);
        await _saveResults(results);
        return true;
     } catch (e) {
         print("Erreur lors de l'ajout du résultat: $e");
         return false;
     }
  }

 Future<bool> updateResult(DiagnosisResult updatedResult) async {
    try {
      final results = await getResults();
      final index = results.indexWhere((result) => result.id == updatedResult.id);
      if (index != -1) {
        results[index] = updatedResult;
        await _saveResults(results);
        return true;
      }
       print("Résultat non trouvé pour mise à jour: ${updatedResult.id}");
      return false;
    } catch (e) {
       print("Erreur lors de la mise à jour du résultat ${updatedResult.id}: $e");
      return false;
    }
  }

 Future<bool> deleteResult(String resultId) async {
     try {
        final results = await getResults();
        final initialLength = results.length;
        results.removeWhere((result) => result.id == resultId);
        if (results.length < initialLength) {
           await _saveResults(results);
           return true;
        }
         print("Résultat non trouvé pour suppression: $resultId");
        return false;
     } catch (e) {
        print("Erreur lors de la suppression du résultat $resultId: $e");
        return false;
     }
  }

  // Helper pour lire et décoder un fichier JSON
  Future<List<dynamic>> _readJsonFile(String fileName) async {
    try {
      final file = await _localFile(fileName);
      if (!await file.exists()) {
        print("Le fichier $fileName n'existe pas. Tentative de création...");
        // Si le fichier n'existe pas, on pourrait le créer avec des données par défaut
        // ou simplement retourner une liste vide. Pour l'instant, on retourne vide.
        // Pour le créer, il faudrait copier depuis les assets ou écrire les données par défaut ici.
        // Voir la note plus bas sur la création initiale.
        if (fileName == _itemsFileName) {
          await _writeJsonFile(fileName, _defaultItems); // Écrit les items par défaut
          return _defaultItems; // Retourne la liste par défaut
        } else if (fileName == _resultsFileName) {
           await _writeJsonFile(fileName, _defaultResults); // Écrit les résultats par défaut
           return _defaultResults; // Retourne les résultats par défaut
        }
        return [];
      }
      final contents = await file.readAsString();
      // Gère le cas où le fichier est vide
      if (contents.isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList;
    } catch (e) {
      print("Erreur de lecture du fichier $fileName: $e");
      return []; // Retourne une liste vide en cas d'erreur
    }
  }

   // Helper pour écrire dans un fichier JSON
   Future<File> _writeJsonFile(String fileName, List<dynamic> data) async {
     final file = await _localFile(fileName);
     final String jsonString = json.encode(data);
     print("Écriture dans $fileName");
     return file.writeAsString(jsonString);
   }


  // --- Méthodes Publiques ---

  // Récupère la liste des items de diagnostic
  Future<List<DiagnosticItem>> getItems() async {
    final List<dynamic> jsonList = await _readJsonFile(_itemsFileName);
    try {
      // Convertit la liste de Maps JSON en liste d'objets DiagnosticItem
      return jsonList
      .map((jsonItem) => DiagnosticItem.fromJson(jsonItem as Map<String, dynamic>))
      .toList() // 1. Crée la liste List<DiagnosticItem>
    ..sort((a, b) => b.weight.compareTo(a.weight)); // 2. Trie la liste en place par poids décroissant

    } catch (e) {
       print("Erreur de parsing des items: $e");
       return []; // Retourne vide si le parsing échoue
    }
  }

  // Récupère la liste des résultats de diagnostic
  Future<List<DiagnosisResult>> getResults() async {
    final List<dynamic> jsonList = await _readJsonFile(_resultsFileName);
     try {
      // Convertit la liste de Maps JSON en liste d'objets DiagnosisResult
      return jsonList.map((jsonItem) => DiagnosisResult.fromJson(jsonItem as Map<String, dynamic>)).toList();
     } catch (e) {
        print("Erreur de parsing des résultats: $e");
        return []; // Retourne vide si le parsing échoue
     }
  }


  // --- Données par Défaut (Utilisées si les fichiers n'existent pas) ---
  // (Tu peux externaliser ces listes si elles deviennent trop grandes)

  final List<Map<String, dynamic>> _defaultItems = [
      {"id": "h1", "description": "Décès du conjoint", "weight": 100}, {"id": "h2", "description": "Divorce", "weight": 73}, {"id": "h3", "description": "Séparation", "weight": 65}, {"id": "h4", "description": "Séjour en prison", "weight": 63}, {"id": "h5", "description": "Décès d’un proche parent", "weight": 63}, {"id": "h6", "description": "Maladies ou blessures personnelles", "weight": 53}, {"id": "h7", "description": "Mariage", "weight": 50}, {"id": "h8", "description": "Perte d’emploi", "weight": 47}, {"id": "h9", "description": "Réconciliation avec le conjoint", "weight": 45}, {"id": "h10", "description": "Retraite", "weight": 45}, {"id": "h11", "description": "Modification de l’état de santé d’un membre de la famille", "weight": 44}, {"id": "h12", "description": "Grossesse", "weight": 40}, {"id": "h13", "description": "Difficultés sexuelles", "weight": 39}, {"id": "h14", "description": "Ajout d’un membre dans la famille", "weight": 39}, {"id": "h15", "description": "Changement dans la vie professionnelle", "weight": 39}, {"id": "h16", "description": "Modification de la situation financière", "weight": 38}, {"id": "h17", "description": "Mort d’un ami proche", "weight": 37}, {"id": "h18", "description": "Changement de carrière", "weight": 36}, {"id": "h19", "description": "Modification du nombre de disputes avec le conjoint", "weight": 35}, {"id": "h20", "description": "Hypothèque supérieure à un an de salaire", "weight": 31}, {"id": "h21", "description": "Saisie d’hypothèque ou de prêt", "weight": 30}, {"id": "h22", "description": "Modification de ses responsabilités professionnelles", "weight": 29}, {"id": "h23", "description": "Départ de l’un des enfants", "weight": 29}, {"id": "h24", "description": "Problème avec les beaux-parents", "weight": 29}, {"id": "h25", "description": "Succès personnel éclatant", "weight": 28}, {"id": "h26", "description": "Début ou fin d’emploi du conjoint", "weight": 26}, {"id": "h27", "description": "Première ou dernière année d’études", "weight": 26}, {"id": "h28", "description": "Modification de ses conditions de vie", "weight": 25}, {"id": "h29", "description": "Changements dans ses habitudes personnelles", "weight": 24}, {"id": "h30", "description": "Difficultés avec son patron", "weight": 23}, {"id": "h31", "description": "Modification des heures et des conditions de travail", "weight": 20}, {"id": "h32", "description": "Changement de domicile", "weight": 20}, {"id": "h33", "description": "Changement d’école", "weight": 20}, {"id": "h34", "description": "Changement du type ou de la quantité de loisirs", "weight": 19}, {"id": "h35", "description": "Modification des activités religieuses", "weight": 19}, {"id": "h36", "description": "Modification des activités sociales", "weight": 18}, {"id": "h37", "description": "Hypothèque ou prêt inférieur à un an de salaire", "weight": 17}, {"id": "h38", "description": "Modification des habitudes de sommeil", "weight": 16}, {"id": "h39", "description": "Modification du nombre de réunions familiales", "weight": 15}, {"id": "h40", "description": "Modification des habitudes alimentaires", "weight": 15}, {"id": "h41", "description": "Voyage ou vacances", "weight": 13}, {"id": "h42", "description": "Noël", "weight": 12}, {"id": "h43", "description": "Infractions mineures à la loi", "weight": 11}
  ];

  final List<Map<String, dynamic>> _defaultResults = [
     {"id": "r1", "minScore": 0, "maxScore": 99, "diagnosisTitle": "Stress modéré", "riskPercentage": 30, "diagnosisText": "En dessous de 100, le risque se révèle peu important. La somme des stress rencontrés est trop peu importante pour ouvrir la voie à une maladie somatique."},
     {"id": "r2", "minScore": 100, "maxScore": 300, "diagnosisTitle": "Stress élevé", "riskPercentage": 51, "diagnosisText": "Ces risques diminuent en même temps que votre score total. Toutefois si votre score est compris entre 300 et 100, les risques que se déclenche une éventuelle maladie somatique demeure statistiquement significatif. Prenez soin de vous. Ce n’est pas la peine d’en rajouter."},
     {"id": "r3", "minScore": 301, "maxScore": 99999, "diagnosisTitle": "Stress très élevé", "riskPercentage": 80, "diagnosisText": "Si votre score de stress vécu au cours des 12 derniers mois dépasse 300, vos risques de présenter dans un avenir proche, une maladie somatique, sont très élevés.\nUn score de 300 et plus suppose que vous avez eu à traverser une série de situations particulièrement pénibles et éprouvantes. Ne craignez donc pas de vous faire aider si c’est votre cas."}
  ];

}