// --- Modèles ---

class BaseEmotion {
  final String id;
  final String name;
  // Optionnel: Couleur ou icône associée
  // final Color color;
  // final IconData icon;

  BaseEmotion({required this.id, required this.name});

  factory BaseEmotion.fromJson(Map<String, dynamic> json) {
    return BaseEmotion(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class SpecificEmotion {
  final String id;
  final String name;
  final String baseEmotionId; // Lien vers l'émotion de base

  SpecificEmotion({required this.id, required this.name, required this.baseEmotionId});

   factory SpecificEmotion.fromJson(Map<String, dynamic> json) {
    return SpecificEmotion(
      id: json['id'],
      name: json['name'],
      baseEmotionId: json['baseEmotionId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseEmotionId': baseEmotionId,
  };
}

class EmotionLogEntry {
  final String id; // ID unique pour cette entrée de log
  final String userId; // ID de l'utilisateur qui a loggé
  final String specificEmotionId; // ID de l'émotion spécifique choisie
  final String baseEmotionId; // ID de l'émotion de base (redondant mais utile)
  final DateTime timestamp; // Date et heure de l'enregistrement
  final String? notes; // Notes optionnelles ajoutées par l'utilisateur

  EmotionLogEntry({
    required this.id,
    required this.userId,
    required this.specificEmotionId,
    required this.baseEmotionId,
    required this.timestamp,
    this.notes,
  });

   factory EmotionLogEntry.fromJson(Map<String, dynamic> json) {
    return EmotionLogEntry(
      id: json['id'],
      userId: json['userId'],
      specificEmotionId: json['specificEmotionId'],
      baseEmotionId: json['baseEmotionId'],
      // Gère la conversion depuis String (ISO 8601) ou int (millisecondsSinceEpoch)
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'specificEmotionId': specificEmotionId,
    'baseEmotionId': baseEmotionId,
    'timestamp': timestamp.toIso8601String(), // Stocke en format standard ISO
    'notes': notes,
  };
}