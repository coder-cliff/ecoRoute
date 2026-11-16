import 'package:intl/intl.dart';

String formatUgx(int value) {
  return '${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')} UGX';
}

String formatCurrencyUgx(int value) => formatUgx(value);

/// Format an amount in Uganda Shillings using the intl package.
String formatUGX(int amount) =>
    NumberFormat.currency(locale: 'en_UG', symbol: 'UGX ', decimalDigits: 0).format(amount);

/// Format a date as "dd MMM yyyy" e.g. "13 Nov 2026".
String formatDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);

/// Format a date and time as "dd MMM yyyy, HH:mm" e.g. "13 Nov 2026, 09:55".
String formatDateTime(DateTime d) => DateFormat('dd MMM yyyy, HH:mm').format(d);

/// Format a duration in minutes as "1h 30m" or "45m".
String formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return h > 0 ? '${h}h ${m}m' : '${m}m';
}

/// Truncate a string to [maxLen] characters, appending "..." if truncated.
String truncate(String s, int maxLen) =>
    s.length > maxLen ? '${s.substring(0, maxLen)}...' : s;
