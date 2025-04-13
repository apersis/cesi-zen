import 'package:cesi_zen/utils/helper.dart';
import 'package:cesi_zen/widgets/appbar_screen.dart';
import 'package:cesi_zen/widgets/drawer_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:cesi_zen/services/auth_service.dart'; // Assurez-vous que le chemin est correct

class UserAdminPage extends StatefulWidget {
  const UserAdminPage({super.key});

  @override
  State<UserAdminPage> createState() => _UserAdminPageState();
}

class _UserAdminPageState extends State<UserAdminPage> {
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() { _isLoading = true; _error = null; });
    }
    try {
      final users = await _authService.getAllUsers();
      // Trier peut-être les utilisateurs par nom pour la lisibilité
      users.sort((a, b) => (a['username'] as String? ?? '').compareTo(b['username'] as String? ?? ''));
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur chargement utilisateurs admin: $e");
      if (mounted) {
        setState(() {
          _error = "Impossible de charger les utilisateurs.";
          _isLoading = false;
        });
      }
    }
  }

  // Affiche le formulaire pour ajouter/modifier un utilisateur
  Future<void> _showUserForm({Map<String, dynamic>? userToEdit}) async {
    final _formKey = GlobalKey<FormState>();
    final _usernameController = TextEditingController(text: userToEdit?['username'] ?? '');
    final _passwordController = TextEditingController(); // Toujours vide au début pour edit
    bool _isAdmin = userToEdit?['isAdmin'] ?? false; // Valeur initiale du switch/checkbox
    bool _isSaving = false;
    String? _formError; // Pour afficher les erreurs spécifiques (ex: username unique)

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isSaving,
      builder: (BuildContext context) {
        // Utilise StatefulBuilder pour gérer l'état interne du dialogue (isAdmin, isSaving, formError)
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(userToEdit == null ? 'Ajouter un utilisateur' : 'Modifier l\'utilisateur'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                       if (_formError != null) // Affiche l'erreur du formulaire
                         Padding(
                           padding: const EdgeInsets.only(bottom: 10.0),
                           child: Text(_formError!, style: TextStyle(color: Colors.red)),
                         ),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(labelText: 'Nom d\'utilisateur'),
                        validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                        enabled: !_isSaving,
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            hintText: userToEdit != null ? 'Laisser vide pour ne pas changer' : null, // Indice pour l'édition
                        ),
                        obscureText: true, // Masque le mot de passe
                        validator: (value) {
                          // Requis seulement si on ajoute un nouvel utilisateur
                          if (userToEdit == null && (value == null || value.isEmpty)) {
                            return 'Mot de passe requis pour un nouvel utilisateur';
                          }
                          return null; // Optionnel si modification
                        },
                        enabled: !_isSaving,
                      ),
                       SizedBox(height: 10),
                       // Utilise SwitchListTile pour le booléen isAdmin
                       SwitchListTile(
                          title: Text('Administrateur'),
                          value: _isAdmin,
                          onChanged: _isSaving ? null : (bool value) {
                             setDialogState(() { // Met à jour l'état interne du dialogue
                               _isAdmin = value;
                             });
                          },
                          secondary: Icon(Icons.admin_panel_settings),
                          contentPadding: EdgeInsets.zero, // Ajuste le padding si besoin
                       )
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                  child: Text('Annuler'),
                ),
                ElevatedButton.icon(
                  icon: _isSaving ? SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.save),
                  label: Text(_isSaving ? 'Sauvegarde...' : 'Sauvegarder'),
                  onPressed: _isSaving ? null : () async {
                    // Réinitialise l'erreur avant validation
                     setDialogState(() => _formError = null);

                    if (_formKey.currentState!.validate()) {
                       setDialogState(() => _isSaving = true);

                       bool success = false;
                       String? errorMessage; // Pour les erreurs spécifiques du service

                       final username = _usernameController.text;
                       final password = _passwordController.text; // Sera vide si non modifié
                       final isAdmin = _isAdmin; // Depuis l'état du dialogue

                       try {
                          if (userToEdit == null) { // Ajout
                            // Vérifie l'unicité du username avant d'enregistrer
                            final existingUsers = await _authService.getAllUsers();
                            if(existingUsers.any((u) => u['username'] == username)) {
                                errorMessage = "Ce nom d'utilisateur existe déjà.";
                                success = false;
                            } else {
                                success = await _authService.register(username, password, isAdmin);
                            }
                          } else { // Modification
                            // Appelle updateUser, passe null pour password si vide
                            success = await _authService.updateUser(
                              userToEdit['userId'], // Utilise l'ID pour identifier
                              username,
                              password.isEmpty ? null : password, // Ne passe le mdp que s'il n'est pas vide
                              isAdmin
                            );
                            // AuthService gère la vérification d'unicité lors de l'update
                            if (!success && !mounted) { // Vérifie si l'erreur vient de l'unicité (AuthService retourne false)
                                // On pourrait améliorer AuthService pour retourner des erreurs spécifiques
                                final existingUsers = await _authService.getAllUsers();
                                if(existingUsers.any((u) => u['userId'] != userToEdit['userId'] && u['username'] == username)) {
                                   errorMessage = "Ce nom d'utilisateur existe déjà.";
                                }
                            }
                          }
                       } catch (e) {
                           print("Erreur sauvegarde user: $e");
                           errorMessage = "Une erreur inattendue s'est produite.";
                           success = false;
                       }


                       if (!mounted) return; // Vérifie avant de manipuler l'état/contexte principal

                       if (success) {
                          Navigator.of(context).pop(true); // Ferme avec succès
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Utilisateur sauvegardé !'), backgroundColor: Colors.green));
                       } else {
                           // Affiche l'erreur spécifique si disponible, sinon une erreur générique
                           setDialogState(() {
                              _isSaving = false;
                              _formError = errorMessage ?? 'Erreur de sauvegarde.';
                           });
                       }
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );

     // Recharge les données si succès
     if (result == true) {
       _loadUsers(showLoading: false);
     }
  }

  // Confirme et supprime un utilisateur
  Future<void> _confirmDeleteUser(Map<String, dynamic> user) async {
      // Idéalement, récupérer l'utilisateur actuel pour empêcher l'auto-suppression
      // final currentUser = await _sessionManager.getLoggedInUsername(); // ou userId
      // if (currentUser == user['username']) { ... afficher message ... return; }

      final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('Confirmer la suppression'),
                content: Text('Voulez-vous vraiment supprimer l\'utilisateur "${user['username']}" ?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Annuler')),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Supprimer')
                  ),
                ],
              ));

      if (confirm == true) {
        setState(() => _isLoading = true );
        final success = await _authService.deleteUser(user['userId']); // Utilise l'ID
         if (!mounted) return;
         if (success) {
            //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Utilisateur supprimé.'), backgroundColor: Colors.green));
            _loadUsers(showLoading: false);
         } else {
             setState(() => _isLoading = false );
             //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de suppression.'), backgroundColor: Colors.red));
         }
      }
  }



  // --- Widgets ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: Colors.red)));
    }

    return Scaffold( 
      drawer: DrawerMenuWidget(pageType: PageType.adminAccount),
      appBar: PreferredSize(
        preferredSize: Size(0, 60),
        child: AppBarScreen(pageName: "Admin utilisateur"),
      ),
      body: _buildAdminBody()
    );

  }

  // Nouvelle méthode pour construire le contenu du body
  Widget _buildAdminBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_error!, style: TextStyle(color: Colors.red))));
    }
    if (_users.isEmpty) {
      // Gère le cas où il n'y a aucun utilisateur (même après chargement)
      return Column( // Utilise Column pour pouvoir mettre le bouton Ajouter
        children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Ajouter un premier utilisateur'),
                onPressed: () => _showUserForm(),
              ),
            ),
            Expanded(child: Center(child: Text("Aucun utilisateur trouvé."))),
        ],
      );
    }
    // Si chargement OK et utilisateurs présents, retourne la Column avec bouton + liste
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('Ajouter un utilisateur'),
            onPressed: () => _showUserForm(), // Ouvre le formulaire d'ajout
            style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(40)), // Prend plus de largeur
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              final bool isAdmin = user['isAdmin'] ?? false;
              return ListTile(
                leading: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person),
                title: Text(user['username'] ?? 'Nom invalide'),
                subtitle: Text(isAdmin ? 'Administrateur' : 'Utilisateur standard'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                      tooltip: 'Modifier',
                      onPressed: () => _showUserForm(userToEdit: user),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_forever, color: Colors.red[700]),
                      tooltip: 'Supprimer',
                      onPressed: () => _confirmDeleteUser(user),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}