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
