// lib/models/relaxation_activity.dart
class RelaxationActivity {
  final String id;
  final String title;
  final String description;
  final String category; // Ex: "Pleine conscience", "Créatif", "Physique", "Nature"
  final String? imageUrl; // Optionnel: URL d'une image illustrative
  final String? durationEstimate; // Optionnel: Ex: "5 min", "15-30 min"

  RelaxationActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
    this.durationEstimate,
  });

  factory RelaxationActivity.fromJson(Map<String, dynamic> json) {
    return RelaxationActivity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String?,
      durationEstimate: json['durationEstimate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'durationEstimate': durationEstimate,
    };
  }
}