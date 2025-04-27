// lib/models/info_item.dart
class InfoItem {
  final String id;
  final String title;
  final String description;
  final String routePath; // Le chemin ou nom de route pour go_router (ex: '/home', 'user_profile')
  final String? iconName; // Nom de l'icône Material (ex: 'home', 'person', 'spa') - optionnel

  InfoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.routePath,
    this.iconName,
  });

  factory InfoItem.fromJson(Map<String, dynamic> json) {
    return InfoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      routePath: json['routePath'] as String,
      iconName: json['iconName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'routePath': routePath,
      'iconName': iconName,
    };
  }
}