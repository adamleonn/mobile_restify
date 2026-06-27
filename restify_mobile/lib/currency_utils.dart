import 'package:intl/intl.dart';

String formatRupiah(dynamic price) {
  if (price == null) return "Rp 0,00";
  String str = price.toString().trim();
  if (str.isEmpty) return "Rp 0,00";

  // Handle standard Indonesian formatting if it's already formatted
  if (str.contains(',') && str.contains('.')) {
    // e.g. "Rp 650.000,00" or "650.000,00"
    str = str.replaceAll('.', '').replaceAll(',', '.');
  } else if (str.contains(',')) {
    // e.g. "650000,00" or "Rp 650000,00"
    str = str.replaceAll(',', '.');
  }

  // Clean string from any non-numeric except optional dot or minus
  final cleanString = str.replaceAll(RegExp(r'[^0-9.-]'), '');
  final value = double.tryParse(cleanString) ?? 0.0;

  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 2,
  ).format(value);
}

int parseRupiah(dynamic price) {
  if (price == null) return 0;
  if (price is num) return price.toInt();
  String str = price.toString().trim();
  if (str.isEmpty) return 0;

  // Clean currency prefix and spacing
  str = str.replaceAll(RegExp(r'[Rp\s]'), '');

  // If it has both dot and comma (e.g. 650.000,00), it's standard IDR format
  if (str.contains(',') && str.contains('.')) {
    // Split by comma to get the integer part
    str = str.split(',')[0].replaceAll('.', '');
  } else if (str.contains(',')) {
    // If it only contains comma, e.g. 650000,00
    str = str.split(',')[0];
  } else if (str.contains('.')) {
    // If it only contains dot, e.g. 650.000 (thousands separator)
    // or maybe 650000.00 (decimal point)
    final parts = str.split('.');
    if (parts.length == 2 && parts[1].length <= 2) {
      // e.g. 650000.00 -> 650000
      str = parts[0];
    } else {
      // e.g. 650.000 -> 650000
      str = str.replaceAll('.', '');
    }
  }

  // Remove any remaining non-digit characters
  str = str.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(str) ?? 0;
}

