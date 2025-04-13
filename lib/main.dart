import 'package:cesi_zen/pages/activity_page.dart';
import 'package:cesi_zen/pages/admin_account.dart';
import 'package:cesi_zen/pages/admin_diagnostics.dart';
import 'package:cesi_zen/pages/admin_emotions.dart';
import 'package:cesi_zen/pages/breath_page.dart';
import 'package:cesi_zen/pages/cat_page.dart';
import 'package:cesi_zen/pages/diagnostics_page.dart';
import 'package:cesi_zen/pages/emotion_page.dart';
import 'package:cesi_zen/pages/info_page.dart';
import 'package:cesi_zen/pages/login_page.dart';
import 'package:cesi_zen/pages/tracker_page.dart';
import 'package:cesi_zen/pages/user_page.dart';
import 'package:cesi_zen/services/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() async {
  // Important: S'assurer que les bindings sont initialisés avant d'appeler SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();

  final sessionManager = SessionManager();
  bool loggedIn = await sessionManager.isLoggedIn();

  runApp(MainApp(isLoggedIn: loggedIn));
}

final GoRouter _router = GoRouter(routes: <RouteBase>[
  GoRoute(
    path: '/', 
    name: "info", 
    builder: (BuildContext context, GoRouterState state){
      return const InfoPage();
    }
  ),
  GoRoute(
    path: '/cats', 
    name: "cats", 
    builder: (BuildContext context, GoRouterState state){
      return const FunCatPage();
    }
  ),
  GoRoute(
    path: '/activity', 
    name: "activity", 
    builder: (BuildContext context, GoRouterState state){
      return const ActivityCatalogPage();
    }
  ),
  GoRoute(
    path: '/admin/activity', 
    name: "adminActivity", 
    builder: (BuildContext context, GoRouterState state){
      return const ActivityAdminPage();
    }
  ),
  GoRoute(
    path: '/breath', 
    name: "breath", 
    builder: (BuildContext context, GoRouterState state){
      return const BreathExercisePage();
    }
  ),
  GoRoute(
    path: '/diagnostics', 
    name: "diagnostics", 
    builder: (BuildContext context, GoRouterState state){
      return const DiagnosticsPage();
    }
  ),
  GoRoute(
    path: '/tracker', 
    name: "tracker", 
    builder: (BuildContext context, GoRouterState state){
      return const EmotionJournalPage();
    }
  ),
  GoRoute(
    path: '/emotion', 
    name: "emotion", 
    builder: (BuildContext context, GoRouterState state){
      return const EmotionLoggingPage();
    }
  ),
  GoRoute(
    path: '/user', 
    name: "user", 
    builder: (BuildContext context, GoRouterState state){
      return const UserPage();
    }
  ),
  GoRoute(
    path: '/login', 
    name: "login", 
    builder: (BuildContext context, GoRouterState state){
      return const LoginPage();
    }
  ),
  GoRoute(
    path: '/admin/diagnostics', 
    name: "adminDiagnostics", 
    builder: (BuildContext context, GoRouterState state){
      return const DiagnosticsAdminPage();
    }
  ),
  GoRoute(
    path: '/admin/account', 
    name: "adminAccount", 
    builder: (BuildContext context, GoRouterState state){
      return const UserAdminPage();
    }
  ),
  GoRoute(
    path: '/admin/emotions', 
    name: "adminEmotions", 
    builder: (BuildContext context, GoRouterState state){
      return const EmotionAdminPage();
    }
  ),
]);



class MainApp extends StatelessWidget {
  final bool isLoggedIn;

  const MainApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: "Cesi Zen",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 0, 191, 99)),
        appBarTheme: AppBarTheme(iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary))
      )  
    );
  }
}
