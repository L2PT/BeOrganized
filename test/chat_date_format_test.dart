import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:venturiautospurghi/utils/date_utils.dart' as _;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('DateUtils.formatChatDate', () {
    test('formats today as "Oggi"', () {
      final now = _.DateUtils.now();
      expect(_.DateUtils.formatChatDate(now), 'Oggi');

      // Test different hour of today
      final earlierToday = DateTime(now.year, now.month, now.day, 2, 30);
      expect(_.DateUtils.formatChatDate(earlierToday), 'Oggi');
    });

    test('formats yesterday as "Ieri"', () {
      final now = _.DateUtils.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1, 15, 45);
      expect(_.DateUtils.formatChatDate(yesterday), 'Ieri');
    });

    test('formats older dates with format "dd MMMM yyyy"', () {
      final sampleDate1 = DateTime(2026, 11, 8, 14, 20);
      expect(_.DateUtils.formatChatDate(sampleDate1), '08 Novembre 2026');

      final sampleDate2 = DateTime(2025, 1, 5, 9, 0);
      expect(_.DateUtils.formatChatDate(sampleDate2), '05 Gennaio 2025');

      final sampleDate3 = DateTime(2024, 7, 23, 22, 10);
      expect(_.DateUtils.formatChatDate(sampleDate3), '23 Luglio 2024');
    });
  });

  group('DateUtils.isSameDay', () {
    test('detects same day correctly', () {
      final d1 = DateTime(2026, 9, 7, 10, 0);
      final d2 = DateTime(2026, 9, 7, 23, 59);
      expect(_.DateUtils.isSameDay(d1, d2), isTrue);
    });

    test('detects different days correctly', () {
      final d1 = DateTime(2026, 9, 7, 10, 0);
      final d2 = DateTime(2026, 9, 6, 10, 0);
      expect(_.DateUtils.isSameDay(d1, d2), isFalse);
    });
  });
}
