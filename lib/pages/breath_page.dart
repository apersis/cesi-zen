import 'dart:async'; // Important pour le Timer
import 'package:cesi_zen/utils/helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Pour InputFormatters
import 'package:cesi_zen/widgets/appbar_screen.dart'; // Tes widgets perso
import 'package:cesi_zen/widgets/drawer_menu_widget.dart';

// Énumération pour les phases de respiration
enum BreathingPhase { inhale, hold, exhale }

// Classe pour définir un exercice
class BreathingExercise {
  final String name;
  final int inhale;
  final int hold;
  final int exhale;
  final bool isCustom; // Pour savoir si c'est un exercice perso

  const BreathingExercise({
    required this.name,
    required this.inhale,
    required this.hold,
    required this.exhale,
    this.isCustom = false,
  });

  // Temps total pour un cycle complet
  int get totalCycleTime => inhale + hold + exhale;

  // Pour obtenir une description simple
  String get description => '$inhale - $hold - $exhale';
}

class BreathExercisePage extends StatefulWidget {
  const BreathExercisePage({super.key});

  @override
  State<BreathExercisePage> createState() => _BreathExercisePageState();
}

class _BreathExercisePageState extends State<BreathExercisePage> {
  // --- Variables d'état ---

  // Exercices prédéfinis
  final List<BreathingExercise> _presets = const [
    BreathingExercise(name: 'Relaxation (7-4-8)', inhale: 7, hold: 4, exhale: 8),
    BreathingExercise(name: 'Équilibre (5-5)', inhale: 5, hold: 0, exhale: 5),
    BreathingExercise(name: 'Cohérence (4-6)', inhale: 4, hold: 0, exhale: 6),
  ];

  // Exercice actuellement sélectionné (initialisé au premier preset)
  late BreathingExercise _selectedExercise;
  bool _isCustomSelected = false; // Pour savoir si "Personnalisé" est coché

  // Controllers pour les champs personnalisés
  final _customInhaleController = TextEditingController(text: '4'); // Valeurs par défaut
  final _customHoldController = TextEditingController(text: '0');
  final _customExhaleController = TextEditingController(text: '6');

  // État de l'exercice en cours
  bool _isRunning = false;
  Timer? _timer; // Le timer principal pour le décompte
  BreathingPhase? _currentPhase; // Phase actuelle (inhale, hold, exhale)
  int _phaseTimer = 0; // Temps restant dans la phase actuelle
  int _cycleCount = 0; // Nombre de cycles complétés
  final int _totalCycles = 5; // Nombre total de cycles à faire

  // --- Initialisation et Nettoyage ---

  @override
  void initState() {
    super.initState();
    // Sélectionne le premier preset par défaut
    _selectedExercise = _presets[0];
    // Ajoute des listeners pour mettre à jour _selectedExercise si custom est modifié PENDANT la sélection custom
    _customInhaleController.addListener(_updateCustomExercise);
    _customHoldController.addListener(_updateCustomExercise);
    _customExhaleController.addListener(_updateCustomExercise);
  }

  // Met à jour _selectedExercise si les champs custom sont modifiés ET que custom est sélectionné
  void _updateCustomExercise() {
    if (_isCustomSelected) {
       final inhale = int.tryParse(_customInhaleController.text) ?? 0;
       final hold = int.tryParse(_customHoldController.text) ?? 0;
       final exhale = int.tryParse(_customExhaleController.text) ?? 0;
       // Met à jour seulement si les valeurs sont valides (positives, sauf hold peut être 0)
       if (inhale > 0 && hold >= 0 && exhale > 0) {
           setState(() {
              _selectedExercise = BreathingExercise(
                name: 'Personnalisé',
                inhale: inhale,
                hold: hold,
                exhale: exhale,
                isCustom: true,
              );
           });
       }
    }
  }


  @override
  void dispose() {
    _timer?.cancel(); // Arrête le timer s'il est actif
    _customInhaleController.dispose();
    _customHoldController.dispose();
    _customExhaleController.dispose();
    super.dispose();
  }

