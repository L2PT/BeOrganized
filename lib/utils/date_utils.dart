import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:venturiautospurghi/utils/global_constants.dart';

class DateUtils {
  static final DateFormat _monthFormat = DateFormat('MMMM yyyy');
  static final DateFormat _dayFormat = DateFormat('dd');
  static final DateFormat _firstDayFormat = DateFormat('MMM dd');
  static final DateFormat _fullDayFormat = DateFormat('EEE MMM dd, yyyy');
  static final DateFormat _apiDayFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _hoverDateFormat = DateFormat('EEEE, dd MMMM', 'it_IT');
  static final DateFormat _tableDateFormat = DateFormat('dd MMMM yyyy', 'it_IT');
  static final DateFormat _pdfDateFormat = DateFormat('EEEE, dd MMMM yyyy', 'it_IT');
  static final DateFormat _hoverTimeFormat = DateFormat('HH:mm');
  static final DateFormat _hoverDateFormatDiff = DateFormat('dd MMMM hh:mm', 'it_IT');

  static String formatMonth(DateTime d) => _monthFormat.format(d);

  static String formatDay(DateTime d) => _dayFormat.format(d);

  static String formatFirstDay(DateTime d) => _firstDayFormat.format(d);

  static String fullDayFormat(DateTime d) => _fullDayFormat.format(d);

  static String apiDayFormat(DateTime d) => _apiDayFormat.format(d);

  static String hoverDateFormat(DateTime d) => _hoverDateFormat.format(d);

  static String hoverTimeFormat(DateTime d) => _hoverTimeFormat.format(d);

  static String hoverDateFormatDiff(DateTime d) => _hoverDateFormatDiff.format(d);

  static String pdfDateFormat(DateTime d) => _pdfDateFormat.format(d);

  static String tableDateFormat(DateTime d) => _tableDateFormat.format(d);

  static const List<String> weekdays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat'
  ];

  /// The list of days in a given month
  static List<DateTime> daysInMonth(DateTime month) {
    var first = firstDayOfMonth(month);
    var daysBefore = first.weekday;
    var firstToDisplay = first.subtract(Duration(days: daysBefore));
    var last = DateUtils.lastDayOfMonth(month);

    var daysAfter = 7 - last.weekday;

    // If the last day is sunday (7) the entire week must be rendered
    if (daysAfter == 0) {
      daysAfter = 7;
    }

    var lastToDisplay = last.add(Duration(days: daysAfter));
    return daysInRange(firstToDisplay, lastToDisplay).toList();
  }

  static bool isFirstDayOfMonth(DateTime day) {
    return isSameDay(firstDayOfMonth(day), day);
  }

  static bool isLastDayOfMonth(DateTime day) {
    return isSameDay(lastDayOfMonth(day), day);
  }

  static DateTime firstDayOfMonth(DateTime month) {
    return DateTime(month.year, month.month);
  }

  static DateTime firstDayOfWeek(DateTime day) {
    /// Handle Daylight Savings by setting hour to 12:00 Noon
    /// rather than the default of Midnight
    day = DateTime.utc(day.year, day.month, day.day, 12);

    /// Weekday is on a 1-7 scale Monday - Sunday,
    /// This Calendar works from Sunday - Monday
    var decreaseNum = day.weekday % 7;
    return day.subtract(Duration(days: decreaseNum));
  }

  static DateTime lastDayOfWeek(DateTime day) {
    /// Handle Daylight Savings by setting hour to 12:00 Noon
    /// rather than the default of Midnight
    day = DateTime.utc(day.year, day.month, day.day, 12);

    /// Weekday is on a 1-7 scale Monday - Sunday,
    /// This Calendar's Week starts on Sunday
    var increaseNum = day.weekday % 7;
    return day.add(Duration(days: 7 - increaseNum));
  }

  /// The last day of a given month
  static DateTime lastDayOfMonth(DateTime month) {
    var beginningNextMonth = (month.month < 12)
        ? DateTime(month.year, month.month + 1, 1)
        : DateTime(month.year + 1, 1, 1);
    return beginningNextMonth.subtract(Duration(days: 1));
  }

  /// Returns a [DateTime] for each day the given range.
  ///
  /// [start] inclusive
  /// [end] exclusive
  static Iterable<DateTime> daysInRange(DateTime start, DateTime end) sync* {
    var i = start;
    var offset = start.timeZoneOffset;
    while (i.isBefore(end)) {
      yield i;
      i = i.add(Duration(days: 1));
      var timeZoneDiff = i.timeZoneOffset - offset;
      if (timeZoneDiff.inSeconds != 0) {
        offset = i.timeZoneOffset;
        i = i.subtract(Duration(seconds: timeZoneDiff.inSeconds));
      }
    }
  }

  /// Whether or not two times are on the same day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isSameWeek(DateTime a, DateTime b) {
    /// Handle Daylight Savings by setting hour to 12:00 Noon
    /// rather than the default of Midnight
    a = DateTime.utc(a.year, a.month, a.day);
    b = DateTime.utc(b.year, b.month, b.day);

    var diff = a.toUtc().difference(b.toUtc()).inDays;
    if (diff.abs() >= 7) {
      return false;
    }

    var min = a.isBefore(b) ? a : b;
    var max = a.isBefore(b) ? b : a;
    var result = max.weekday % 7 - min.weekday % 7 >= 0;
    return result;
  }

  static DateTime previousMonth(DateTime m) {
    var year = m.year;
    var month = m.month;
    if (month == 1) {
      year--;
      month = 12;
    } else {
      month--;
    }
    return DateTime(year, month);
  }

  static DateTime nextMonth(DateTime m) {
    var year = m.year;
    var month = m.month;

    if (month == 12) {
      year++;
      month = 1;
    } else {
      month++;
    }
    return DateTime(year, month);
  }

  static DateTime previousWeek(DateTime w) {
    return w.subtract(Duration(days: 7));
  }

  static DateTime nextWeek(DateTime w) {
    return w.add(Duration(days: 7));
  }

  static String nameOfMonth(DateTime w, BuildContext context) {
    String locale = Localizations.localeOf(context).languageCode;
    return DateFormat("MMMM",locale).format(w);
  }

  static double calcWidgetHeightInGrid(DateTime selectedDay, int gridHourSpan, double gridHourHeight,
      {DateTime? start, DateTime? end, int? firstWorkedMinute, int? lastWorkedMinute}) {
    if(start == null && firstWorkedMinute == null) throw new Exception("Start time not passed");
    if(end == null && lastWorkedMinute == null) throw new Exception("End time not passed");
    double hoursDurationEvent = (((lastWorkedMinute??getLastDailyWorkedMinute(end!, selectedDay)) -
        (firstWorkedMinute??getFirstDailyWorkedMinute(start!, selectedDay))) / 60);
    return hoursDurationEvent / gridHourSpan * gridHourHeight;
  }

  static int getFirstDailyWorkedMinute(DateTime start, DateTime currentDay) {
    return (start.day != currentDay.day ? Constants.MIN_WORKTIME * 60 : max<int>(
        Constants.MIN_WORKTIME * 60, start.hour * 60 + start.minute));
  }

  static int getLastDailyWorkedMinute(DateTime end, DateTime currentDay) {
    return (end.day != currentDay.day ? Constants.MAX_WORKTIME * 60 : min<int>(
        Constants.MAX_WORKTIME * 60, end.hour * 60 + end.minute));
  }
}
