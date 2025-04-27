import 'package:cesi_zen/models/activite_item.dart';
import 'package:cesi_zen/services/activite_service.dart';
import 'package:flutter/material.dart';
import 'package:cesi_zen/services/favorite_service.dart';
import 'package:cesi_zen/services/session_manager.dart';
// import 'package:cesi_zen/models/relaxation_activity.dart';
import 'package:cesi_zen/widgets/appbar_screen.dart';
import 'package:cesi_zen/widgets/drawer_menu_widget.dart';
import 'package:cesi_zen/utils/helper.dart'; // Pour PageType

class ActivityCatalogPage extends StatefulWidget {
  const ActivityCatalogPage({super.key});

  @override
  State<ActivityCatalogPage> createState() => _ActivityCatalogPageState();
}

class _ActivityCatalogPageState extends State<ActivityCatalogPage> {
  final RelaxationService _relaxationService = RelaxationService();
  final FavoriteService _favoriteService = FavoriteService();
  final SessionManager _sessionManager = SessionManager();

  bool _isLoading = true;
  String? _error;
  List<RelaxationActivity> _allActivities = [];
  List<RelaxationActivity> _filteredActivities = [];
  Set<String> _favoriteIds = {};
  List<String> _categories = [];
  String? _selectedCategoryFilter;

  bool _isLoggedIn = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // Vérifie si l'utilisateur est connecté et récupère son ID
      final userSession = await _sessionManager.getUserSession();
      _isLoggedIn = userSession.isLoggedIn;
      // Utilise le username comme ID pour l'instant, à adapter si vous avez un userId dédié
      _userId = userSession.username;

      final activities = await _relaxationService.getActivities();
      _allActivities = activities;
      _filteredActivities = activities; // Au début, tout est affiché

      // Extrait les catégories uniques pour le filtre
      _categories = activities.map((a) => a.category).toSet().toList();
      _categories.sort(); // Trie les catégories par ordre alphabétique

      // Charge les favoris SEULEMENT si l'utilisateur est connecté
      if (_isLoggedIn && _userId != null) {
         _favoriteIds = await _favoriteService.getFavoriteActivityIds(_userId!);
      } else {
         _favoriteIds = {}; // Vide si non connecté
      }

    } catch (e) {
      print("Erreur chargement catalogue: $e");
      _error = "Impossible de charger le catalogue d'activités.";
    } finally {
       if (mounted) setState(() { _isLoading = false; });
    }
  }

  // Filtre les activités par catégorie
  void _applyFilter(String? category) {
    setState(() {
      _selectedCategoryFilter = category;
      if (category == null) {
        // Pas de filtre, affiche tout
        _filteredActivities = _allActivities;
      } else {
        _filteredActivities = _allActivities.where((a) => a.category == category).toList();
      }
    });
  }

  // Ajoute ou retire une activité des favoris
  Future<void> _toggleFavorite(String activityId) async {
     if (!_isLoggedIn || _userId == null) return; // Ne fait rien si non connecté

     final bool isCurrentlyFavorite = _favoriteIds.contains(activityId);
     setState(() {
       // Met à jour l'UI immédiatement pour la réactivité
       if (isCurrentlyFavorite) {
         _favoriteIds.remove(activityId);
       } else {
         _favoriteIds.add(activityId);
       }
     });

     // Appelle le service en arrière-plan
     try {
        if (isCurrentlyFavorite) {
          await _favoriteService.removeFavorite(_userId!, activityId);
        } else {
          await _favoriteService.addFavorite(_userId!, activityId);
        }
         // Affiche un SnackBar de confirmation
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
               content: Text(isCurrentlyFavorite ? 'Retiré des favoris' : 'Ajouté aux favoris'),
               duration: Duration(seconds: 1),
             ));
         }
     } catch (e) {
        print("Erreur toggle favori: $e");
        // Si erreur, remet l'état précédent de l'UI
         if (mounted) {
             setState(() {
               if (isCurrentlyFavorite) {
                 _favoriteIds.add(activityId); // Remet si suppression échoue
               } else {
                 _favoriteIds.remove(activityId); // Retire si ajout échoue
               }
             });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                 content: Text('Erreur mise à jour favoris.'),
                 backgroundColor: Colors.red,
              ));
         }
     }
  }

