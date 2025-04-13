import 'package:cesi_zen/models/emotion_item.dart';
import 'package:flutter/material.dart';
import 'package:cesi_zen/services/emotion_service.dart'; // Importe le service
import 'package:cesi_zen/services/session_manager.dart'; // Pour obtenir l'userId
// Importe les modèles si nécessaire
// import 'package:cesi_zen/models/base_emotion.dart';
// import 'package:cesi_zen/models/specific_emotion.dart';
import 'package:cesi_zen/widgets/appbar_screen.dart'; // Tes widgets
import 'package:cesi_zen/widgets/drawer_menu_widget.dart';
import 'package:cesi_zen/utils/helper.dart'; // Pour PageType

class EmotionLoggingPage extends StatefulWidget {
  const EmotionLoggingPage({super.key});

  @override
  State<EmotionLoggingPage> createState() => _EmotionLoggingPageState();
}

class _EmotionLoggingPageState extends State<EmotionLoggingPage> {
  final EmotionService _emotionService = EmotionService();
  final SessionManager _sessionManager = SessionManager(); // Pour obtenir userId
  final _notesController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<BaseEmotion> _baseEmotions = [];
  List<SpecificEmotion> _specificEmotions = []; // Toutes les émotions spécifiques
  List<SpecificEmotion> _filteredSpecificEmotions = []; // Celles pour la base sélectionnée

  BaseEmotion? _selectedBaseEmotion;
  SpecificEmotion? _selectedSpecificEmotion;
  String? _currentUserId; // Pour stocker l'ID de l'utilisateur connecté

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

