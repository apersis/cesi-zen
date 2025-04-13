import 'package:cesi_zen/models/emotion_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pour formater les dates (ajoute la dépendance intl)
import 'package:cesi_zen/services/emotion_service.dart';
import 'package:cesi_zen/services/session_manager.dart';
// Importe les modèles
// import 'package:cesi_zen/models/emotion_log_entry.dart';
// import 'package:cesi_zen/models/base_emotion.dart';
// import 'package:cesi_zen/models/specific_emotion.dart';
import 'package:cesi_zen/widgets/appbar_screen.dart';
import 'package:cesi_zen/widgets/drawer_menu_widget.dart';
import 'package:cesi_zen/utils/helper.dart';

// Énum pour les filtres de date
enum DateFilter { week, month, quarter, year, all }

class EmotionJournalPage extends StatefulWidget {
  const EmotionJournalPage({super.key});

  @override
  State<EmotionJournalPage> createState() => _EmotionJournalPageState();
}

class _EmotionJournalPageState extends State<EmotionJournalPage> {
  final EmotionService _emotionService = EmotionService();
  final SessionManager _sessionManager = SessionManager();

  bool _isLoading = true;
  String? _error;
  List<EmotionLogEntry> _logEntries = [];
  List<BaseEmotion> _baseEmotions = []; // Pour afficher les noms
  List<SpecificEmotion> _specificEmotions = []; // Pour afficher les noms

  DateFilter _selectedFilter = DateFilter.week; // Filtre par défaut
  String? _currentUserId;

  // Map pour un accès rapide aux noms des émotions par ID
  Map<String, String> _baseEmotionNames = {};
  Map<String, String> _specificEmotionNames = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _currentUserId = await _sessionManager.getLoggedInUsername(); // Ou userId dédié
      if (_currentUserId == null) throw Exception("Utilisateur non connecté.");

      // Charge les définitions d'émotions une fois
      final emotionsResult = await Future.wait([
         _emotionService.getBaseEmotions(),
         _emotionService.getSpecificEmotions(),
      ]);
      _baseEmotions = emotionsResult[0] as List<BaseEmotion>;
      _specificEmotions = emotionsResult[1] as List<SpecificEmotion>;

      // Crée les Maps pour les noms
      _baseEmotionNames = {for (var e in _baseEmotions) e.id: e.name};
      _specificEmotionNames = {for (var e in _specificEmotions) e.id: e.name};

