import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class UgxInputFormatter extends TextInputFormatter {
  UgxInputFormatter() : _format = NumberFormat.decimalPattern();

  final NumberFormat _format;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final formatted = _format.format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