   @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }


  Future<void> _loadInitialData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _currentUserId = await _sessionManager.getLoggedInUsername(); // Ou mieux, un userId dédié si SessionManager le stocke
      if (_currentUserId == null) {
         throw Exception("Utilisateur non connecté."); // Gère le cas où l'utilisateur n'est pas connecté
      }

      final results = await Future.wait([
        _emotionService.getBaseEmotions(),
        _emotionService.getSpecificEmotions(), // Charge toutes les émotions spécifiques une fois
      ]);
      _baseEmotions = results[0] as List<BaseEmotion>;
      _specificEmotions = results[1] as List<SpecificEmotion>;

      // Pré-sélectionne la première émotion de base si la liste n'est pas vide
      if (_baseEmotions.isNotEmpty) {
         _selectBaseEmotion(_baseEmotions.first);
      }

    } catch (e) {
      print("Erreur chargement données logging: $e");
      _error = "Impossible de charger les émotions.";
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // Met à jour la liste des émotions spécifiques quand une base est sélectionnée
  void _selectBaseEmotion(BaseEmotion baseEmotion) {
    setState(() {
      _selectedBaseEmotion = baseEmotion;
      // Filtre les émotions spécifiques
      _filteredSpecificEmotions = _specificEmotions
          .where((se) => se.baseEmotionId == baseEmotion.id)
          .toList();
      // Réinitialise l'émotion spécifique sélectionnée si elle n'appartient pas à la nouvelle base
      if (_selectedSpecificEmotion != null && _selectedSpecificEmotion!.baseEmotionId != baseEmotion.id) {
          _selectedSpecificEmotion = null;
      }
       // Sélectionne la première émotion spécifique par défaut si la liste filtrée n'est pas vide
       if (_selectedSpecificEmotion == null && _filteredSpecificEmotions.isNotEmpty) {
           _selectedSpecificEmotion = _filteredSpecificEmotions.first;
       }
    });
  }

  // Enregistre l'émotion sélectionnée
  Future<void> _saveEmotionLog() async {
     if (_currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: Utilisateur non identifié.'), backgroundColor: Colors.red));
        return;
     }
     if (_selectedSpecificEmotion == null || _selectedBaseEmotion == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veuillez sélectionner une émotion.'), backgroundColor: Colors.orange));
        return;
     }

      setState(() { _isLoading = true; }); // Affiche un indicateur pendant la sauvegarde

      final success = await _emotionService.addLogEntry(
          userId: _currentUserId!,
          specificEmotionId: _selectedSpecificEmotion!.id,
          baseEmotionId: _selectedBaseEmotion!.id,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          // timestamp: DateTime.now() // Pris par défaut dans le service si non fourni
      );

       if (!mounted) return; // Vérifie après l'await

       setState(() { _isLoading = false; });

       if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Émotion enregistrée !'), backgroundColor: Colors.green));
          // Optionnel : Naviguer vers le journal ou vider les champs
          _notesController.clear();
          // Peut-être réinitialiser la sélection ?
          // Navigator.pop(context); // Si c'est une page modale
          // context.goNamed('emotion_journal'); // Si tu veux aller au journal après ajout
       } else {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'enregistrement.'), backgroundColor: Colors.red));
       }

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Adapte PageType pour le drawer
      drawer: DrawerMenuWidget(pageType: PageType.emotion), // Ou un PageType.emotionTracker dédié
      appBar: PreferredSize(
        preferredSize: Size(0, 60),
        child: AppBarScreen(pageName: "Enregistrer mon émotion"),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _baseEmotions.isEmpty) { // Affiche chargement seulement au début
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_error!, style: TextStyle(color: Colors.red))));
    }

    return SingleChildScrollView( // Permet le défilement si le contenu est long
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Comment vous sentez-vous maintenant ?", style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 20),

            // --- Sélection Émotion de Base ---
            Text("1. Choisissez une catégorie :", style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 10),
            Wrap( // Dispose les boutons en ligne, passe à la ligne si nécessaire
              spacing: 8.0, // Espace horizontal entre les boutons
              runSpacing: 8.0, // Espace vertical entre les lignes
              children: _baseEmotions.map((base) => ChoiceChip(
                    label: Text(base.name),
                    selected: _selectedBaseEmotion?.id == base.id,
                    onSelected: (selected) {
                      if (selected) {
                        _selectBaseEmotion(base);
                      }
                    },
                    // Tu peux ajouter une couleur ou une icône ici si tu les as définies dans le modèle
                    // avatar: Icon(base.icon),
                    // selectedColor: base.color.withOpacity(0.2),
              )).toList(),
            ),

            SizedBox(height: 30),

            // --- Sélection Émotion Spécifique ---
             if (_selectedBaseEmotion != null && _filteredSpecificEmotions.isNotEmpty) ...[
                Text("2. Précisez votre émotion :", style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 10),
                 Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _filteredSpecificEmotions.map((specific) => ChoiceChip(
                        label: Text(specific.name),
                        selected: _selectedSpecificEmotion?.id == specific.id,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() { _selectedSpecificEmotion = specific; });
                          }
                        },
                    )).toList(),
                 ),
                 SizedBox(height: 30),
             ] else if (_selectedBaseEmotion != null) ... [
                // Cas où une base est sélectionnée mais n'a pas d'émotion spécifique (ne devrait pas arriver avec nos données)
                Text("Aucune émotion spécifique pour cette catégorie.", style: TextStyle(fontStyle: FontStyle.italic)),
                 SizedBox(height: 30),
             ],

             // --- Notes Optionnelles ---
             Text("3. Ajoutez une note (optionnel) :", style: Theme.of(context).textTheme.titleMedium),
             SizedBox(height: 10),
             TextField(
                controller: _notesController,
                decoration: InputDecoration(
                   hintText: 'Qu\'est-ce qui a déclenché cette émotion ? Que se passe-t-il ?',
                   border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
             ),

             SizedBox(height: 30),

             // --- Bouton Sauvegarder ---
              Center(
                child: ElevatedButton.icon(
                    icon: _isLoading ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.save),
                    label: Text(_isLoading ? 'Sauvegarde...' : 'Enregistrer cette émotion'),
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                    // Désactive le bouton si aucune émotion spécifique n'est choisie ou si chargement en cours
                    onPressed: (_selectedSpecificEmotion == null || _isLoading) ? null : _saveEmotionLog,
                ),
              ),

          ],
        ),
    );
  }
}