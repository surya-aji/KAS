// Date and time formatting utilities.
//
// Timestamps are stored in UTC (section 4.2 of the
// implementation plan) and displayed in local time.

import 'package:intl/intl.dart';

class DateTimeFormatter {
  DateTimeFormatter._();

  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _timeFormat = DateFormat('HH:mm');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _fullDateTimeFormat = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');

  /// Formats a UTC [DateTime] to a local date string.
  ///
  /// Example: `25/10/2026`
  static String formatDate(DateTime utcDateTime) {
    return _dateFormat.format(utcDateTime.toLocal());
  }

  /// Formats a UTC [DateTime] to a local time string.
  ///
  /// Example: `17:30`
  static String formatTime(DateTime utcDateTime) {
    return _timeFormat.format(utcDateTime.toLocal());
  }

  /// Formats a UTC [DateTime] to a local date-time string.
  ///
  /// Example: `25/10/2026 17:30`
  static String formatDateTime(DateTime utcDateTime) {
    return _dateTimeFormat.format(utcDateTime.toLocal());
  }

  /// Formats a UTC [DateTime] to a full local date-time string.
  ///
  /// Example: `25 Oktober 2026, 17:30`
  static String formatFullDateTime(DateTime utcDateTime) {
    return _fullDateTimeFormat.format(utcDateTime.toLocal());
  }
}
