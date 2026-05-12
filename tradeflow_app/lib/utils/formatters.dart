import 'package:intl/intl.dart';

final NumberFormat _frNumber = NumberFormat('#,###', 'fr_FR');

String formatFCFA(num amount) {
  final s = _frNumber.format(amount).replaceAll(',', ' ').replaceAll(' ', ' ');
  return '$s FCFA';
}

String formatNumber(num amount) {
  return _frNumber.format(amount).replaceAll(',', ' ').replaceAll(' ', ' ');
}

String formatCompactFCFA(num amount) {
  if (amount >= 1000000) {
    final v = amount / 1000000;
    final s = v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    return '${s.replaceAll('.', ',')}M FCFA';
  }
  if (amount >= 1000) {
    final v = amount / 1000;
    return '${v.toStringAsFixed(0)}K FCFA';
  }
  return formatFCFA(amount);
}
