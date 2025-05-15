import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cesi_zen/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final AuthService _authService = AuthService();

  late Directory tempDir;
  late File userFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('test_users');
    userFile = File('${tempDir.path}/utilisateurs.json');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /*test('ajoute un nouvel utilisateur avec succès', () async {
    SharedPreferences.setMockInitialValues({}); // Simule des prefs vides
    final prefs = await SharedPreferences.getInstance();

    final result = await _authService.register(
      'test','test',false,
    );

    // L'utilisateur a bien été ajouté
    expect(result, true);

    // Le fichier a bien été créé et contient l'utilisateur
    final contenu = jsonDecode(await userFile.readAsString());
    expect(contenu.length, 1);
    expect(contenu[0]['username'], 'test');

    // L'adresse email a bien été stockée dans les prefs
    expect(prefs.getString('username'), 'test');
  });*/

  test('1+1=2', () async {
    int result = 1 + 1;
    expect(result, 2);
  });
}