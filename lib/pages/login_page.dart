import 'package:cesi_zen/services/auth_service.dart';
import 'package:cesi_zen/services/session_manager.dart';
import 'package:cesi_zen/utils/helper.dart';
import 'package:cesi_zen/widgets/appbar_screen.dart';
import 'package:cesi_zen/widgets/drawer_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _sessionManager = SessionManager();
  String _errorMessage = '';
  bool _isLoading = false;
  

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
         _errorMessage = 'Veuillez remplir tous les champs.';
         _isLoading = false;
      });
      return;
    }

    final user = await _authService.login(username, password);

    setState(() { _isLoading = false; });

    if (user != null && mounted) { // Vérifie si le widget est toujours monté
      // Connexion réussie
      final bool actualAdminStatus = user['isAdmin'] ?? false;
      await _sessionManager.saveSession(user['username'], actualAdminStatus);

      if (!mounted) return;
        final scaffoldMessenger = ScaffoldMessenger.of(context); // Récupère le ScaffoldMessenger
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Connexion réussie ! Bienvenue ${user['username']}.'),
            duration: Duration(seconds: 2), // Durée d'affichage
            backgroundColor: Colors.green, // Couleur pour succès
          ),
        );
        
      // Naviguer vers la page d'accueil et supprimer la page de connexion de la pile
      if (actualAdminStatus){
      context.goNamed("adminInfo");
      }else{
        context.goNamed("info");
      }
    } else if (mounted) {
      // Échec de la connexion
      setState(() {
        _errorMessage = 'Nom d\'utilisateur ou mot de passe incorrect.';
      });
    }
  }

  // Optionnel: Fonction pour l'enregistrement
  Future<void> _register() async {
     // Logique similaire à _login, mais appelle _authService.register
     // Affiche un message de succès/échec
     // Par exemple:
     final username = _usernameController.text.trim();
     final password = _passwordController.text.trim();
     final bool isAdmin = false;
     if (username.isEmpty || password.isEmpty) { /* ... */ return; }
     setState(() { _isLoading = true; _errorMessage = ''; });
     bool success = await _authService.register(username, password, isAdmin);
     setState(() { _isLoading = false; });
     if (success) {
        setState(() { _errorMessage = 'Compte créé! Vous pouvez vous connecter.'; });
     } else {
        setState(() { _errorMessage = 'Erreur lors de la création du compte (peut-être déjà existant).'; });
     }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerMenuWidget(pageType: PageType.login),
      appBar: PreferredSize(
        preferredSize: Size(0, 60),
        child: AppBarScreen(pageName: "Connexion"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Nom d\'utilisateur'),
              enabled: !_isLoading,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
              enabled: !_isLoading,
            ),
            SizedBox(height: 30),
            /*Text("Admin ?"),
            Switch(
              value: _adminController, 
              onChanged: (bool value){
                setState(() {
                  _adminController = value;
                });
            }),
            */
            SizedBox(height: 50),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
              ),
            if (_isLoading)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _login,
                child: Text('Se Connecter'),
              ),
            // Optionnel: Bouton pour s'enregistrer
            SizedBox(height: 20),
            TextButton(
              onPressed: _isLoading ? null : _register,
              child: Text('Créer un compte'),
             )
          ],
        ),
      ),
    );
  }
}