// Recharge uniquement les IDs favoris pour l'utilisateur courant
  Future<void> _reloadFavoriteIds() async {
    if (!_isLoggedIn || _userId == null) {
      // Si l'utilisateur s'est déconnecté entre temps, vide les favoris locaux
      if (_favoriteIds.isNotEmpty && mounted) {
         setState(() => _favoriteIds = {});
      }
      return;
    }
    try {
      final updatedFavIds = await _favoriteService.getFavoriteActivityIds(_userId!);
      if (mounted) {
        setState(() {
          _favoriteIds = updatedFavIds;
        });
      }
    } catch (e) {
       print("Erreur recharge favoris catalogue: $e");
       // Optionnel: afficher un message d'erreur si besoin
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerMenuWidget(pageType: PageType.activity), // Adapte le PageType
      appBar: PreferredSize(
        preferredSize: Size(0, 60),
        child: AppBarScreen(pageName: "Activités de Détente"),
      ),
      body: _buildCatalogBody(),
    );
  }

  Widget _buildCatalogBody() {
    if (_isLoading) return Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: TextStyle(color: Colors.red))));

    return Column(
      children: [
        // --- Zone de Filtres ---
        _buildFilterChips(),

        // --- Liste des Activités ---
        Expanded(
          child: _filteredActivities.isEmpty
              ? Center(child: Text('Aucune activité trouvée pour cette catégorie.'))
              : GridView.builder( // Utilise GridView pour un affichage en grille
                  padding: EdgeInsets.all(8.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 colonnes
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 0.8, // Ratio pour la hauteur des cartes
                  ),
                  itemCount: _filteredActivities.length,
                  itemBuilder: (context, index) {
                    final activity = _filteredActivities[index];
                    final isFav = _favoriteIds.contains(activity.id);

                    return InkWell( // Rend la carte cliquable
                      onTap: () async {
                         if (!mounted) return; // Vérifie avant de naviguer
                        // Navigue vers la page détail ET ATTEND son retour
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ActivityDetailPage(activity: activity)),
                        );
                        // --- CODE EXÉCUTÉ APRÈS LE RETOUR DE ActivityDetailPage ---
                        if (!mounted) return; // Re-vérifie si le widget est toujours monté

                        print("Retour sur le catalogue depuis le détail, rechargement favoris...");
                        // Recharge SEULEMENT les favoris, pas toute la liste d'activités
                        await _reloadFavoriteIds();
                      },
                      child: Card(
                         clipBehavior: Clip.antiAlias, // Pour arrondir l'image
                         elevation: 3.0,
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             // Image (si disponible)
                             if (activity.imageUrl != null)
                               Expanded(
                                  child: Image.network(
                                     activity.imageUrl!,
                                     fit: BoxFit.cover, // Couvre l'espace
                                     width: double.infinity, // Prend toute la largeur
                                     // Affiche un indicateur pendant le chargement
                                     loadingBuilder: (context, child, loadingProgress) {
                                       if (loadingProgress == null) return child;
                                       return Center(child: CircularProgressIndicator(
                                           value: loadingProgress.expectedTotalBytes != null
                                               ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                               : null,
                                           strokeWidth: 2,
                                       ));
                                     },
                                     // Affiche une icône si l'image ne charge pas
                                     errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                  )
                               )
                             else // Placeholder si pas d'image
                               Expanded(child: Container(color: Colors.grey[200], child: Center(child: Icon(Icons.spa, color: Colors.grey[400])))),

                             // Titre et catégorie
                             Padding(
                                padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
                                child: Text(activity.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                             ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(activity.category, style: Theme.of(context).textTheme.bodySmall),
                              ),

                             // Durée et Bouton Favori (sur la même ligne en bas)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (activity.durationEstimate != null)
                                       Text(activity.durationEstimate!, style: Theme.of(context).textTheme.bodySmall),
                                    Spacer(), // Pousse le favori à droite
                                    // Bouton Favori (visible seulement si connecté)
                                    if (_isLoggedIn)
                                       IconButton(
                                         icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey),
                                         iconSize: 20,
                                         constraints: BoxConstraints(), // Réduit la zone de clic
                                         padding: EdgeInsets.zero,
                                         tooltip: isFav ? 'Retirer des favoris' : 'Ajouter aux favoris',
                                         onPressed: () => _toggleFavorite(activity.id),
                                       ),
                                  ],
                                ),
                              )
                           ],
                         ),
                      ),
                    );
                  }
              )
        ),
      ],
    );
  }

   // Widget pour les filtres de catégorie
  Widget _buildFilterChips() {
     // Crée les chips de filtre
     List<Widget> filterChips = _categories.map((category) => ChoiceChip(
        label: Text(category),
        selected: _selectedCategoryFilter == category,
        onSelected: (selected) {
           _applyFilter(selected ? category : null); // Applique ou retire le filtre
        },
     )).toList();

     // Ajoute une option "Tous" au début
      filterChips.insert(0, ChoiceChip(
         label: Text('Tous'),
         selected: _selectedCategoryFilter == null,
         onSelected: (selected) {
            _applyFilter(null); // Retire le filtre
         },
      ));

     // Affiche les chips dans une ligne scrollable
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
       child: SingleChildScrollView(
         scrollDirection: Axis.horizontal, // Permet de scroller si beaucoup de catégories
         child: Row(
           children: filterChips.map((chip) => Padding(
             padding: const EdgeInsets.symmetric(horizontal: 4.0),
             child: chip,
           )).toList(),
         ),
       ),
     );
  }
}


