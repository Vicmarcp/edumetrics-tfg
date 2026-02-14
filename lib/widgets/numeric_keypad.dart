import 'package:flutter/material.dart';

class NumericKeypad extends StatefulWidget {
  final int maxDigits; // 1 para unidades, 2 para decenas+unidades
  final Function(String) onSubmit;
  final bool showDecenas; // Si true, colorea primer dígito naranja

  const NumericKeypad({
    super.key,
    required this.maxDigits,
    required this.onSubmit,
    this.showDecenas = false,
  });

  @override
  State<NumericKeypad> createState() => _NumericKeypadState();
}

class _NumericKeypadState extends State<NumericKeypad> {
  String _currentValue = '';

  void _onNumberPressed(int number) {
    if (_currentValue.length < widget.maxDigits) {
      setState(() {
        _currentValue += number.toString();
      });
    }
  }

  void _onDelete() {
    if (_currentValue.isNotEmpty) {
      setState(() {
        _currentValue = _currentValue.substring(0, _currentValue.length - 1);
      });
    }
  }

  void _onSubmit() {
    if (_currentValue.isNotEmpty) {
      widget.onSubmit(_currentValue);
      setState(() {
        _currentValue = '';
      });
    }
  }

  Color _getDigitColor(int index) {
    // Si es el primer dígito y showDecenas está activo → naranja
    if (index == 0 && widget.showDecenas && _currentValue.length > 1) {
      return Colors.orange;
    }
    // Resto de dígitos (unidades) → azul estándar por ahora
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Display del número construido
        Container(
          width: 300,
          height: 100,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade400, width: 3),
          ),
          child: Center(
            child: _currentValue.isEmpty
                ? Text(
              '?',
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _currentValue.split('').asMap().entries.map((entry) {
                return Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: _getDigitColor(entry.key),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Grid numérico 3x4
        SizedBox(
          width: 300,
          child: Column(
            children: [
              // Fila 1-2-3
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKey('1', () => _onNumberPressed(1)),
                  _buildKey('2', () => _onNumberPressed(2)),
                  _buildKey('3', () => _onNumberPressed(3)),
                ],
              ),
              const SizedBox(height: 12),

              // Fila 4-5-6
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKey('4', () => _onNumberPressed(4)),
                  _buildKey('5', () => _onNumberPressed(5)),
                  _buildKey('6', () => _onNumberPressed(6)),
                ],
              ),
              const SizedBox(height: 12),

              // Fila 7-8-9
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKey('7', () => _onNumberPressed(7)),
                  _buildKey('8', () => _onNumberPressed(8)),
                  _buildKey('9', () => _onNumberPressed(9)),
                ],
              ),
              const SizedBox(height: 12),

              // Fila Borrar-0-Confirmar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKey('←', _onDelete, isAction: true, color: Colors.red),
                  _buildKey('0', () => _onNumberPressed(0)),
                  _buildKey('✓', _onSubmit, isAction: true, color: Colors.green),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKey(String label, VoidCallback onPressed, {bool isAction = false, Color? color}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(90, 90),
        backgroundColor: color ?? Colors.blue,
        foregroundColor: Colors.white,
        textStyle: TextStyle(
          fontSize: isAction ? 32 : 40,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Text(label),
    );
  }
}