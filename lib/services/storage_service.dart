import 'dart:io';
import 'package:path_provider/path_provider.dart';

abstract class StorageService {
  Future<String?> readFile(String fileName, {String? defaultContent});
  Future<void> writeFile(String fileName, String content);
}

class FileStorageService implements StorageService {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _localFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  @override
  Future<String?> readFile(String fileName, {String? defaultContent}) async {
    try {
      final file = await _localFile(fileName);
      if (await file.exists()) {
        final content = await file.readAsString();
        return content.isEmpty ? null : content; // Retourne null si vide
      } else if (defaultContent != null) {
        // Si le fichier n'existe pas et qu'un contenu par défaut est fourni,
        // on écrit le défaut et on le retourne.
        await writeFile(fileName, defaultContent);
        return defaultContent;
      }
      return null; // Fichier n'existe pas, pas de défaut fourni
    } catch (e) {
      print("Erreur lecture fichier $fileName (FileStorageService): $e");
      // Peut-être retourner null ou lancer une exception spécifique
      return null;
    }
  }

  @override
  Future<void> writeFile(String fileName, String content) async {
     try {
        final file = await _localFile(fileName);
        await file.writeAsString(content);
     } catch (e) {
        print("Erreur écriture fichier $fileName (FileStorageService): $e");
        // Relancer l'exception ou gérer autrement
        rethrow;
     }
  }
}