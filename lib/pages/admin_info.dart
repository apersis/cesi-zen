import 'package:cesi_zen/models/info_item.dart';
import 'package:flutter/material.dart';
import 'package:cesi_zen/services/info_service.dart';
import 'package:cesi_zen/widgets/appbar_screen.dart'; // Vos composants
import 'package:cesi_zen/widgets/drawer_menu_widget.dart';
import 'package:cesi_zen/utils/helper.dart'; // Pour PageType admin


class InfoAdminPage extends StatefulWidget {
  const InfoAdminPage({super.key});

  @override
  State<InfoAdminPage> createState() => _InfoAdminPageState();
}

class _InfoAdminPageState extends State<InfoAdminPage> {
  final InfoService _infoService = InfoService();
  bool _isLoading = true;
  String? _error;
  List<InfoItem> _infoItems = [];

  @override
  void initState() {
    super.initState();
    _loadInfoItems();
  }

  Future<void> _loadInfoItems({bool showLoading = true}) async {
     if (showLoading && mounted) setState(() => _isLoading = true);
      try {
          _infoItems = await _infoService.getInfoItems();
      } catch (e) { _error = "Erreur chargement infos."; print("Admin Load Infos Error: $e"); }
      finally { if (mounted) setState(() => _isLoading = false); }
  }

  // Affiche le formulaire pour ajouter/modifier un item d'info
  Future<void> _showInfoItemForm({InfoItem? itemToEdit}) async {
      final _formKey = GlobalKey<FormState>();
      final _titleController = TextEditingController(text: itemToEdit?.title ?? '');
      final _descriptionController = TextEditingController(text: itemToEdit?.description ?? '');
      final _routePathController = TextEditingController(text: itemToEdit?.routePath ?? '');
      final _iconNameController = TextEditingController(text: itemToEdit?.iconName ?? '');
      bool isSaving = false;

      /*void disposeControllers() { /* ... dispose de tous les controllers ... */
         _titleController.dispose(); _descriptionController.dispose(); _routePathController.dispose(); _iconNameController.dispose();
      }*/

