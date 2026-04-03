import 'package:flutter_test/flutter_test.dart';

/// Tests de lógica de validación de actividades.
/// Replican la lógica de validateAnswer de cada actividad para
/// poder ejecutarse sin contexto Flutter.
void main() {
  group('Comparación numérica', () {
    bool validate(int num1, int num2, String userAnswer) {
      final correct = num1 > num2 ? 'mayor' : 'menor';
      return userAnswer == correct;
    }

    test('15 > 8: respuesta "mayor" es correcta', () {
      expect(validate(15, 8, 'mayor'), true);
    });

    test('5 < 12: respuesta "menor" es correcta', () {
      expect(validate(5, 12, 'menor'), true);
    });

    test('Respuesta incorrecta es rechazada', () {
      expect(validate(15, 8, 'menor'), false);
    });
  });

  group('Secuencia numérica', () {
    bool validate(int correctAnswer, String userAnswer) {
      try {
        return int.parse(userAnswer) == correctAnswer;
      } catch (_) {
        return false;
      }
    }

    test('Número correcto entre 4 y 6 es 5', () {
      expect(validate(5, '5'), true);
    });

    test('Texto no numérico es rechazado', () {
      expect(validate(5, 'cinco'), false);
    });
  });

  group('Sumas', () {
    bool validate(int correctAnswer, String userAnswer) {
      try {
        return int.parse(userAnswer) == correctAnswer;
      } catch (_) {
        return false;
      }
    }

    test('3 + 4 = 7', () => expect(validate(7, '7'), true));
    test('Resultado erróneo se rechaza', () => expect(validate(7, '8'), false));
  });

  group('Restas', () {
    bool validate(int correctAnswer, String userAnswer) {
      try {
        return int.parse(userAnswer) == correctAnswer;
      } catch (_) {
        return false;
      }
    }

    test('9 - 3 = 6', () => expect(validate(6, '6'), true));
    test(
      'No acepta resultados negativos como texto',
      () => expect(validate(6, '-6'), false),
    );
  });

  group('Valor posicional', () {
    bool validate(int correctAnswer, String userAnswer) {
      try {
        return int.parse(userAnswer) == correctAnswer;
      } catch (_) {
        return false;
      }
    }

    test('14 tiene 1 decena', () => expect(validate(1, '1'), true));
    test('14 tiene 4 unidades', () => expect(validate(4, '4'), true));
  });

  group('Vocales perdidas', () {
    bool validate(String hiddenVowel, String userAnswer) {
      return userAnswer == hiddenVowel;
    }

    test('GATO con A oculta acepta A', () {
      expect(validate('A', 'A'), true);
    });

    test('GATO con A oculta rechaza E', () {
      expect(validate('A', 'E'), false);
    });
  });

  group('Contar sílabas', () {
    bool validate(int syllables, dynamic userAnswer) {
      return userAnswer == syllables;
    }

    test('CASA tiene 2 sílabas', () => expect(validate(2, 2), true));
    test('MARIPOSA tiene 4 sílabas', () => expect(validate(4, 4), true));
    test(
      'Respuesta incorrecta se rechaza',
      () => expect(validate(2, 3), false),
    );
  });

  group('Ordenar frases', () {
    bool validate(String sentence, String userAnswer) {
      return userAnswer == sentence;
    }

    test('Frase ordenada correctamente', () {
      expect(validate('El gato bebe agua', 'El gato bebe agua'), true);
    });

    test('Orden incorrecto se rechaza', () {
      expect(validate('El gato bebe agua', 'gato El bebe agua'), false);
    });
  });

  group('Mayúsculas', () {
    bool validate(String sentence, int correctIndex, String userAnswer) {
      final words = sentence.split(' ');
      return userAnswer == words[correctIndex];
    }

    test('Inicio de frase: "el" es la palabra correcta', () {
      expect(validate('el gato duerme', 0, 'el'), true);
    });

    test('Nombre propio: "maria" es correcta', () {
      expect(validate('yo soy maria', 2, 'maria'), true);
    });
  });

  group('Completar sílabas', () {
    bool validate(String correctAnswer, String userAnswer) {
      return userAnswer == correctAnswer;
    }

    test('GA-TO con TO oculta acepta TO', () {
      expect(validate('TO', 'TO'), true);
    });

    test('GA-TO con TO oculta rechaza TA', () {
      expect(validate('TO', 'TA'), false);
    });
  });

  group('Sanitización de nombres', () {
    String sanitize(String name) {
      return name
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
    }

    test('Espacios se reemplazan por guiones bajos', () {
      expect(sanitize('Pepe Garcia'), 'Pepe_Garcia');
    });

    test('Caracteres especiales se eliminan', () {
      expect(sanitize('María/Juan'), 'MaraJuan');
    });

    test('Nombre simple se mantiene igual', () {
      expect(sanitize('Pepe'), 'Pepe');
    });
  });
}
