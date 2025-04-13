import 'package:cesi_zen/services/auth_service.dart'; // <-- Importe AuthService
import 'package:cesi_zen/services/session_manager.dart';
import 'package:cesi_zen/utils/helper.dart';
import 'package:cesi_zen/widgets/appbar_screen.dart';
import 'package:cesi_zen/widgets/drawer_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // <-- Importe go_router pour la navigation

class UserPage extends StatefulWidget {
  @override
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final _sessionManager = SessionManager();
  final _authService = AuthService(); // Instance de AuthService
  final _passwordController = TextEditingController(); // Controller pour le nouveau mdp

  String? _username;
  bool _isPasswordChanging = false;
  bool _isDeleting = false; // Pour l'état de chargement de la suppression

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  @override
  void dispose() {
    _passwordController.dispose(); // N'oublie pas de dispose le controller
    super.dispose();
  }

  Future<void> _loadUsername() async {
    //final username = await _sessionManager.getLoggedInUsername();
    final UserSession _session = await _sessionManager.getUserSession();
    final username = _session.username;
    if (mounted) {
      setState(() {
        _username = username;
      });
    }
  }

  // --- Logique pour changer le mot de passe ---
  Future<void> _changePassword() async {
    if (_username == null || _isPasswordChanging) return; // Sécurité

    final newPassword = _passwordController.text.trim();
    if (newPassword.isEmpty) {
      // Affiche une erreur si le champ est vide
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez entrer un nouveau mot de passe.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() { _isPasswordChanging = true; });

    final success = await _authService.updatePassword(_username!, newPassword);

    if (mounted) { // Vérifie si le widget est toujours là
       setState(() { _isPasswordChanging = false; });

        if (success) {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Mot de passe mis à jour avec succès !'),
                backgroundColor: Colors.green,
              ),
            );
           _passwordController.clear(); // Vide le champ après succès
           FocusScope.of(context).unfocus(); // Masque le clavier
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de la mise à jour du mot de passe.'),
                backgroundColor: Colors.red,
              ),
           );
        }
    }
  }

  // --- Logique pour la suppression de compte (avec confirmation) ---
  Future<void> _confirmDeleteAccount() async {
    if (_username == null || _isDeleting) return;

    // Affiche la pop-up de confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Supprimer le compte'),
          content: Text('Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Retourne false
              child: Text('Annuler'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red), // Style pour danger
              onPressed: () => Navigator.of(context).pop(true), // Retourne true
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );

    // Si l'utilisateur a confirmé (confirm == true)
    if (confirm == true) {
      _deleteAccount(); // Appelle la fonction de suppression réelle
    }
  }

  // Fonction qui effectue réellement la suppression
  Future<void> _deleteAccount() async {
      if (_username == null) return; // Double vérification

      setState(() { _isDeleting = true; });

      final success = await _authService.deleteAccount(_username!);

      if (!mounted) return; // Vérifie avant d'utiliser le context

      if (success) {
         // Efface la session
         await _sessionManager.clearSession();

         // Affiche un message de succès (avant de naviguer)
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Compte supprimé avec succès.'),
              backgroundColor: Colors.green,
            ),
         );

         // Attendre un peu pour que le SnackBar soit visible
         await Future.delayed(Duration(milliseconds: 500));

         if (!mounted) return; // Re-vérifie

         // Redirige vers la page de connexion
         context.goNamed('info');

      } else {
          // Erreur lors de la suppression
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Erreur lors de la suppression du compte.'),
               backgroundColor: Colors.red,
             ),
          );
          setState(() { _isDeleting = false; }); // Permet de réessayer
      }
      // Note: On ne remet _isDeleting à false que en cas d'erreur,
      // car en cas de succès on quitte la page.
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerMenuWidget(pageType: PageType.user),
      appBar: PreferredSize(
        preferredSize: Size(0, 60),
        child: AppBarScreen(pageName: "Compte utilisateur"),
      ),
      // Utilise un SingleChildScrollView pour éviter les problèmes de dépassement si le clavier s'affiche
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Ajoute du padding autour
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centre verticalement (approximativement)
            crossAxisAlignment: CrossAxisAlignment.stretch, // Étire les éléments horizontalement
            children: [
              // Affiche le message de bienvenue (si username est chargé)
              if (_username != null)
                 Padding(
                   padding: const EdgeInsets.only(bottom: 24.0),
                   child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Centre verticalement (approximativement)
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Étire les éléments horizontalement
                    children: [
                      Text(
                        'Bienvenue dans votre espace, $_username !',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),

                  ])
                 ),
              if (_username == null) // Affiche un indicateur si username n'est pas encore chargé
                 Center(child: CircularProgressIndicator()),

              SizedBox(height: 20),

              // --- Section Changement de Mot de Passe ---
              Text("Changer le mot de passe :", style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true, // Masque le mot de passe
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isPasswordChanging, // Désactive si opération en cours
              ),
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: (_username == null || _isPasswordChanging) ? null : _changePassword, // Désactive si username pas chargé ou opération en cours
                icon: _isPasswordChanging
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.key),
                label: Text(_isPasswordChanging ? 'Modification...' : 'Changer le mot de passe'),
              ),

              SizedBox(height: 40), // Espace avant la zone de danger

              // --- Section Suppression de Compte ---
              Text("Zone de danger :", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red[700])),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: (_username == null || _isDeleting) ? null : _confirmDeleteAccount, // Désactive si username pas chargé ou opération en cours
                icon: _isDeleting
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.delete_forever),
                label: Text(_isDeleting ? 'Suppression...' : 'Supprimer mon compte'),
                // Style pour indiquer une action dangereuse
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700], // Fond rouge
                  foregroundColor: Colors.white,     // Texte blanc
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}