import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  static const String _fileName = 'users.json';
  final _uuid = Uuid();

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  // Lire les utilisateurs depuis le fichier JSON
  Future<List<Map<String, dynamic>>> _readUsers() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        // Si le fichier n'existe pas, le créer avec une liste vide (ou des utilisateurs par défaut)
        await _writeUsers([]);
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = json.decode(contents);
      // S'assurer que chaque élément est bien un Map<String, dynamic>
      return jsonList.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print("Erreur de lecture du fichier users: $e");
      // Retourner une liste vide en cas d'erreur (ou gérer autrement)
      return [];
    }
  }

  // Écrire la liste des utilisateurs dans le fichier JSON (pour l'enregistrement par exemple)
  Future<File> _writeUsers(List<Map<String, dynamic>> users) async {
    final file = await _localFile;
    final String jsonString = json.encode(users);
    return file.writeAsString(jsonString);
  }

  // Fonction de Connexion
  Future<Map<String, dynamic>?> login(String username, String password) async {
    final users = await _readUsers();
    for (var user in users) {
      // !! COMPARAISON EN TEXTE CLAIR - NON SÉCURISÉ !!
      if (user['username'] == username && user['password'] == password) {
        print("Connexion réussie pour $username");
        return user; // Retourne les infos de l'utilisateur connecté
      }
    }
    print("Échec de la connexion pour $username");
    return null; // Aucun utilisateur trouvé ou mot de passe incorrect
  }

  // Register: Modifié pour ajouter userId et accepter isAdmin
  Future<bool> register(String username, String password, bool isAdmin) async {
    // !! RAPPEL : Stockage en clair non sécurisé !!
    try {
      final users = await _readUsers();
      // Vérifier si l'utilisateur existe déjà par username
      if (users.any((user) => user['username'] == username)) {
        print("L'utilisateur $username existe déjà.");
        return false;
      }
      // Ajouter le nouvel utilisateur avec un userId
      final newUser = {
        'userId': _uuid.v4(), // Génère un ID unique
        'username': username,
        'password': password,
        'isAdmin': isAdmin
      };
      users.add(newUser);
      await _writeUsers(users); // _writeUsers doit accepter List<dynamic> ou List<Map<String, dynamic>>
      print("Utilisateur $username enregistré avec isAdmin=$isAdmin.");
      return true;
    } catch (e) {
       print("Erreur lors de l'enregistrement de $username: $e");
       return false;
    }
  }

  // Nouvelle méthode pour mettre à jour le mot de passe
  Future<bool> updatePassword(String username, String newPassword) async {
    // !! RAPPEL : Stockage en clair non sécurisé !!
    try {
      final users = await _readUsers();
      // Trouve l'index de l'utilisateur
      final userIndex = users.indexWhere((user) => user['username'] == username);

      if (userIndex != -1) {
        // Met à jour le mot de passe pour cet utilisateur
        users[userIndex]['password'] = newPassword;
        // Réécrit le fichier avec la liste mise à jour
        await _writeUsers(users);
        print("Mot de passe mis à jour pour $username.");
        return true; // Succès
      } else {
        print("Utilisateur $username non trouvé pour la mise à jour du mot de passe.");
        return false; // Utilisateur non trouvé
      }
    } catch (e) {
      print("Erreur lors de la mise à jour du mot de passe pour $username: $e");
      return false; // Erreur
    }
  }

  // Nouvelle méthode pour supprimer un compte
  Future<bool> deleteAccount(String username) async {
    try {
      final users = await _readUsers();
      final initialLength = users.length;
      // Supprime l'utilisateur de la liste
      users.removeWhere((user) => user['username'] == username);

      // Vérifie si un utilisateur a bien été supprimé
      if (users.length < initialLength) {
        // Réécrit le fichier avec la liste mise à jour
        await _writeUsers(users);
        print("Compte $username supprimé.");
        return true; // Succès
      } else {
        print("Utilisateur $username non trouvé pour la suppression.");
        return false; // Utilisateur non trouvé
      }
    } catch (e) {
      print("Erreur lors de la suppression du compte $username: $e");
      return false; // Erreur
    }
  }
  // Récupère TOUS les utilisateurs
   Future<List<Map<String, dynamic>>> getAllUsers() async {
       final List<dynamic> usersDynamic = await _readUsers();
       // Convertit en List<Map<String, dynamic>> si nécessaire
       return usersDynamic.whereType<Map<String, dynamic>>().toList();
   }

   // Met à jour un utilisateur existant par userId
   Future<bool> updateUser(String userId, String newUsername, String? newPassword, bool newIsAdmin) async {
      // !! RAPPEL : Stockage en clair non sécurisé !!
      try {
         final users = await getAllUsers(); // Récupère la liste actuelle
         final index = users.indexWhere((user) => user['userId'] == userId);

         if (index == -1) {
            print("Utilisateur non trouvé pour mise à jour: $userId");
            return false; // Utilisateur non trouvé
         }

         // Vérifier l'unicité du nouveau nom d'utilisateur (s'il a changé)
         if (users[index]['username'] != newUsername && users.any((user) => user['userId'] != userId && user['username'] == newUsername)) {
             print("Erreur: Le nom d'utilisateur '$newUsername' est déjà pris.");
             // Idéalement, retourner un code d'erreur spécifique ou lancer une exception ici
             return false; // Nom d'utilisateur déjà pris
         }

         // Met à jour les champs
         users[index]['username'] = newUsername;
         users[index]['isAdmin'] = newIsAdmin;
         // Met à jour le mot de passe SEULEMENT s'il est fourni et non vide
         if (newPassword != null && newPassword.isNotEmpty) {
            users[index]['password'] = newPassword;
            print("Mot de passe mis à jour pour l'utilisateur $userId.");
         } else {
            print("Mot de passe non modifié pour l'utilisateur $userId.");
         }

         await _writeUsers(users); // Sauvegarde la liste complète
         print("Utilisateur $userId mis à jour.");
         return true;

      } catch (e) {
          print("Erreur lors de la mise à jour de l'utilisateur $userId: $e");
          return false;
      }
   }

   // Supprime un utilisateur par userId
   Future<bool> deleteUser(String userId) async {
       try {
          final users = await getAllUsers();
          final initialLength = users.length;
          users.removeWhere((user) => user['userId'] == userId);

          if (users.length < initialLength) {
             await _writeUsers(users);
             print("Utilisateur $userId supprimé.");
             return true;
          } else {
             print("Utilisateur non trouvé pour suppression: $userId");
             return false;
          }
       } catch (e) {
           print("Erreur lors de la suppression de l'utilisateur $userId: $e");
           return false;
       }
   }

}