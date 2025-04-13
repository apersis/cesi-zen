import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _usernameKey = 'loggedInUsername';
  static const String _isAdminKey = 'isAdmin';

  Future<void> saveSession(String username, bool isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_usernameKey, username);
    await prefs.setBool(_isAdminKey, isAdmin);
    print("Session sauvegardée pour $username");
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_isAdminKey);
    print("Session effacée");
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<String?> getLoggedInUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAdminKey) ?? false;
  }

  // NOUVELLE MÉTHODE: Récupère toutes les infos de session en une fois
  Future<UserSession> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey);
    final isAdmin = prefs.getBool(_isAdminKey) ?? false;
    // Crée et retourne l'objet UserSession
    return UserSession(username: username, isAdmin: isAdmin);
  }
}

// Créons une petite classe pour contenir les données de session
class UserSession {
  final String? username;
  final bool isAdmin;
  final bool isLoggedIn; // Dérivé de username

  UserSession({this.username, this.isAdmin = false})
      : isLoggedIn = username != null; // isLoggedIn est vrai si username n'est pas null
}