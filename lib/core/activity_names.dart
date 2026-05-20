/// Mapeo de claves de actividad a sus nombres legibles en español.
///
/// Se mantiene en un archivo aparte (sin dependencias de `dart:html` /
/// `package:web`) para poder ser importado en tests que corren sobre la
/// VM de Dart, no únicamente en el navegador.
const Map<String, String> kActivityNames = {
  'comparison': 'Comparación',
  'sequence': 'Secuencia',
  'place_value': 'Valor Posicional',
  'addition': 'Sumas',
  'subtraction': 'Restas',
  'missing_vowels': 'Vocales',
  'syllable_count': 'Sílabas',
  'sentence_order': 'Ordenar Frases',
  'capitalization': 'Mayúsculas',
  'syllable_complete': 'Completar Sílabas',
};
