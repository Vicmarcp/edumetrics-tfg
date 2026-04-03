import 'package:edumetrics/core/accessibility_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccessibilityService - Tamaño de fuente', () {
    setUp(() {
      AccessibilityService.fontScale.value = 1.0;
    });

    test('setFontSize "small" reduce escala a 0.85', () {
      AccessibilityService.setFontSize('small');
      expect(AccessibilityService.fontScale.value, 0.85);
      expect(AccessibilityService.currentFontSizeLabel, 'small');
    });

    test('setFontSize "large" aumenta escala a 1.2', () {
      AccessibilityService.setFontSize('large');
      expect(AccessibilityService.fontScale.value, 1.2);
      expect(AccessibilityService.currentFontSizeLabel, 'large');
    });

    test('setFontSize "normal" devuelve escala a 1.0', () {
      AccessibilityService.setFontSize('large');
      AccessibilityService.setFontSize('normal');
      expect(AccessibilityService.fontScale.value, 1.0);
      expect(AccessibilityService.currentFontSizeLabel, 'normal');
    });

    test('Valor desconocido se trata como normal', () {
      AccessibilityService.setFontSize('xyz');
      expect(AccessibilityService.fontScale.value, 1.0);
    });
  });

  group('AccessibilityService - Modo daltónico', () {
    setUp(() {
      AccessibilityService.colorblindMode.value = false;
    });

    test('Sin modo daltónico, color correcto es verde', () {
      expect(AccessibilityService.correctColor, Colors.green);
    });

    test('Sin modo daltónico, color error es rojo', () {
      expect(AccessibilityService.errorColor, Colors.red);
    });

    test('Con modo daltónico, color correcto es azul (Wong)', () {
      AccessibilityService.colorblindMode.value = true;
      expect(AccessibilityService.correctColor, const Color(0xFF0072B2));
    });

    test('Con modo daltónico, color error es naranja (Wong)', () {
      AccessibilityService.colorblindMode.value = true;
      expect(AccessibilityService.errorColor, const Color(0xFFD55E00));
    });

    test('chartBarColor según porcentaje sin daltónico', () {
      expect(AccessibilityService.chartBarColor(80), Colors.green);
      expect(AccessibilityService.chartBarColor(60), Colors.orange);
      expect(AccessibilityService.chartBarColor(30), Colors.red);
    });

    test('chartBarColor según porcentaje con daltónico', () {
      AccessibilityService.colorblindMode.value = true;
      expect(AccessibilityService.chartBarColor(80), const Color(0xFF0072B2));
      expect(AccessibilityService.chartBarColor(60), const Color(0xFFE69F00));
      expect(AccessibilityService.chartBarColor(30), const Color(0xFFD55E00));
    });

    test('chartColors tiene 10 colores', () {
      expect(AccessibilityService.chartColors.length, 10);
      AccessibilityService.colorblindMode.value = true;
      expect(AccessibilityService.chartColors.length, 10);
    });
  });

  group('AccessibilityService - Alto contraste', () {
    setUp(() {
      AccessibilityService.highContrast.value = false;
    });

    test('Sin alto contraste, borderWidth es 2.0', () {
      expect(AccessibilityService.borderWidth, 2.0);
    });

    test('Con alto contraste, borderWidth es 5.0', () {
      AccessibilityService.highContrast.value = true;
      expect(AccessibilityService.borderWidth, 5.0);
    });
  });
}
