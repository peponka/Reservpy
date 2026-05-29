import 'package:intl/intl.dart';

/// Date/time formatting helpers.
class AppDateUtils {
  AppDateUtils._();

  static final _dayFormat = DateFormat('EEEE d', 'es');
  static final _shortDate = DateFormat('dd/MM/yyyy');
  static final _timeFormat = DateFormat('HH:mm');
  static final _fullDate = DateFormat("d 'de' MMMM, yyyy", 'es');
  static final _dayMonth = DateFormat("d 'de' MMMM", 'es');

  static String formatDay(DateTime date) => _dayFormat.format(date);
  static String formatShortDate(DateTime date) => _shortDate.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);
  static String formatFullDate(DateTime date) => _fullDate.format(date);
  static String formatDayMonth(DateTime date) => _dayMonth.format(date);

  static String formatTimeRange(DateTime start, DateTime end) {
    return '${_timeFormat.format(start)} - ${_timeFormat.format(end)}';
  }

  static String timeOfDayToString(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool isOpen(int openHour, int openMinute, int closeHour, int closeMinute) {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final openMinutes = openHour * 60 + openMinute;
    final closeMinutes = closeHour * 60 + closeMinute;
    return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
  }

  /// Generates time slots between [start] and [end] with [durationMinutes] gaps.
  static List<DateTime> generateSlots(
    DateTime day,
    int startHour,
    int startMinute,
    int endHour,
    int endMinute,
    int durationMinutes,
  ) {
    final slots = <DateTime>[];
    var current = DateTime(day.year, day.month, day.day, startHour, startMinute);
    final endTime = DateTime(day.year, day.month, day.day, endHour, endMinute);

    while (current.add(Duration(minutes: durationMinutes)).isBefore(endTime) ||
        current.add(Duration(minutes: durationMinutes)).isAtSameMomentAs(endTime)) {
      slots.add(current);
      current = current.add(Duration(minutes: durationMinutes));
    }
    return slots;
  }
}