// --- PAGE DE DÉTAIL (Simple pour l'instant) ---
// Crée un nouveau fichier: lib/pages/relaxation/activity_detail_page.dart
class ActivityDetailPage extends StatefulWidget {
  final RelaxationActivity activity;

  const ActivityDetailPage({required this.activity, super.key});

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
   final FavoriteService _favoriteService = FavoriteService();
   final SessionManager _sessionManager = SessionManager();

   bool _isLoggedIn = false;
   String? _userId;
   bool _isFavorite = false;
   bool _isLoadingFavorite = true; // Chargement état favori

   @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

   Future<void> _loadInitialState() async {
      try {
        final session = await _sessionManager.getUserSession();
        _isLoggedIn = session.isLoggedIn;
        _userId = session.username; // Ou userId dédié

        if (_isLoggedIn && _userId != null) {
          _isFavorite = await _favoriteService.isFavorite(_userId!, widget.activity.id);
        }
      } catch(e) {
         print("Erreur chargement état favori détail: $e");
         // Gère l'erreur si nécessaire
      } finally {
         if (mounted) setState(() => _isLoadingFavorite = false);
      }
   }

   // Fonction pour ajouter/retirer des favoris (similaire à la page catalogue)
   Future<void> _toggleFavorite() async {
      if (!_isLoggedIn || _userId == null || _isLoadingFavorite) return;

      final bool wasFavorite = _isFavorite;
      // Met à jour l'UI immédiatement
      setState(() => _isFavorite = !_isFavorite);

       try {
        if (wasFavorite) {
          await _favoriteService.removeFavorite(_userId!, widget.activity.id);
        } else {
          await _favoriteService.addFavorite(_userId!, widget.activity.id);
        }
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
               content: Text(wasFavorite ? 'Retiré des favoris' : 'Ajouté aux favoris'),
               duration: Duration(seconds: 1),
             ));
         }
     } catch (e) {
        print("Erreur toggle favori détail: $e");
         if (mounted) {
             // Annule le changement UI si erreur
             setState(() => _isFavorite = wasFavorite);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                 content: Text('Erreur mise à jour favoris.'),
                 backgroundColor: Colors.red,
              ));
         }
     }
   }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.activity.title)), // AppBar simple ici
      body: SingleChildScrollView( // Permet de scroller si la description est longue
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affiche l'image si disponible
             if (widget.activity.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ClipRRect( // Pour arrondir les coins
                     borderRadius: BorderRadius.circular(8.0),
                     child: Image.network(
                       widget.activity.imageUrl!,
                       fit: BoxFit.cover,
                       width: double.infinity, height: 200, // Hauteur fixe pour l'image
                       loadingBuilder: (context, child, progress) => progress == null ? child : SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                       errorBuilder: (context, error, stackTrace) => SizedBox(height: 200, child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey))),
                     ),
                  ),
                ),

            // Titre (répété pour emphase)
            Text(widget.activity.title, style: Theme.of(context).textTheme.headlineMedium),
            SizedBox(height: 10),

             // Catégorie et Durée
             Row(
               children: [
                  Chip(label: Text(widget.activity.category), avatar: Icon(Icons.category, size: 16)),
                  SizedBox(width: 10),
                  if (widget.activity.durationEstimate != null)
                     Chip(label: Text(widget.activity.durationEstimate!), avatar: Icon(Icons.timer, size: 16)),
                  Spacer(), // Pousse le bouton favori à droite
                   // Bouton Favori (si connecté et état chargé)
                  if (_isLoggedIn && !_isLoadingFavorite)
                     IconButton(
                        icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : Colors.grey[700], size: 30),
                        tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                        onPressed: _toggleFavorite,
                     )
                  else if (_isLoadingFavorite && _isLoggedIn) // Indicateur pendant chargement favori
                     SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),

               ],
             ),
            SizedBox(height: 20),

            // Description
            Text('Description :', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            Text(widget.activity.description),

          ],
        ),
      ),
    );
  }
}


