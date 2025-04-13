import 'package:cesi_zen/models/diagnostic_item.dart';
import 'package:cesi_zen/utils/helper.dart';
import 'package:cesi_zen/widgets/appbar_screen.dart';
import 'package:cesi_zen/widgets/drawer_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cesi_zen/services/diagnostic_service.dart';

class DiagnosticsAdminPage extends StatefulWidget {
  const DiagnosticsAdminPage({super.key});

  @override
  State<DiagnosticsAdminPage> createState() => _DiagnosticsAdminPageState();
}

class _DiagnosticsAdminPageState extends State<DiagnosticsAdminPage> with SingleTickerProviderStateMixin {
  final DiagnosticService _diagnosticService = DiagnosticService();
  late TabController _tabController; // Controller pour les onglets

  bool _isLoading = true;
  String? _error;
  List<DiagnosticItem> _items = [];
  List<DiagnosisResult> _results = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 onglets: Items, Résultats
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
        _diagnosticService.getItems(),
        _diagnosticService.getResults(),
      ]);
      if (mounted) {
        setState(() {
          _items = results[0] as List<DiagnosticItem>;
          _results = results[1] as List<DiagnosisResult>;
           _isLoading = false;
        });
      }
    } catch (e) {
       print("Erreur chargement admin data: $e");
       if (mounted) {
         setState(() {
           _error = "Impossible de charger les données.";
           _isLoading = false;
         });
       }
    }
  }

  // --- Logique pour les ITEMS ---

  // Affiche le formulaire (dialog) pour ajouter/modifier un item
  Future<void> _showItemForm({DiagnosticItem? itemToEdit}) async {
    final _formKey = GlobalKey<FormState>();
    final _descriptionController = TextEditingController(text: itemToEdit?.description ?? '');
    final _weightController = TextEditingController(text: itemToEdit?.weight.toString() ?? '');
    bool isSaving = false; // État de chargement pour le dialogue

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !isSaving, // Empêche de fermer pendant sauvegarde
      builder: (BuildContext context) {
        // Utilise un StatefulWidget pour gérer l'état de chargement dans le dialogue
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(itemToEdit == null ? 'Ajouter un événement' : 'Modifier l\'événement'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView( // Pour éviter overflow si clavier apparaît
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(labelText: 'Description'),
                        validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                        enabled: !isSaving,
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _weightController,
                        decoration: InputDecoration(labelText: 'Poids (Points)'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Champ requis';
                          if (int.tryParse(value) == null) return 'Nombre invalide';
                          return null;
                        },
                        enabled: !isSaving,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(context).pop(false), // Annuler
                  child: Text('Annuler'),
                ),
                ElevatedButton.icon(
                  icon: isSaving ? SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.save),
                  label: Text(isSaving ? 'Sauvegarde...' : 'Sauvegarder'),
                  onPressed: isSaving ? null : () async {
                    if (_formKey.currentState!.validate()) {
                       setDialogState(() => isSaving = true); // Met à jour l'état du dialogue

                       bool success;
                       final description = _descriptionController.text;
                       final weight = int.parse(_weightController.text); // Validé comme int

                       if (itemToEdit == null) { // Ajout
                          success = await _diagnosticService.addItem(description, weight);
                       } else { // Modification
                          final updatedItem = DiagnosticItem(
                             id: itemToEdit.id, // Garde l'ID existant
                             description: description,
                             weight: weight
                          );
                          success = await _diagnosticService.updateItem(updatedItem);
                       }

                       if (!mounted) return; // Vérifie avant d'utiliser le contexte principal

                       if (success) {
                          Navigator.of(context).pop(true); // Ferme le dialogue avec succès
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Événement sauvegardé !'), backgroundColor: Colors.green));
                       } else {
                           setDialogState(() => isSaving = false); // Réactive les boutons si erreur
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de sauvegarde.'), backgroundColor: Colors.red));
                           // Ne ferme pas le dialogue en cas d'erreur
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

     // Si le dialogue a retourné true (sauvegarde réussie), recharge les données
     if (result == true) {
       _loadData(showLoading: false); // Recharge sans montrer l'indicateur global
     }
  }

  // Confirme et supprime un item
  Future<void> _confirmDeleteItem(DiagnosticItem item) async {
      final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('Confirmer la suppression'),
                content: Text('Voulez-vous vraiment supprimer l\'événement "${item.description}" ?'),
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
        final success = await _diagnosticService.deleteItem(item.id);
         if (!mounted) return;
         if (success) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Événement supprimé.'), backgroundColor: Colors.green));
            _loadData(showLoading: false); // Recharge la liste
         } else {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de suppression.'), backgroundColor: Colors.red));
         }
      }
  }
  // Dans la classe _DiagnosticsAdminPageState

  // --- Logique pour les RÉSULTATS (Diagnostiques) ---

  // Affiche le formulaire (dialog) pour ajouter/modifier un résultat
  Future<void> _showResultForm({DiagnosisResult? resultToEdit}) async {
    final _formKey = GlobalKey<FormState>();
    // Initialise les controllers avec les valeurs existantes si en mode édition
    final _minScoreController = TextEditingController(text: resultToEdit?.minScore.toString() ?? '');
    final _maxScoreController = TextEditingController(text: resultToEdit?.maxScore.toString() ?? '');
    final _titleController = TextEditingController(text: resultToEdit?.diagnosisTitle ?? '');
    final _riskController = TextEditingController(text: resultToEdit?.riskPercentage?.toString() ?? ''); // Gère le null
    final _textController = TextEditingController(text: resultToEdit?.diagnosisText ?? '');
    bool isSaving = false;

    // Nettoyage des controllers (important si le dialogue est fermé autrement qu'en sauvegardant)
    void disposeControllers() {
        _minScoreController.dispose();
        _maxScoreController.dispose();
        _titleController.dispose();
        _riskController.dispose();
        _textController.dispose();
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(resultToEdit == null ? 'Ajouter un diagnostic' : 'Modifier le diagnostic'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(labelText: 'Titre du diagnostic'),
                        validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                        enabled: !isSaving,
                      ),
                      SizedBox(height: 10),
                      Row( // Min et Max Score sur la même ligne
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _minScoreController,
                              decoration: InputDecoration(labelText: 'Score Min'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Requis';
                                if (int.tryParse(value) == null) return 'Nombre invalide';
                                return null;
                              },
                              enabled: !isSaving,
                            ),
                          ),
                          SizedBox(width: 10),
                           Expanded(
                            child: TextFormField(
                              controller: _maxScoreController,
                              decoration: InputDecoration(labelText: 'Score Max'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Requis';
                                final maxScore = int.tryParse(value);
                                if (maxScore == null) return 'Nombre invalide';
                                // Validation optionnelle de la fourchette
                                final minScore = int.tryParse(_minScoreController.text);
                                if (minScore != null && maxScore < minScore) {
                                   return 'Max < Min';
                                }
                                return null;
                              },
                              enabled: !isSaving,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                       TextFormField( // Champ pour le % de risque (optionnel)
                        controller: _riskController,
                        decoration: InputDecoration(labelText: 'Risque Évalué (%) (Optionnel)'),
                        keyboardType: TextInputType.numberWithOptions(decimal: false), // Permet juste les entiers
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                           // Optionnel, donc valide si vide
                           if (value == null || value.isEmpty) return null;
                           // Si non vide, doit être un nombre valide
                           if (int.tryParse(value) == null) return 'Nombre invalide';
                           return null;
                         },
                        enabled: !isSaving,
                      ),
                       SizedBox(height: 10),
                       TextFormField(
                        controller: _textController,
                        decoration: InputDecoration(
                          labelText: 'Texte du diagnostic',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3, // Permet plusieurs lignes
                        validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                        enabled: !isSaving,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isSaving ? null : () {
                      disposeControllers(); // Nettoie les controllers avant de pop
                      Navigator.of(context).pop(false);
                  },
                  child: Text('Annuler'),
                ),
                ElevatedButton.icon(
                  icon: isSaving ? SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.save),
                  label: Text(isSaving ? 'Sauvegarde...' : 'Sauvegarder'),
                  onPressed: isSaving ? null : () async {
                    if (_formKey.currentState!.validate()) {
                       setDialogState(() => isSaving = true);

                       bool success;
                       // Parse les valeurs (la validation assure qu'ils sont non null et valides)
                       final minScore = int.parse(_minScoreController.text);
                       final maxScore = int.parse(_maxScoreController.text);
                       final title = _titleController.text;
                       final text = _textController.text;
                       // Gère le risque optionnel (int.tryParse retourne null si vide ou invalide)
                       final risk = int.tryParse(_riskController.text);

                       if (resultToEdit == null) { // Ajout
                          success = await _diagnosticService.addResult(minScore, maxScore, title, text, risk);
                       } else { // Modification
                          final updatedResult = DiagnosisResult(
                             id: resultToEdit.id, // Garde l'ID existant
                             minScore: minScore,
                             maxScore: maxScore,
                             diagnosisTitle: title,
                             diagnosisText: text,
                             riskPercentage: risk
                          );
                          success = await _diagnosticService.updateResult(updatedResult);
                       }

                       if (!mounted) {
                         disposeControllers(); // Nettoie si le widget parent est démonté
                         return;
                       }

                       if (success) {
                          disposeControllers(); // Nettoie après succès
                          Navigator.of(context).pop(true); // Ferme avec succès
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Diagnostic sauvegardé !'), backgroundColor: Colors.green));
                       } else {
                           setDialogState(() => isSaving = false);
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de sauvegarde.'), backgroundColor: Colors.red));
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

     // Si le dialogue a retourné true (sauvegarde réussie), recharge les données
     if (result == true) {
       _loadData(showLoading: false);
     }
  }

   // Confirme et supprime un résultat (diagnostic)
  Future<void> _confirmDeleteResult(DiagnosisResult result) async {
      final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('Confirmer la suppression'),
                content: Text('Voulez-vous vraiment supprimer le diagnostic "${result.diagnosisTitle}" (Score ${result.minScore}-${result.maxScore}) ?'),
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
        setState(() => _isLoading = true ); // Affiche un indicateur pendant la suppression
        final success = await _diagnosticService.deleteResult(result.id);
         if (!mounted) return;

         if (success) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Diagnostic supprimé.'), backgroundColor: Colors.green));
            _loadData(showLoading: false); // Recharge la liste (et arrêtera l'indicateur)
         } else {
             setState(() => _isLoading = false ); // Arrête l'indicateur si erreur
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de suppression.'), backgroundColor: Colors.red));
         }
      }
  }


  // --- Widgets de l'UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerMenuWidget(pageType: PageType.adminDiagnostics), // Adapte PageType
      appBar: PreferredSize(
        preferredSize: Size(0, 60),
        child: AppBarScreen(pageName: "Admin Diagnostic"),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
              : Column( // Le body est maintenant une Column
                  children: [
                    // 1. La TabBar vient en premier dans la Column
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(icon: Icon(Icons.list_alt), text: 'Événements'),
                        Tab(icon: Icon(Icons.comment), text: 'Diagnostics'),
                      ],
                      // Style optionnel pour la TabBar dans le body
                      labelColor: Theme.of(context).colorScheme.primary, // Couleur du texte sélectionné
                      unselectedLabelColor: Colors.grey, // Couleur du texte non sélectionné
                      indicatorColor: Theme.of(context).colorScheme.primary, // Couleur de l'indicateur
                    ),

                    // 2. La TabBarView vient ensuite, mais dans un Expanded
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildItemsTab(), // Onglet pour gérer les items
                          _buildResultsTab(), // Onglet pour gérer les résultats
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // Construit l'onglet de gestion des items
  Widget _buildItemsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('Ajouter un événement'),
            onPressed: () => _showItemForm(), // Ouvre le formulaire d'ajout
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return ListTile(
                title: Text(item.description),
                subtitle: Text('Poids: ${item.weight}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min, // Important pour Row dans ListTile trailing
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Modifier',
                      onPressed: () => _showItemForm(itemToEdit: item), // Ouvre le formulaire d'édition
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Supprimer',
                      onPressed: () => _confirmDeleteItem(item), // Lance la confirmation
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

  Widget _buildResultsTab() {
    return Column(
       children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('Ajouter un diagnostic'),
            onPressed: () => _showResultForm(), // Appelle la fonction d'ajout
          ),
        ),
         Expanded(
          child: _results.isEmpty // Gère le cas où la liste est vide
            ? Center(child: Text('Aucun diagnostic défini.'))
            : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return ListTile(
                    title: Text(result.diagnosisTitle),
                    subtitle: Text('Score: ${result.minScore} - ${result.maxScore} | Risque: ${result.riskPercentage ?? 'N/A'}%'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Modifier',
                          onPressed: () => _showResultForm(resultToEdit: result), // Appelle la fonction d'édition
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Supprimer',
                          onPressed: () => _confirmDeleteResult(result), // Appelle la fonction de suppression
                        ),
                      ],
                    ),
                    onTap: () => _showResultForm(resultToEdit: result), // Ouvre aussi l'édition
                  );
                },
              ),
        ),
      ],
    );
  }
}