  // --- Logique de l'exercice ---

  void _startExercise() {
    // Si l'exercice est personnalisé, essaie de le créer à partir des champs
    if (_isCustomSelected) {
      final inhale = int.tryParse(_customInhaleController.text);
      final hold = int.tryParse(_customHoldController.text);
      final exhale = int.tryParse(_customExhaleController.text);

      // Validation simple
      if (inhale == null || inhale <= 0 || hold == null || hold < 0 || exhale == null || exhale <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veuillez entrer des durées valides (positives, sauf apnée >= 0).'),
            backgroundColor: Colors.orange,
          ),
        );
        return; // Ne commence pas si invalide
      }
       _selectedExercise = BreathingExercise(
         name: 'Personnalisé',
         inhale: inhale,
         hold: hold,
         exhale: exhale,
         isCustom: true
       );
    }

    // Vérifie si l'exercice sélectionné est valide (durées > 0, sauf hold >= 0)
    if (_selectedExercise.inhale <= 0 || _selectedExercise.hold < 0 || _selectedExercise.exhale <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Les durées d\'exercice doivent être valides.'),
            backgroundColor: Colors.orange,
          ),
        );
       return;
    }

    // Démarre l'exercice
    setState(() {
      _isRunning = true;
      _cycleCount = 0; // Commence au cycle 0, passera à 1 après la première expiration
      _currentPhase = BreathingPhase.inhale; // Commence par inspirer
      _phaseTimer = _selectedExercise.inhale; // Initialise le timer de phase
    });

    // Lance le timer qui se déclenche toutes les secondes
    _timer?.cancel(); // Annule un timer précédent au cas où
    _timer = Timer.periodic(Duration(seconds: 1), _tick);
  }

  void _tick(Timer timer) {
    if (!_isRunning) {
      timer.cancel();
      return;
    }

    setState(() {
      if (_phaseTimer > 1) {
        _phaseTimer--; // Décrémente le temps restant dans la phase
      } else {
        // Changement de phase
        switch (_currentPhase) {
          case BreathingPhase.inhale:
            // Passe à Apnée (si hold > 0) ou Expiration
            if (_selectedExercise.hold > 0) {
              _currentPhase = BreathingPhase.hold;
              _phaseTimer = _selectedExercise.hold;
            } else {
              _currentPhase = BreathingPhase.exhale;
              _phaseTimer = _selectedExercise.exhale;
            }
            break;
          case BreathingPhase.hold:
            // Passe à Expiration
            _currentPhase = BreathingPhase.exhale;
            _phaseTimer = _selectedExercise.exhale;
            break;
          case BreathingPhase.exhale:
            // Fin du cycle, passe au suivant ou arrête
            _cycleCount++;
            if (_cycleCount >= _totalCycles) {
              _stopExercise(); // Arrête après le nombre de cycles défini
            } else {
              // Commence un nouveau cycle -> Inspiration
              _currentPhase = BreathingPhase.inhale;
              _phaseTimer = _selectedExercise.inhale;
            }
            break;
          case null: // Ne devrait pas arriver si _isRunning est true
            _stopExercise();
            break;
        }
      }
    });
  }

  void _stopExercise() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _currentPhase = null;
      _cycleCount = 0;
      _phaseTimer = 0;
    });
  }

  // --- Fonctions d'aide pour l'UI ---

  String _getPhaseInstruction() {
    switch (_currentPhase) {
      case BreathingPhase.inhale: return 'Inspirez...';
      case BreathingPhase.hold: return 'Retenez...';
      case BreathingPhase.exhale: return 'Expirez...';
      default: return 'Prêt ?';
    }
  }

  IconData _getPhaseIcon() {
     switch (_currentPhase) {
      case BreathingPhase.inhale: return Icons.arrow_upward; // Ou Icons.expand_less, Icons.air
      case BreathingPhase.hold: return Icons.pause_circle_filled; // Ou Icons.hourglass_empty
      case BreathingPhase.exhale: return Icons.arrow_downward; // Ou Icons.expand_more, Icons.compress
      default: return Icons.play_circle_outline;
    }
  }

  // --- Construction de l'interface ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerMenuWidget(pageType: PageType.breath),
      appBar: PreferredSize(
        preferredSize: Size(0, 60),
        child: AppBarScreen(pageName: "Exercices de Respiration"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // --- MODIFICATION ICI ---
        // Ajoute un widget Center uniquement autour de l'interface de l'exercice
        child: _isRunning
            ? Center(child: _buildExerciseInterface()) // <-- ENVELOPPE AVEC CENTER
            : _buildSelectionInterface(), // L'interface de sélection reste telle quelle (utilise ListView)
        // --- FIN MODIFICATION ---
      ),
    );
  }

  // Interface de sélection des exercices
  Widget _buildSelectionInterface() {
    return ListView( // Utilise ListView pour éviter overflow si beaucoup d'options
      children: [
        Text('Choisissez un exercice :', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 10),

        // Options prédéfinies
        ..._presets.map((preset) => RadioListTile<BreathingExercise>(
              title: Text(preset.name),
              subtitle: Text('(${preset.description})'),
              value: preset,
              groupValue: _isCustomSelected ? null : _selectedExercise, // Gère la sélection
              onChanged: (BreathingExercise? value) {
                if (value != null) {
                  setState(() {
                    _isCustomSelected = false; // Décoche "Personnalisé"
                    _selectedExercise = value; // Sélectionne le preset
                  });
                }
              },
            )),

        // Option Personnalisée
         RadioListTile<bool>(
              title: Text('Personnalisé'),
              subtitle: Text('Définissez vos propres durées'),
              value: true, // La valeur pour cette option
              groupValue: _isCustomSelected, // Est-ce que cette option est sélectionnée ?
              onChanged: (bool? value) {
                if (value == true) {
                  setState(() {
                    _isCustomSelected = true; // Coche "Personnalisé"
                    _updateCustomExercise(); // Met à jour _selectedExercise avec les valeurs actuelles des champs
                  });
                }
              },
          ),

        // Champs personnalisés (visibles seulement si "Personnalisé" est coché)
        if (_isCustomSelected)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCustomTimeInput('Inspirez', _customInhaleController),
                _buildCustomTimeInput('Apnée', _customHoldController),
                _buildCustomTimeInput('Expirez', _customExhaleController),
              ],
            ),
          ),

        SizedBox(height: 30),

        // Bouton Démarrer
        Center(
          child: ElevatedButton.icon(
            icon: Icon(Icons.play_arrow),
            label: Text('Démarrer l\'exercice (${_selectedExercise.name})'),
            style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
            onPressed: _startExercise, // Appelle la fonction pour démarrer
          ),
        ),
      ],
    );
  }

  // Helper pour créer les champs de saisie numérique personnalisés
  Widget _buildCustomTimeInput(String label, TextEditingController controller) {
    return Expanded( // Pour que les champs prennent l'espace disponible
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
            isDense: true, // Rend le champ plus compact
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly], // N'autorise que les chiffres
          textAlign: TextAlign.center,
        ),
      ),
    );
  }


  // Interface affichée pendant l'exercice
  Widget _buildExerciseInterface() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Cycle ${_cycleCount + 1} / $_totalCycles', style: Theme.of(context).textTheme.titleMedium),
        Spacer(flex: 1), // Pousse le contenu vers le centre/bas
        // Icône dynamique (pourrait être remplacée par une animation plus tard)
        Icon(
          _getPhaseIcon(),
          size: 100, // Grande icône
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: 20),

        // Instruction de phase
        Text(
          _getPhaseInstruction(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),

        // Temps restant dans la phase
        Text(
          '$_phaseTimer s',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),

        Spacer(flex: 2), // Plus d'espace avant le bouton stop

        // Bouton Arrêter
        ElevatedButton.icon(
          icon: Icon(Icons.stop),
          label: Text('Arrêter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)
          ),
          onPressed: _stopExercise, // Appelle la fonction pour arrêter
        ),
        SizedBox(height: 20), // Espace en bas
      ],
    );
  }
}