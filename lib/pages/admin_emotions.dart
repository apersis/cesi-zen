import 'package:cesi_zen/models/emotion_item.dart';
import 'package:flutter/material.dart';
import 'package:cesi_zen/services/emotion_service.dart';
// Importe tes modèles si séparés
// import 'package:cesi_zen/models/base_emotion.dart';
// import 'package:cesi_zen/models/specific_emotion.dart';
import 'package:cesi_zen/widgets/appbar_screen.dart'; // Utilise tes composants
import 'package:cesi_zen/widgets/drawer_menu_widget.dart';
import 'package:cesi_zen/utils/helper.dart'; // Pour PageType (adapte ou supprime si pas besoin de drawer ici)


class EmotionAdminPage extends StatefulWidget {
  const EmotionAdminPage({super.key});

  @override
  State<EmotionAdminPage> createState() => _EmotionAdminPageState();
}

class _EmotionAdminPageState extends State<EmotionAdminPage> with SingleTickerProviderStateMixin {
  final EmotionService _emotionService = EmotionService();
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;
  List<BaseEmotion> _baseEmotions = [];
  List<SpecificEmotion> _specificEmotions = [];
  // Map pour accès rapide au nom de l'émotion de base par ID
  Map<String, String> _baseNames = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

   @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading && mounted) {
       setState(() { _isLoading = true; _error = null; });
    }
    try {
      final results = await Future.wait([
        _emotionService.getBaseEmotions(),
        _emotionService.getSpecificEmotions(),
      ]);
      if (mounted) {
        setState(() {
          _baseEmotions = results[0] as List<BaseEmotion>;
          _specificEmotions = results[1] as List<SpecificEmotion>;
          _baseNames = { for (var e in _baseEmotions) e.id : e.name }; // Crée le map
           _isLoading = false;
        });
      }
    } catch (e) {
       print("Erreur chargement admin emotions: $e");
       if (mounted) {
         setState(() {
           _error = "Impossible de charger les données.";
           _isLoading = false;
         });
       }
    }
  }

  // --- Logique CRUD Base Emotions ---

  Future<void> _showBaseEmotionForm({BaseEmotion? baseEmotionToEdit}) async {
      final _formKey = GlobalKey<FormState>();
      final _nameController = TextEditingController(text: baseEmotionToEdit?.name ?? '');
      bool isSaving = false;

      final result = await showDialog<bool>(
          context: context,
          barrierDismissible: !isSaving,
          builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
              return AlertDialog(
                  title: Text(baseEmotionToEdit == null ? 'Ajouter Émotion Base' : 'Modifier Émotion Base'),
                  content: Form(
                      key: _formKey,
                      child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(labelText: 'Nom de l\'émotion'),
                          validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                          enabled: !isSaving,
                      )
                  ),
                  actions: [
                     TextButton(onPressed: isSaving ? null : () => Navigator.of(context).pop(false), child: Text('Annuler')),
                     ElevatedButton.icon(
                         icon: isSaving ? SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.save),
                         label: Text(isSaving ? 'Sauvegarde...' : 'Sauvegarder'),
                         onPressed: isSaving ? null : () async {
                             if (_formKey.currentState!.validate()) {
                                 setDialogState(() => isSaving = true);
                                 bool success;
                                 final name = _nameController.text.trim();
                                 String? errorMessage;

                                 try {
                                     if (baseEmotionToEdit == null) {
                                        success = await _emotionService.addBaseEmotion(name);
                                        if (!success && mounted) {
                                            // Vérifie si l'erreur est due au nom dupliqué
                                            final currentEmotions = await _emotionService.getBaseEmotions();
                                            if (currentEmotions.any((e) => e.name.toLowerCase() == name.toLowerCase())) {
                                                errorMessage = "Ce nom d'émotion existe déjà.";
                                            }
                                        }
                                     } else {
                                         final updated = BaseEmotion(id: baseEmotionToEdit.id, name: name);
                                         success = await _emotionService.updateBaseEmotion(updated);
                                           if (!success && mounted) {
                                            final currentEmotions = await _emotionService.getBaseEmotions();
                                            if (currentEmotions.any((e) => e.id != updated.id && e.name.toLowerCase() == name.toLowerCase())) {
                                                errorMessage = "Ce nom d'émotion est déjà utilisé.";
                                            }
                                        }
                                     }
                                 } catch(e) { success = false; }


                                 if (!mounted) return;
                                 if (success) {
                                     Navigator.of(context).pop(true);
                                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sauvegardé !'), backgroundColor: Colors.green));
                                 } else {
                                      setDialogState(() => isSaving = false);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage ?? 'Erreur sauvegarde.'), backgroundColor: Colors.red));
                                 }
                             }
                         }
                     ),
                  ]
              );
          })
      );
       if (result == true) _loadData(showLoading: false);
  }

  Future<void> _confirmDeleteBaseEmotion(BaseEmotion baseEmotion) async {
     // Vérification si l'émotion est utilisée AVANT de montrer le dialogue
      final specificEmotions = await _emotionService.getSpecificEmotions(); // Recharge au cas où
      if (specificEmotions.any((se) => se.baseEmotionId == baseEmotion.id)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Impossible de supprimer "${baseEmotion.name}" : elle est utilisée par des émotions spécifiques.'),
              backgroundColor: Colors.orange,
          ));
          return;
      }

      final confirm = await showDialog<bool>( /* ... dialogue confirmation standard ... */
           context: context,
           builder: (context) => AlertDialog(
                title: Text('Confirmer la suppression'),
                content: Text('Voulez-vous vraiment supprimer l\'émotion de base "${baseEmotion.name}" ?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Annuler')),
                  TextButton(style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.of(context).pop(true), child: Text('Supprimer')),
                ],
              )
       );

       if (confirm == true) {
          setState(() => _isLoading = true);
          final success = await _emotionService.deleteBaseEmotion(baseEmotion.id);
          if (!mounted) return;
          if (success) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Émotion supprimée.'), backgroundColor: Colors.green));
              _loadData(showLoading: false); // Recharge les deux listes
          } else {
               setState(() => _isLoading = false);
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression.'), backgroundColor: Colors.red));
          }
       }
  }

   // --- Logique CRUD Specific Emotions ---
   Future<void> _showSpecificEmotionForm({SpecificEmotion? specificEmotionToEdit}) async {
       final _formKey = GlobalKey<FormState>();
       final _nameController = TextEditingController(text: specificEmotionToEdit?.name ?? '');
       String? _selectedBaseId = specificEmotionToEdit?.baseEmotionId ?? (_baseEmotions.isNotEmpty ? _baseEmotions.first.id : null); // Sélection initiale
       bool isSaving = false;

       if (_baseEmotions.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veuillez d\'abord créer une émotion de base.'), backgroundColor: Colors.orange));
          return;
       }

       final result = await showDialog<bool>(
          context: context,
          barrierDismissible: !isSaving,
          builder: (context) => StatefulBuilder(builder: (context, setDialogState){
             return AlertDialog(
                title: Text(specificEmotionToEdit == null ? 'Ajouter Émotion Spécifique' : 'Modifier Émotion Spécifique'),
                 content: Form(
                     key: _formKey,
                     child: SingleChildScrollView(
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                            DropdownButtonFormField<String>(
                                value: _selectedBaseId,
                                decoration: InputDecoration(labelText: 'Émotion de Base Parente'),
                                items: _baseEmotions.map((BaseEmotion base) {
                                  return DropdownMenuItem<String>(value: base.id, child: Text(base.name));
                                }).toList(),
                                onChanged: isSaving ? null : (String? newValue) {
                                    setDialogState(() => _selectedBaseId = newValue);
                                },
                                validator: (value) => value == null ? 'Champ requis' : null,
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(labelText: 'Nom de l\'émotion spécifique'),
                                validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                                enabled: !isSaving,
                            ),
                         ]
                       ),
                     ),
                 ),
                 actions: [
                     TextButton(onPressed: isSaving ? null : () => Navigator.of(context).pop(false), child: Text('Annuler')),
                     ElevatedButton.icon(
                       icon: isSaving ? SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.save),
                       label: Text(isSaving ? 'Sauvegarde...' : 'Sauvegarder'),
                       onPressed: (isSaving || _selectedBaseId == null) ? null : () async { // Désactive si pas de base sélectionnée
                          if (_formKey.currentState!.validate()) {
                             setDialogState(() => isSaving = true);
                             bool success;
                             final name = _nameController.text.trim();
                             final baseId = _selectedBaseId!;
                             String? errorMessage;

                             try {
                               if (specificEmotionToEdit == null) { // Ajout
                                  success = await _emotionService.addSpecificEmotion(name, baseId);
                                  if (!success && mounted) {
                                      final currentEmotions = await _emotionService.getSpecificEmotions();
                                      if (currentEmotions.any((e)=> e.baseEmotionId == baseId && e.name.toLowerCase() == name.toLowerCase())) {
                                          errorMessage = "Ce nom existe déjà pour cette émotion de base.";
                                      }
                                  }
                               } else { // Modification
                                  final updated = SpecificEmotion(id: specificEmotionToEdit.id, name: name, baseEmotionId: baseId);
                                  success = await _emotionService.updateSpecificEmotion(updated);
                                    if (!success && mounted) {
                                       final currentEmotions = await _emotionService.getSpecificEmotions();
                                       if (currentEmotions.any((e)=> e.id != updated.id && e.baseEmotionId == baseId && e.name.toLowerCase() == name.toLowerCase())) {
                                           errorMessage = "Ce nom existe déjà pour cette émotion de base.";
                                       }
                                   }
                               }
                             } catch(e) { success = false; }

                             if (!mounted) return;
                             if (success) {
                                Navigator.of(context).pop(true);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sauvegardé !'), backgroundColor: Colors.green));
                             } else {
                                 setDialogState(() => isSaving = false);
                                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage ?? 'Erreur sauvegarde.'), backgroundColor: Colors.red));
                             }
                          }
                       }
                     ),
                 ]
             );
          })
       );
       if (result == true) _loadData(showLoading: false);
   }

    Future<void> _confirmDeleteSpecificEmotion(SpecificEmotion specificEmotion) async {
       final confirm = await showDialog<bool>( /* ... dialogue confirmation standard ... */
           context: context,
           builder: (context) => AlertDialog(
                title: Text('Confirmer la suppression'),
                content: Text('Voulez-vous vraiment supprimer l\'émotion spécifique "${specificEmotion.name}" ?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Annuler')),
                  TextButton(style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.of(context).pop(true), child: Text('Supprimer')),
                ],
              )
       );
       if (confirm == true) {
          setState(() => _isLoading = true);
          final success = await _emotionService.deleteSpecificEmotion(specificEmotion.id);
          if (!mounted) return;
          if (success) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Émotion supprimée.'), backgroundColor: Colors.green));
              _loadData(showLoading: false);
          } else {
               setState(() => _isLoading = false);
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression.'), backgroundColor: Colors.red));
          }
       }
    }


  // --- Widgets Build ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerMenuWidget(pageType: PageType.adminEmotions), // Adapte PageType
      appBar: PreferredSize(
        preferredSize: Size(0, 60),
        child: AppBarScreen(pageName: "Admin Emotions"),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
              : Column(children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.psychology_alt), text: 'Émotions Base'), // Ou Icons.brightness_auto
                    Tab(icon: Icon(Icons.psychology), text: 'Émotions Spécifiques'), // Ou Icons.filter_vintage
                  ],
                ),
                Expanded(child: 
                  TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBaseEmotionsTab(),
                      _buildSpecificEmotionsTab(),
                    ],
                  ),
                )
              ],)
              
              
              
    );
  }

  Widget _buildBaseEmotionsTab() {
     return Column(
       children: [
         Padding(
           padding: const EdgeInsets.all(8.0),
           child: ElevatedButton.icon(
             icon: Icon(Icons.add), label: Text('Ajouter Émotion Base'),
             onPressed: () => _showBaseEmotionForm(),
           ),
         ),
         Expanded(
           child: ListView.builder(
             itemCount: _baseEmotions.length,
             itemBuilder: (context, index) {
               final item = _baseEmotions[index];
               return ListTile(
                 title: Text(item.name),
                 trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => _showBaseEmotionForm(baseEmotionToEdit: item)),
                    IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDeleteBaseEmotion(item)),
                 ]),
               );
             },
           ),
         ),
       ],
     );
  }

   Widget _buildSpecificEmotionsTab() {
     return Column(
       children: [
         Padding(
           padding: const EdgeInsets.all(8.0),
           child: ElevatedButton.icon(
             icon: Icon(Icons.add), label: Text('Ajouter Émotion Spécifique'),
             onPressed: () => _showSpecificEmotionForm(),
           ),
         ),
         Expanded(
           child: ListView.builder(
             itemCount: _specificEmotions.length,
             itemBuilder: (context, index) {
               final item = _specificEmotions[index];
               final baseName = _baseNames[item.baseEmotionId] ?? 'Base Inconnue'; // Utilise le Map
               return ListTile(
                 title: Text(item.name),
                 subtitle: Text('Base: $baseName'), // Affiche le nom de la base
                 trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => _showSpecificEmotionForm(specificEmotionToEdit: item)),
                    IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDeleteSpecificEmotion(item)),
                 ]),
               );
             },
           ),
         ),
       ],
     );
  }

}