      // Charge les entrées du journal avec le filtre par défaut (semaine)
      await _loadJournalEntries();

    } catch (e) {
       print("Erreur chargement journal: $e");
       _error = "Impossible de charger le journal.";
    } finally {
       if (mounted) setState(() { _isLoading = false; });
    }
  }

  // Charge (ou recharge) les entrées du journal en fonction du filtre sélectionné
  Future<void> _loadJournalEntries() async {
    if (_currentUserId == null) return; // Ne charge pas si pas d'utilisateur
    if (!_isLoading && mounted) setState(() { _isLoading = true; }); // Affiche chargement si déjà affiché

    DateTime now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate = now; // Par défaut, jusqu'à maintenant

    switch (_selectedFilter) {
      case DateFilter.week:
        // Trouve le Lundi de cette semaine
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day); // Début de journée
        break;
      case DateFilter.month:
        startDate = DateTime(now.year, now.month, 1); // Premier jour du mois
        break;
      case DateFilter.quarter:
         // Trouve le début du trimestre actuel
        int currentQuarter = ((now.month - 1) / 3).floor(); // 0, 1, 2, 3
        startDate = DateTime(now.year, currentQuarter * 3 + 1, 1);
        break;
      case DateFilter.year:
        startDate = DateTime(now.year, 1, 1); // Premier jour de l'année
        break;
      case DateFilter.all:
        startDate = null; // Pas de date de début
        endDate = null; // Pas de date de fin
        break;
    }

     try {
        _logEntries = await _emotionService.getLogEntries(
          _currentUserId!,
          startDate: startDate,
          endDate: endDate, // endDate est toujours null pour 'all', ou now pour les autres
        );
     } catch (e) {
        print("Erreur chargement entrées journal: $e");
        _error = "Erreur lors du chargement des entrées.";
     } finally {
        if (mounted) setState(() { _isLoading = false; });
     }

  }

  // Supprime une entrée
  Future<void> _deleteEntry(String entryId) async {
     if (_currentUserId == null) return;

     final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Confirmer la suppression'),
              content: Text('Voulez-vous vraiment supprimer cette entrée du journal ?'),
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
        setState(() => _isLoading = true); // Affiche indicateur
        final success = await _emotionService.deleteLogEntry(entryId, _currentUserId!);
        if (!mounted) return;

         if (success) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Entrée supprimée.'), backgroundColor: Colors.green));
            await _loadJournalEntries(); // Recharge la liste après suppression
         } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de suppression.'), backgroundColor: Colors.red));
            setState(() => _isLoading = false); // Arrête l'indicateur si erreur
         }
     }
  }

  // Ouvre le formulaire/dialogue pour modifier une entrée
  Future<void> _editEntry(EmotionLogEntry entryToEdit) async {
    if (_currentUserId == null) return; // Sécurité

    // Trouve les objets émotion initiaux (pour pré-sélectionner)
    final initialBase = _baseEmotions.firstWhere((b) => b.id == entryToEdit.baseEmotionId, orElse: () => _baseEmotions.first);
    final initialSpecific = _specificEmotions.firstWhere((s) => s.id == entryToEdit.specificEmotionId, orElse: () => _specificEmotions.firstWhere((s) => s.baseEmotionId == initialBase.id)); // Prend la 1ere spécifique de la base si l'originale n'existe plus

    // Controllers et état pour le dialogue
    final _notesController = TextEditingController(text: entryToEdit.notes ?? '');
    BaseEmotion? _selectedBase = initialBase;
    SpecificEmotion? _selectedSpecific = initialSpecific;
    List<SpecificEmotion> _filteredSpecific = _specificEmotions.where((s) => s.baseEmotionId == _selectedBase?.id).toList();
    bool _isSaving = false;

    void disposeControllers() {
        _notesController.dispose();
    }

    final success = await showDialog<bool>(
        context: context,
        barrierDismissible: !_isSaving,
        builder: (dialogContext) {
            // Utilise StatefulBuilder pour l'état interne du dialogue
            return StatefulBuilder(
                builder: (context, setDialogState) {
                    return AlertDialog(
                        title: Text('Modifier l\'entrée'),
                        content: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text("Émotion de Base :", style: Theme.of(context).textTheme.labelLarge),
                                    Wrap(
                                        spacing: 8.0, runSpacing: 4.0,
                                        children: _baseEmotions.map((base) => ChoiceChip(
                                            label: Text(base.name),
                                            selected: _selectedBase?.id == base.id,
                                            onSelected: (selected) {
                                                if (selected && !_isSaving) {
                                                    setDialogState(() {
                                                        _selectedBase = base;
                                                        _filteredSpecific = _specificEmotions.where((s) => s.baseEmotionId == base.id).toList();
                                                        // Si l'émotion spécifique actuelle n'appartient plus à la nouvelle base,
                                                        // la désélectionner ou sélectionner la première de la nouvelle liste
                                                        if (_filteredSpecific.isNotEmpty && !_filteredSpecific.any((s)=> s.id == _selectedSpecific?.id)) {
                                                             _selectedSpecific = _filteredSpecific.first;
                                                        } else if (_filteredSpecific.isEmpty) {
                                                            _selectedSpecific = null; // Aucune émotion spécifique pour cette base
                                                        }
                                                    });
                                                }
                                            },
                                        )).toList(),
                                    ),
                                    SizedBox(height: 15),
                                    if (_selectedBase != null && _filteredSpecific.isNotEmpty) ...[
                                        Text("Émotion Spécifique :", style: Theme.of(context).textTheme.labelLarge),
                                         Wrap(
                                            spacing: 8.0, runSpacing: 4.0,
                                            children: _filteredSpecific.map((specific) => ChoiceChip(
                                                label: Text(specific.name),
                                                selected: _selectedSpecific?.id == specific.id,
                                                onSelected: (selected) {
                                                    if (selected && !_isSaving) {
                                                        setDialogState(() { _selectedSpecific = specific; });
                                                    }
                                                },
                                            )).toList(),
                                         ),
                                         SizedBox(height: 15),
                                    ],
                                    Text("Notes :", style: Theme.of(context).textTheme.labelLarge),
                                    TextField(
                                        controller: _notesController,
                                        decoration: InputDecoration(hintText: 'Notes optionnelles...', border: OutlineInputBorder()),
                                        maxLines: 3,
                                        textCapitalization: TextCapitalization.sentences,
                                        enabled: !_isSaving,
                                    ),
                                ],
                            ),
                        ),
                        actions: [
                           TextButton(
                              onPressed: _isSaving ? null : () {
                                 disposeControllers();
                                 Navigator.of(context).pop(false);
                              },
                              child: Text('Annuler')
                           ),
                           ElevatedButton.icon(
                              icon: _isSaving ? SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.save),
                              label: Text(_isSaving ? 'Sauvegarde...' : 'Sauvegarder'),
                              // Désactive si pas d'émotion spécifique sélectionnée ou si sauvegarde en cours
                              onPressed: (_selectedSpecific == null || _isSaving) ? null : () async {
                                  setDialogState(() => _isSaving = true);
                                  final updatedEntry = EmotionLogEntry(
                                      id: entryToEdit.id, // Garde l'ID original
                                      userId: _currentUserId!, // Garde l'userId original
                                      specificEmotionId: _selectedSpecific!.id, // Prend la nouvelle sélection
                                      baseEmotionId: _selectedBase!.id, // Prend la nouvelle sélection
                                      timestamp: entryToEdit.timestamp, // Garde le timestamp original
                                      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                                  );

                                  final updateSuccess = await _emotionService.updateLogEntry(updatedEntry);

                                  if (!mounted) { disposeControllers(); return; } // Vérifie si le widget parent est toujours là

                                  if (updateSuccess) {
                                      disposeControllers();
                                      Navigator.of(context).pop(true); // Ferme dialogue avec succès
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Entrée mise à jour !'), backgroundColor: Colors.green));
                                  } else {
                                      setDialogState(() => _isSaving = false); // Réactive bouton si erreur
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de mise à jour.'), backgroundColor: Colors.red));
                                  }
                              },
                           )
                        ],
                    );
                }
            );
        }
    );

    // Recharge les données du journal si la mise à jour a réussi
    if (success == true) {
        _loadJournalEntries();
    } else {
      // Assure le nettoyage si on a fermé autrement (ex: clic extérieur si barrierDismissible=true)
      disposeControllers();
    }
}

  // Helper pour formater la date
  String _formatDateTime(DateTime dt) {
     // Utilise intl pour un formatage plus localisé si besoin
     // return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(dt);
     return DateFormat('dd MMM yyyy HH:mm').format(dt); // Format plus court
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       drawer: DrawerMenuWidget(pageType: PageType.tracker), // Ou autre
       appBar: PreferredSize(
         preferredSize: Size(0, 60),
         child: AppBarScreen(pageName: "Journal des Émotions"),
       ),
       body: _buildJournalBody(),
    );
  }

   Widget _buildJournalBody() {
      if (_isLoading && _logEntries.isEmpty) { // Chargement initial
         return Center(child: CircularProgressIndicator());
      }
      if (_error != null) {
         return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_error!, style: TextStyle(color: Colors.red))));
      }

       return Column(
         children: [
           // --- Barre de Filtres ---
           Padding(
             padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
             child: SegmentedButton<DateFilter>( // Boutons segmentés pour le filtre
                segments: const <ButtonSegment<DateFilter>>[
                   ButtonSegment(value: DateFilter.week, label: Text('Semaine'), icon: Icon(Icons.calendar_view_week)),
                   ButtonSegment(value: DateFilter.month, label: Text('Mois'), icon: Icon(Icons.calendar_view_month)),
                   ButtonSegment(value: DateFilter.quarter, label: Text('Trimestre'), icon: Icon(Icons.calendar_today)), // Icône approximative
                   ButtonSegment(value: DateFilter.year, label: Text('Année'), icon: Icon(Icons.calendar_today)),
                   ButtonSegment(value: DateFilter.all, label: Text('Tout'), icon: Icon(Icons.all_inclusive)),
                ],
                selected: {_selectedFilter}, // Le Set attendu par SegmentedButton
                onSelectionChanged: (Set<DateFilter> newSelection) {
                   setState(() {
                      _selectedFilter = newSelection.first; // Prend le seul élément sélectionné
                      _loadJournalEntries(); // Recharge les données avec le nouveau filtre
                   });
                },
                // Style pour les rendre plus petits si nécessaire
                style: SegmentedButton.styleFrom(
                   // visualDensity: VisualDensity.compact,
                ),
             ),
           ),

           // --- Indicateur de chargement pendant le filtrage ---
            if (_isLoading)
               Padding(
                 padding: const EdgeInsets.symmetric(vertical: 8.0),
                 child: Center(child: LinearProgressIndicator()), // Indicateur linéaire
               ),

           // --- Liste des Entrées ---
            Expanded(
              child: _logEntries.isEmpty && !_isLoading
                  ? Center(child: Text('Aucune entrée trouvée pour cette période.'))
                  : ListView.builder(
                      itemCount: _logEntries.length,
                      itemBuilder: (context, index) {
                         final entry = _logEntries[index];
                         final baseName = _baseEmotionNames[entry.baseEmotionId] ?? 'Inconnue';
                         final specificName = _specificEmotionNames[entry.specificEmotionId] ?? 'Inconnue';

                         return Card( // Utilise des cartes pour chaque entrée
                            margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: ListTile(
                               leading: Icon(Icons.sentiment_satisfied_alt, color: Theme.of(context).colorScheme.primary), // Icône générique, à améliorer
                               title: Text('$baseName - $specificName'),
                               subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     Text(_formatDateTime(entry.timestamp)),
                                     if (entry.notes != null && entry.notes!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text('Note: ${entry.notes}', style: TextStyle(fontStyle: FontStyle.italic)),
                                        ),
                                  ],
                               ),
                               trailing: Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                    IconButton(
                                       icon: Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                                       tooltip: 'Modifier',
                                       onPressed: () => _editEntry(entry),
                                    ),
                                    IconButton(
                                       icon: Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                       tooltip: 'Supprimer',
                                       onPressed: () => _deleteEntry(entry.id),
                                    ),
                                 ],
                               ),
                               isThreeLine: entry.notes != null && entry.notes!.isNotEmpty, // Adapte la hauteur si notes
                            ),
                         );
                      },
                    ),
            ),
         ],
       );
   }

}