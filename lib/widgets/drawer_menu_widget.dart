import 'package:cesi_zen/services/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cesi_zen/utils/helper.dart';

class DrawerMenuWidget extends StatelessWidget{

  @override
  const DrawerMenuWidget({super.key, required this.pageType});

  final PageType pageType;

  // On garde la fonction _logout séparée pour la clarté
  Future<void> _logout(BuildContext context) async {
    final sessionManager = SessionManager();
    if (!context.mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Déconnexion réussie.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue, // Ou une autre couleur appropriée
        ),
      );
    await sessionManager.clearSession();
    if (!context.mounted) return;
    Navigator.pop(context); // Ferme le drawer
    context.goNamed("info"); // Navigue vers login
  }

  @override
  Widget build(BuildContext context) {
    // Style commun pour les titres, pour correspondre à _MenuItem

    final sessionManager = SessionManager();

    const TextStyle titleStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.black, // Assure-toi que c'est la bonne couleur par défaut
    );
    const double iconSize = 30; // Taille d'icône cohérente

    

    return Drawer(
      semanticLabel: "Menu de l'application",
      backgroundColor: Colors.white,
      child: FutureBuilder<UserSession>( // Utilise FutureBuilder pour attendre le résultat de isLoggedIn
        future: sessionManager.getUserSession(), // Récupère le nom d'utilisateur (ou null)
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print("Erreur DrawerHeader: ${snapshot.error}"); // Log l'erreur
            return const Center(child: Text("Erreur session"));
          } else {
            final UserSession session = snapshot.data ?? UserSession();
            final String? username = session.username;
            final bool isAdmin = session.isAdmin;
            final bool isLoggedIn = session.isLoggedIn; // Directement depuis l'objet

            // Construit le ListView basé sur l'état de connexion
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                ExcludeSemantics(
                  child: DrawerHeader(
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary),
                    child: Image.asset("assets/extended_logo.png"),
                  ),
                ),

                // Affiche les éléments de menu utilisateur
                if (!isAdmin) ...[
                  _MenuItem(pageType: PageType.info, isSelected: pageType == PageType.info),
                  _MenuItem(pageType: PageType.diagnostics, isSelected: pageType == PageType.diagnostics),
                  _MenuItem(pageType: PageType.breath, isSelected: pageType == PageType.breath),
                  _MenuItem(pageType: PageType.activity, isSelected: pageType == PageType.activity),
                  _MenuItem(pageType: PageType.funcat, isSelected: pageType == PageType.funcat),
                  if (isLoggedIn) ...[
                    _MenuItem(pageType: PageType.emotion, isSelected: pageType == PageType.emotion),
                    _MenuItem(pageType: PageType.tracker, isSelected: pageType == PageType.tracker),
                  ]
                ]
                else ...[
                  _MenuItem(pageType: PageType.adminInfo, isSelected: pageType == PageType.adminInfo),
                  _MenuItem(pageType: PageType.adminDiagnostics, isSelected: pageType == PageType.adminDiagnostics),
                  _MenuItem(pageType: PageType.adminAccount, isSelected: pageType == PageType.adminAccount),
                  _MenuItem(pageType: PageType.adminEmotions, isSelected: pageType == PageType.adminEmotions),
                  _MenuItem(pageType: PageType.adminActivity, isSelected: pageType == PageType.adminActivity),
                  // Admin info
                ],

                Divider(), // Séparateur avant l'option contextuelle
                
                // Affiche "Déconnexion" OU "Connexion" conditionnellement
                if (isLoggedIn) ...[
                  _MenuItem(pageType: PageType.user, isSelected: pageType == PageType.user, title: username,),
                  ListTile(
                    leading: Icon(Icons.logout, size: iconSize),
                    title: Text("Déconnexion"),
                    titleTextStyle: titleStyle,
                    textColor: Colors.black,
                    onTap: () => _logout(context), // Action de déconnexion
                  ),
                ]
                else
                  _MenuItem(pageType: PageType.login, isSelected: pageType == PageType.login),
              ],
            );
          }
        },
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  @override
  const _MenuItem({required this.pageType, required this.isSelected, this.title});

  final PageType pageType;
  final bool isSelected;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: getIconOfMenu(pageType),
      title: (title == null ? getTextOfMenu(pageType) : Text(title!)),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).secondaryHeaderColor,
      selectedColor: const Color.fromARGB(255, 0, 0, 0),
      textColor: Colors.black,
      onTap: () => onTapMenu(pageType, context),
    );
  }

  void onTapMenu(PageType pageType, BuildContext context){
    switch(pageType){
      case PageType.funcat :
        context.goNamed("cats");
        break;
      case PageType.info :
        context.goNamed("info");
        break;
      case PageType.activity :
        context.goNamed("activity");
        break;
      case PageType.breath :
        context.goNamed("breath");
        break;
      case PageType.diagnostics :
        context.goNamed("diagnostics");
        break;
      case PageType.tracker :
        context.goNamed("tracker");
        break;
      case PageType.emotion :
        context.goNamed("emotion");
        break;
      case PageType.user :
        context.goNamed("user");
        break;
      case PageType.login :
        context.goNamed("login");
        break;
      case PageType.adminDiagnostics :
        context.goNamed("adminDiagnostics");
        break;
      case PageType.adminAccount :
        context.goNamed("adminAccount");
        break;
      case PageType.adminEmotions :
        context.goNamed("adminEmotions");
        break;
      case PageType.adminActivity :
        context.goNamed("adminActivity");
        break;
      case PageType.adminInfo :
        context.goNamed("adminInfo");
        break;
    }
  }

  Icon getIconOfMenu(PageType pageType){
    const double iconSize = 30;
    switch(pageType){
      case PageType.funcat:
        return Icon(Icons.pets, size: iconSize,);
      case PageType.info:
        return Icon(Icons.info, size: iconSize,);
      case PageType.activity:
        return Icon(Icons.weekend, size: iconSize,);
      case PageType.breath:
        return Icon(Icons.self_improvement, size: iconSize,);
      case PageType.diagnostics:
        return Icon(Icons.quiz, size: iconSize,);
      case PageType.tracker:
        return Icon(Icons.query_stats, size: iconSize,);
      case PageType.emotion:
        return Icon(Icons.emoji_emotions, size: iconSize,);
      case PageType.user:
        return Icon(Icons.person, size: iconSize,);
      case PageType.login:
        return Icon(Icons.login, size: iconSize,);
      case PageType.adminDiagnostics:
        return Icon(Icons.quiz, size: iconSize,);
      case PageType.adminAccount:
        return Icon(Icons.admin_panel_settings, size: iconSize,);
      case PageType.adminEmotions:
        return Icon(Icons.emoji_emotions, size: iconSize,);
      case PageType.adminActivity:
        return Icon(Icons.weekend, size: iconSize,);
      case PageType.adminInfo:
        return Icon(Icons.info, size: iconSize,);
    }
  }

  Text getTextOfMenu(PageType pageType){
    switch(pageType){
      case PageType.funcat:
        return Text("Fun Cat");
      case PageType.info:
        return Text("Informations");
      case PageType.activity:
        return Text("Activité de détente");
      case PageType.breath:
        return Text("Exercices de respiration");
      case PageType.diagnostics:
        return Text("Diagnostics");
      case PageType.tracker:
        return Text("Tracker d'émotions");
      case PageType.emotion:
        return Text("Enregistrement d'émotion");
      case PageType.user:
        return Text("Utilisateur");
      case PageType.login:
        return Text("Connexion");
      case PageType.adminDiagnostics:
        return Text("Admin diagnostics");
      case PageType.adminAccount:
        return Text("Admin comptes");
      case PageType.adminEmotions:
        return Text("Admin emotions");
      case PageType.adminActivity:
        return Text("Admin activités");
      case PageType.adminInfo:
        return Text("Admin infos");
    }
  }
}