import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {

  // Helper pour construire la clé SharedPreferences spécifique à l'utilisateur
  String _getFavKey(String userId) => 'fav_activities_$userId';

  // Récupère les IDs favoris pour un utilisateur
  Future<Set<String>> getFavoriteActivityIds(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? favList = prefs.getStringList(_getFavKey(userId));
      if (favList == null) {
        return {}; // Retourne un Set vide si la clé n'existe pas
      }
      return favList.toSet(); // Convertit la liste en Set
    } catch (e) {
      print("Erreur lecture favoris: $e");
      return {}; // Retourne vide en cas d'erreur
    }
  }

  // Vérifie si une activité est favorite
  Future<bool> isFavorite(String userId, String activityId) async {
    final favIds = await getFavoriteActivityIds(userId);
    return favIds.contains(activityId);
  }

  // Ajoute une activité aux favoris
  Future<void> addFavorite(String userId, String activityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favIds = await getFavoriteActivityIds(userId);
      if (favIds.add(activityId)) { // add retourne true si l'élément n'était pas déjà présent
        await prefs.setStringList(_getFavKey(userId), favIds.toList()); // Sauvegarde la liste mise à jour
         print("Favori ajouté: $activityId pour $userId");
      }
    } catch (e) {
       print("Erreur ajout favori: $e");
    }
  }

  // Retire une activité des favoris
  Future<void> removeFavorite(String userId, String activityId) async {
     try {
        final prefs = await SharedPreferences.getInstance();
        final favIds = await getFavoriteActivityIds(userId);
        if (favIds.remove(activityId)) { // remove retourne true si l'élément était présent et a été retiré
           await prefs.setStringList(_getFavKey(userId), favIds.toList()); // Sauvegarde la liste mise à jour
           print("Favori retiré: $activityId pour $userId");
        }
     } catch (e) {
        print("Erreur retrait favori: $e");
     }
  }
}