      final result = await showDialog<bool>(
         context: context,
         barrierDismissible: !isSaving,
         builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
            return AlertDialog(
               title: Text(itemToEdit == null ? 'Ajouter Item Info' : 'Modifier Item Info'),
               content: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                           TextFormField(controller: _titleController, decoration: InputDecoration(labelText: 'Titre *'), validator: (v)=>(v==null||v.isEmpty)?'Requis':null, enabled: !isSaving),
                           SizedBox(height: 10),
                           TextFormField(controller: _descriptionController, decoration: InputDecoration(labelText: 'Description *', border: OutlineInputBorder()), maxLines: 3, validator: (v)=>(v==null||v.isEmpty)?'Requis':null, enabled: !isSaving),
                           SizedBox(height: 10),
                           TextFormField(controller: _routePathController, decoration: InputDecoration(labelText: 'Chemin/Nom Route *', hintText: 'ex: /home ou user_profile'), validator: (v)=>(v==null||v.isEmpty)?'Requis':null, enabled: !isSaving),
                            SizedBox(height: 10),
                           TextFormField(controller: _iconNameController, decoration: InputDecoration(labelText: 'Nom Icône Material (Optionnel)', hintText: 'ex: home, info, spa'), enabled: !isSaving),
                       ]
                     ),
                  )
               ),
               actions: [
                  TextButton(onPressed: isSaving ? null : () { Navigator.of(context).pop(false); }, child: Text('Annuler')),
                  ElevatedButton.icon(
                     icon: isSaving ? SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.save),
                     label: Text(isSaving ? 'Sauvegarde...' : 'Sauvegarder'),
                     onPressed: isSaving ? null : () async {
                         if (_formKey.currentState!.validate()) {
                             setDialogState(()=> isSaving = true);
                             bool success; String? errorMessage;
                              final itemData = InfoItem(
                                  id: itemToEdit?.id ?? '', // Ignoré si ajout
                                  title: _titleController.text.trim(),
                                  description: _descriptionController.text.trim(),
                                  routePath: _routePathController.text.trim(),
                                  iconName: _iconNameController.text.trim().isEmpty ? null : _iconNameController.text.trim(),
                              );
                             try {
                               if (itemToEdit == null) {
                                   success = await _infoService.addInfoItem(itemData);
                                   // TODO: Ajouter vérif unicité titre/route si besoin avant appel service
                               } else {
                                   success = await _infoService.updateInfoItem(itemData);
                                    // TODO: Ajouter vérif unicité titre/route si besoin avant appel service
                               }
                             } catch(e) { success = false; }

                             if (!mounted) { return; }
                             if (success) {
                                 Navigator.of(context).pop(true);
                                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sauvegardé !'), backgroundColor: Colors.green));
                             } else {
                                 setDialogState(()=> isSaving = false);
                                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage ?? 'Erreur sauvegarde.'), backgroundColor: Colors.red));
                             }
                         }
                     }
                  ),
               ]
            );
         })
      );
      if (result == true) _loadInfoItems(showLoading: false);
  }

  // Confirme et supprime un item d'info
  Future<void> _confirmDeleteInfoItem(InfoItem item) async {
    // Vérifie si monté avant même d'afficher le dialogue
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>( /* ... dialogue confirmation standard ... */
         context: context,
         builder: (context) => AlertDialog(
              title: Text('Confirmer la suppression'),
              content: Text('Voulez-vous vraiment supprimer l\'item "${item.title}" ?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Annuler')),
                TextButton(style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.of(context).pop(true), child: Text('Supprimer')),
              ],
            )
     );
     if (confirm == true) {
        setState(() => _isLoading = true);
        final success = await _infoService.deleteInfoItem(item.id);
        if (!mounted) return;
        if (success) {
          //scaffoldMessenger.showSnackBar(SnackBar(content: Text('Item supprimé.'),backgroundColor: Colors.green,));
          _loadInfoItems(showLoading: false);
        } else {
          setState(() => _isLoading = false);
          //scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erreur suppression.'),backgroundColor: Colors.red,));
        }
     }
  }

  @override
  Widget build(BuildContext context) {
     // Retourne directement le contenu pour que l'utilisateur ajoute son Scaffold
     if (_isLoading) return Center(child: CircularProgressIndicator());
     if (_error != null) return Center(child: Text(_error!, style: TextStyle(color: Colors.red)));

     return Scaffold(
      drawer: DrawerMenuWidget(pageType: PageType.adminInfo), // Adapte PageType
      appBar: PreferredSize(
        preferredSize: Size(0, 60),
        child: AppBarScreen(pageName: "Admin Emotions"),
      ),
      body: Column(
       children: [
         Padding(
           padding: const EdgeInsets.all(8.0),
           child: ElevatedButton.icon(
             icon: Icon(Icons.add), label: Text('Ajouter un Item Info'),
             onPressed: () => _showInfoItemForm(),
           ),
         ),
         Expanded(
           child: _infoItems.isEmpty
              ? Center(child: Text("Aucun item d'information défini."))
              : ListView.builder(
                  itemCount: _infoItems.length,
                  itemBuilder: (context, index) {
                     final item = _infoItems[index];
                     return ListTile(
                       leading: Icon(_getIconFromName(item.iconName)), // Utilise la même logique d'icône
                       title: Text(item.title),
                       subtitle: Text(item.description + '\nRoute: ${item.routePath}'),
                       isThreeLine: true, // Pour bien afficher la description et la route
                       trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => _showInfoItemForm(itemToEdit: item)),
                          IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDeleteInfoItem(item)),
                       ]),
                     );
                  },
                ),
         ),
       ],
     )
   );
  }

   // Copie de la fonction _getIconFromName depuis InformationPage (ou mets-la dans un helper commun)
   //final Map<String, IconData> _iconMap = { /* ... map des icônes ... */ };
   IconData _getIconFromName(String? iconName) { /* ... logique identique ... */
      final Map<String, IconData> iconMap = {
         'info': Icons.info_outline, 'account_circle': Icons.account_circle_outlined, 'quiz': Icons.quiz_outlined,
         'sentiment_satisfied': Icons.sentiment_satisfied_outlined, 'spa': Icons.spa_outlined,
         'self_improvement': Icons.self_improvement_outlined, 'admin_panel_settings': Icons.admin_panel_settings_outlined,
         'list_alt': Icons.list_alt_outlined, /* Ajoute d'autres si besoin */
      };
     if (iconName == null) return Icons.help_outline;
     return iconMap[iconName.toLowerCase()] ?? Icons.help_outline;
   }
}