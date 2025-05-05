import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cesi_zen/services/auth_service.dart';

class MockDirectory extends Mock implements Directory {}

class MockFile extends Mock implements File {}

void main() {
  group('loadUsers', () {
    test(
      'devrait charger les utilisateurs depuis un fichier existant',
      () async {
        final mockDir = MockDirectory();
        final mockFile = MockFile();
        final _authService = AuthService();

        when(() => mockDir.path).thenReturn('/fake/path');
        when(() => mockFile.exists()).thenAnswer(() async => true);
        when(() => mockFile.readAsString()).thenAnswer(
          () async => jsonEncode([
            {'nom': 'admin'},
            {'nom': 'tom'},
          ]),
        );

        final result = await _authService._readUsers(
          getDir: () async => mockDir,
          getFile: (path) => mockFile,
        );

        expect(result.length, 2);
        expect(result[0]['nom'], equals('admin'));
        expect(result[1]['nom'], equals('tom'));
      },
    );

    test('doit lancer une exception si le fichier est manquant', () async {
      final mockDir = MockDirectory();
      final mockFile = MockFile();

      when(() => mockDir.path).thenReturn('/fake/path');
      when(() => mockFile.exists()).thenAnswer(() async => false);

      expect(
        () =>
            loadUsers(getDir: () async => mockDir, getFile: (path) => mockFile),
        throwsException,
      );
    });
  });
}