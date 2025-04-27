
import 'package:cesi_zen/models/info_item.dart';
import 'package:cesi_zen/services/info_service.dart';
import 'package:cesi_zen/utils/helper.dart';
import 'package:cesi_zen/widgets/appbar_screen.dart';
import 'package:cesi_zen/widgets/drawer_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InfoPage extends StatefulWidget {
  @override
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage>{

  final InfoService _infoService = InfoService();
  bool _isLoading = true;
  String? _error;
  List<InfoItem> _infoItems = [];

  // Map pour convertir les noms d'icônes en IconData (à enrichir !)
  final Map<String, IconData> _iconMap = {
    'info': Icons.info_outline,
    'account_circle': Icons.account_circle_outlined,
    'quiz': Icons.quiz_outlined,
    'sentiment_satisfied': Icons.sentiment_satisfied_outlined,
    'spa': Icons.spa_outlined,
    'self_improvement': Icons.self_improvement_outlined,
    'admin_panel_settings': Icons.admin_panel_settings_outlined,
    'list_alt': Icons.list_alt_outlined,
    // Ajoute d'autres icônes utilisées ici
  };

  IconData _getIconFromName(String? iconName) {
    if (iconName == null) return Icons.help_outline; // Icône par défaut
    return _iconMap[iconName.toLowerCase()] ?? Icons.help_outline; // Icône par défaut si non trouvée
  }

  @override
  void initState() {
    super.initState();
    _loadInfoItems();
  }

  Future<void> _loadInfoItems() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _infoItems = await _infoService.getInfoItems();
    } catch (e) {
       print("Erreur chargement info items: $e");
      _error = "Impossible de charger les informations.";
    } finally {
       if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _navigateTo(String routePath) {
    // Utilise go ou goNamed selon ce que routePath contient (chemin ou nom)
    // Si ce sont des noms, utilise goNamed
    // Si ce sont des chemins (commençant par '/'), utilise go
    if (routePath.startsWith('/')) {
       context.go(routePath);
    } else {
       context.goNamed(routePath); // Suppose que ce sont des noms de route
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerMenuWidget(pageType: PageType.info), // PageType pour le drawer
      appBar: PreferredSize(
        preferredSize: Size(0, 60),
        child: AppBarScreen(pageName: "Informations & Modules"),
      ),
      body: _buildInfoBody(),
    );
  }

  Widget _buildInfoBody() {
    if (_isLoading) return Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Padding(padding: EdgeInsets.all(16), child: Text(_error!, style: TextStyle(color: Colors.red))));
    if (_infoItems.isEmpty) return Center(child: Text("Aucune information disponible."));

    return ListView.separated(
      padding: EdgeInsets.all(8.0),
      itemCount: _infoItems.length,
      itemBuilder: (context, index) {
        final item = _infoItems[index];
        return ListTile(
          leading: Icon(_getIconFromName(item.iconName), size: 30, color: Theme.of(context).colorScheme.primary),
          title: Text(item.title, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(item.description),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _navigateTo(item.routePath), // Navigation au clic
          contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Style optionnel
          // tileColor: Colors.white, // Style optionnel
        );
      },
      separatorBuilder: (context, index) => Divider(height: 1, indent: 16, endIndent: 16), // Séparateur entre items
    );
  }
}