// --- PAGE ADMIN (Structure de base) ---
// Crée un nouveau fichier: lib/pages/admin/activity_admin_page.dart
class ActivityAdminPage extends StatefulWidget {
   const ActivityAdminPage({super.key});

   @override
   State<ActivityAdminPage> createState() => _ActivityAdminPageState();
}

class _ActivityAdminPageState extends State<ActivityAdminPage> {
   final RelaxationService _relaxationService = RelaxationService();
   bool _isLoading = true;
   String? _error;
   List<RelaxationActivity> _activities = [];

   @override
  void initState() {
    super.initState();
    _loadActivities();
  }

    Future<void> _loadActivities({bool showLoading = true}) async {
      if (showLoading && mounted) setState(() => _isLoading = true);
      try {
          _activities = await _relaxationService.getActivities();
          _activities.sort((a,b) => a.title.compareTo(b.title)); // Trie par titre
      } catch (e) {
          _error = "Erreur chargement activités.";
          print("Admin Load Activities Error: $e");
      } finally {
          if (mounted) setState(() => _isLoading = false);
      }
    }

   // Affiche le formulaire (dialog) pour ajouter/modifier une activité
  Future<void> _showActivityForm({RelaxationActivity? activityToEdit}) async {
    final _formKey = GlobalKey<FormState>();
    // Crée les controllers, initialise avec les valeurs existantes si édition
    final _titleController = TextEditingController(text: activityToEdit?.title ?? '');
    final _descriptionController = TextEditingController(text: activityToEdit?.description ?? '');
    final _categoryController = TextEditingController(text: activityToEdit?.category ?? '');
    final _imageUrlController = TextEditingController(text: activityToEdit?.imageUrl ?? '');
    final _durationController = TextEditingController(text: activityToEdit?.durationEstimate ?? '');
    bool isSaving = false;
  
    // Fonction pour nettoyer les controllers
    void disposeControllers() {
      _titleController.dispose();
      _descriptionController.dispose();
      _categoryController.dispose();
      _imageUrlController.dispose();
      _durationController.dispose();
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(activityToEdit == null ? 'Ajouter une activité' : 'Modifier l\'activité'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(labelText: 'Titre *'),
                        validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                        enabled: !isSaving,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      SizedBox(height: 10),
                       TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true, // Aligne mieux pour multi-lignes
                        ),
                        maxLines: 4, // Permet plusieurs lignes
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                        enabled: !isSaving,
                      ),
                       SizedBox(height: 10),
                       TextFormField(
                        controller: _categoryController,
                        decoration: InputDecoration(labelText: 'Catégorie *'),
                        validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                        enabled: !isSaving,
                        textCapitalization: TextCapitalization.words,
                      ),
                       SizedBox(height: 10),
                       TextFormField(
                        controller: _imageUrlController,
                        decoration: InputDecoration(labelText: 'URL de l\'image (Optionnel)'),
                        keyboardType: TextInputType.url,
                        enabled: !isSaving,
                      ),
                       SizedBox(height: 10),
                       TextFormField(
                        controller: _durationController,
                        decoration: InputDecoration(labelText: 'Durée estimée (Optionnel)', hintText: 'Ex: 5 min, 15-30 min'),
                        enabled: !isSaving,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isSaving ? null : () {
                     disposeControllers();
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

                       // Crée l'objet activité avec les données du formulaire
                       // L'ID est généré par le service si ajout (null ici), ou repris si édition.
                       final activityData = RelaxationActivity(
                           id: activityToEdit?.id ?? '', // L'ID sera ignoré par addActivity, mais utilisé par updateActivity
                           title: _titleController.text.trim(),
                           description: _descriptionController.text.trim(),
                           category: _categoryController.text.trim(),
                           imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
                           durationEstimate: _durationController.text.trim().isEmpty ? null : _durationController.text.trim(),
                       );

                       try {
                         if (activityToEdit == null) { // Ajout
                            success = await _relaxationService.addActivity(activityData);
                         } else { // Modification
                            success = await _relaxationService.updateActivity(activityData);
                         }
                       } catch (e) {
                           print("Erreur sauvegarde activité: $e");
                           success = false;
                       }


                       if (!mounted) { disposeControllers(); return; }

                       if (success) {
                          disposeControllers();
                          Navigator.of(context).pop(true); // Ferme avec succès
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Activité sauvegardée !'), backgroundColor: Colors.green));
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
    // Recharge les données si succès
    if (result == true) {
      _loadActivities(showLoading: false);
    } else {
      //disposeControllers(); // Assure le nettoyage si fermé autrement
    }
  }

   // Confirme et supprime une activité
  Future<void> _confirmDeleteActivity(RelaxationActivity activity) async {
      final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('Confirmer la suppression'),
                content: Text('Voulez-vous vraiment supprimer l\'activité "${activity.title}" ?'),
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
        setState(() => _isLoading = true ); // Affiche indicateur pendant suppression
        final success = await _relaxationService.deleteActivity(activity.id);
         if (!mounted) return;

         if (success) {
            //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Activité supprimée.'), backgroundColor: Colors.green));
            _loadActivities(showLoading: false); // Recharge la liste
         } else {
             setState(() => _isLoading = false ); // Arrête indicateur si erreur
             //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de suppression.'), backgroundColor: Colors.red));
         }
      }
  }


   @override
   Widget build(BuildContext context) {
      if (_isLoading) return Center(child: CircularProgressIndicator());
      if (_error != null) return Center(child: Text(_error!, style: TextStyle(color: Colors.red)));

      return Scaffold(
       drawer: DrawerMenuWidget(pageType: PageType.adminActivity), // Ou autre
       appBar: PreferredSize(
         preferredSize: Size(0, 60),
         child: AppBarScreen(pageName: "Admin Activités"),
       ),
       body: Column(
         children: [
            Padding(
               padding: const EdgeInsets.all(8.0),
               child: ElevatedButton.icon(
                 icon: Icon(Icons.add),
                 label: Text('Ajouter une activité'),
                 onPressed: () => _showActivityForm(),
               ),
             ),
             Expanded(
               child: _activities.isEmpty
                  ? Center(child: Text("Aucune activité définie."))
                  : ListView.builder(
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                         final activity = _activities[index];
                         return ListTile(
                           // Affiche une image thumbnail si disponible
                           leading: activity.imageUrl != null
                              ? CircleAvatar(backgroundImage: NetworkImage(activity.imageUrl!))
                              : CircleAvatar(child: Icon(Icons.spa)),
                           title: Text(activity.title),
                           subtitle: Text(activity.category),
                           trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(icon: Icon(Icons.edit, color: Colors.blue), onPressed: () => _showActivityForm(activityToEdit: activity)),
                              IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDeleteActivity(activity)),
                           ]),
                         );
                      },
                  ),
             ),
         ],
      )
    );
   }
}