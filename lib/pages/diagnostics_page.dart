import 'package:cesi_zen/models/diagnostic_item.dart';
import 'package:cesi_zen/services/diagnostic_service.dart';
import 'package:flutter/material.dart';
import 'package:cesi_zen/widgets/appbar_screen.dart'; // Tes widgets perso
import 'package:cesi_zen/widgets/drawer_menu_widget.dart';
import 'package:cesi_zen/utils/helper.dart'; // Pour PageType

class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  final DiagnosticService _diagnosticService = DiagnosticService();

  bool _isLoading = true;
  String? _error;
  List<DiagnosticItem> _items = [];
  List<DiagnosisResult> _results = [];

  // Utilise un Set pour stocker les IDs des éléments cochés (efficace pour vérifier si un ID est présent)
  final Set<String> _checkedItemIds = {};

  int _currentScore = 0;
  DiagnosisResult? _currentDiagnosisResult;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Charge les items et les résultats en parallèle
      final results = await Future.wait([
        _diagnosticService.getItems(),
        _diagnosticService.getResults(),
      ]);
      _items = results[0] as List<DiagnosticItem>;
      _results = results[1] as List<DiagnosisResult>;

       // S'assure que les résultats sont triés par minScore pour une recherche plus facile
      _results.sort((a, b) => a.minScore.compareTo(b.minScore));

    } catch (e) {
      print("Erreur de chargement des données de diagnostic: $e");
      _error = "Impossible de charger les données de diagnostic.";
    } finally {
      // Met à jour l'interface même en cas d'erreur pour afficher le message
      if (mounted) {
         setState(() { _isLoading = false; });
         // Recalcule au cas où des données ont été chargées malgré une erreur partielle
         _calculateScoreAndDiagnosis();
      }
    }
  }

  // Met à jour les items cochés et recalcule le score/diagnostic
  void _onItemChecked(String itemId, bool isChecked) {
    setState(() {
      if (isChecked) {
        _checkedItemIds.add(itemId);
      } else {
        _checkedItemIds.remove(itemId);
      }
      // Recalcule à chaque changement
      _calculateScoreAndDiagnosis();
    });
  }

  // Calcule le score total et trouve le diagnostic correspondant
  void _calculateScoreAndDiagnosis() {
    int score = 0;
    // Crée un Map pour un accès rapide aux poids par ID (optimisation)
    final itemMap = {for (var item in _items) item.id: item};

    // Calcule le score
    for (String checkedId in _checkedItemIds) {
      final item = itemMap[checkedId];
      if (item != null) {
        score += item.weight;
      }
    }

    // Trouve le diagnostic correspondant
    DiagnosisResult? foundResult;
    // Itère sur les résultats triés pour trouver la bonne fourchette
    for (var result in _results) {
      if (score >= result.minScore && score <= result.maxScore) {
        foundResult = result;
        break; // Arrête dès qu'on trouve la bonne fourchette
      }
    }

    // Met à jour l'état avec le nouveau score et diagnostic
    // (setState est déjà appelé dans _onItemChecked, mais on le met ici aussi
    // au cas où on appelle cette fonction depuis ailleurs, comme _loadData)
    setState(() {
        _currentScore = score;
        _currentDiagnosisResult = foundResult;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerMenuWidget(pageType: PageType.diagnostics), // Adapte PageType
      appBar: PreferredSize(
        preferredSize: Size(0, 60),
        child: AppBarScreen(pageName: "Diagnostic Stress"),
      ),
      body: _buildBody(), // Appelle une méthode séparée pour le corps
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_error!, style: TextStyle(color: Colors.red, fontSize: 16)),
        ),
      );
    }
     if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Aucun élément de diagnostic trouvé.", style: TextStyle(fontSize: 16)),
        ),
      );
    }


    // Si tout est chargé, affiche la liste et les résultats
    // Utilise Column + Expanded pour que la liste prenne l'espace dispo
    // et que la zone de résultat soit toujours visible en bas.
    return SafeArea(child:
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Cochez les événements de vie qui vous sont arrivés au cours des 12 derniers mois :",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          // La liste des éléments occupe l'espace restant
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return CheckboxListTile(
                  title: Text(item.description),
                  secondary: Text('${item.weight} pts'),
                  value: _checkedItemIds.contains(item.id), // Vérifie si l'ID est dans le Set
                  onChanged: (bool? value) {
                    if (value != null) { // Gère la nullabilité
                      _onItemChecked(item.id, value);
                    }
                  },
                  controlAffinity: ListTileControlAffinity.leading, // Checkbox à gauche
                );
              },
            ),
          ),
          // Zone pour afficher le score et le diagnostic (toujours visible en bas)
          _buildResultsArea(),
        ],
      )

    );
  }

  // Widget pour afficher la zone de résultats
  Widget _buildResultsArea() {
     return Card(
      margin: EdgeInsets.all(8.0),
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Votre score total : $_currentScore",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            if (_currentDiagnosisResult != null) ...[ // Si un diagnostic correspond
              Text(
                 _currentDiagnosisResult!.diagnosisTitle,
                 style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _getRiskColor(_currentDiagnosisResult!.riskPercentage)), // Couleur basée sur risque
              ),
               if (_currentDiagnosisResult!.riskPercentage != null)
                  Text("Risque évalué à : ${_currentDiagnosisResult!.riskPercentage}%"),
               SizedBox(height: 8),
               Text(_currentDiagnosisResult!.diagnosisText),
            ] else if (_currentScore > 0) ... [ // Si score > 0 mais pas de résultat trouvé (ne devrait pas arriver avec nos données)
                Text("Impossible de déterminer le diagnostic pour ce score.", style: TextStyle(fontStyle: FontStyle.italic)),
            ] else ... [ // Si score = 0
                Text("Cochez les événements ci-dessus pour calculer votre score.", style: TextStyle(fontStyle: FontStyle.italic)),
            ]
          ],
        ),
      ),
    );
  }

  // Helper pour obtenir une couleur indicative basée sur le risque
  Color? _getRiskColor(int? risk) {
      if (risk == null) return null;
      if (risk >= 80) return Colors.red[700];
      if (risk >= 51) return Colors.orange[700];
      return Colors.green[700];
  }

}