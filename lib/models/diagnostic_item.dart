// Optionnel: Mettre dans lib/models/diagnostic_item.dart
class DiagnosticItem {
  final String id;
  final String description;
  final int weight;

  DiagnosticItem({required this.id, required this.description, required this.weight});

  // Factory constructor pour créer une instance depuis un JSON (Map)
  factory DiagnosticItem.fromJson(Map<String, dynamic> json) {
    return DiagnosticItem(
      id: json['id'] as String,
      description: json['description'] as String,
      weight: json['weight'] as int,
    );
  }

  // Méthode pour convertir une instance en JSON (utile si on écrit plus tard)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'weight': weight,
    };
  }
}

// Optionnel: Mettre dans lib/models/diagnosis_result.dart
class DiagnosisResult {
  final String id;
  final int minScore;
  final int maxScore;
  final String diagnosisTitle;
  final int? riskPercentage; // Optionnel
  final String diagnosisText;

  DiagnosisResult({
    required this.id,
    required this.minScore,
    required this.maxScore,
    required this.diagnosisTitle,
    this.riskPercentage,
    required this.diagnosisText,
  });

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    return DiagnosisResult(
      id: json['id'] as String,
      minScore: json['minScore'] as int,
      maxScore: json['maxScore'] as int,
      diagnosisTitle: json['diagnosisTitle'] as String,
      riskPercentage: json['riskPercentage'] as int?, // Gère le cas où ce n'est pas présent
      diagnosisText: json['diagnosisText'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'minScore': minScore,
      'maxScore': maxScore,
      'diagnosisTitle': diagnosisTitle,
      'riskPercentage': riskPercentage,
      'diagnosisText': diagnosisText,
    };
  }
}