import 'package:edumetrics/core/activity_names.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests del mapeo de actividades usado por el servicio de exportación.
///
/// Importamos `activity_names.dart` (sin dependencias web) en lugar de
/// `export_service.dart` para que los tests puedan correr sobre la VM
/// de Dart con `flutter test`, no únicamente con `--platform chrome`.
void main() {
  group('ExportService - Mapeo de actividades', () {
    test('Contiene las 10 actividades del proyecto', () {
      expect(kActivityNames.length, 10);
    });

    test('Incluye todas las claves matemáticas y de lengua', () {
      const expectedKeys = [
        // Matemáticas
        'comparison',
        'sequence',
        'place_value',
        'addition',
        'subtraction',
        // Lengua
        'missing_vowels',
        'syllable_count',
        'sentence_order',
        'capitalization',
        'syllable_complete',
      ];
      for (final key in expectedKeys) {
        expect(
          kActivityNames.containsKey(key),
          isTrue,
          reason: 'Falta la clave: $key',
        );
      }
    });

    test('Nombres en español son legibles', () {
      expect(kActivityNames['comparison'], 'Comparación');
      expect(kActivityNames['addition'], 'Sumas');
      expect(kActivityNames['subtraction'], 'Restas');
      expect(kActivityNames['missing_vowels'], 'Vocales');
      expect(kActivityNames['syllable_count'], 'Sílabas');
      expect(kActivityNames['sentence_order'], 'Ordenar Frases');
      expect(kActivityNames['capitalization'], 'Mayúsculas');
      expect(kActivityNames['syllable_complete'], 'Completar Sílabas');
    });

    test('Ningún valor está vacío ni es null', () {
      for (final entry in kActivityNames.entries) {
        expect(
          entry.value.trim().isNotEmpty,
          isTrue,
          reason: 'El nombre para "${entry.key}" está vacío',
        );
      }
    });

    test('No hay nombres duplicados', () {
      final values = kActivityNames.values.toList();
      expect(
        values.toSet().length,
        values.length,
        reason: 'Hay nombres de actividad duplicados',
      );
    });

    test('Las claves usan snake_case (minúsculas y guiones bajos)', () {
      final pattern = RegExp(r'^[a-z_]+$');
      for (final key in kActivityNames.keys) {
        expect(pattern.hasMatch(key), isTrue, reason: 'Clave inválida: $key');
      }
    });
  });
}
