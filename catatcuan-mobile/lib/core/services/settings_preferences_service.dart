import 'package:catatcuan_mobile/core/services/stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppDefaultPeriod { harian, mingguan, bulanan, triwulanan }

class SettingsPreferencesService {
  SettingsPreferencesService._();

  static const String _keyDefaultPeriod = 'default_period';
  static const String _keyDueDateReminder = 'notif_due_date_reminder';
  static const String _keyLowStockAlert = 'notif_low_stock_alert';
  static const String _keyDailyReminder = 'notif_daily_reminder';

  static const Map<String, bool> _defaultNotificationSettings = {
    _keyDueDateReminder: true,
    _keyLowStockAlert: true,
    _keyDailyReminder: false,
  };

  static String get defaultPeriodKey => AppDefaultPeriod.bulanan.name;

  static Future<AppDefaultPeriod> getDefaultPeriod() async {
    final prefs = await SharedPreferences.getInstance();
    final rawValue = prefs.getString(_keyDefaultPeriod) ?? defaultPeriodKey;

    return AppDefaultPeriod.values.firstWhere(
      (period) => period.name == rawValue,
      orElse: () => AppDefaultPeriod.bulanan,
    );
  }

  static Future<void> setDefaultPeriod(AppDefaultPeriod period) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultPeriod, period.name);
  }

  static String getLabel(AppDefaultPeriod period) {
    switch (period) {
      case AppDefaultPeriod.harian:
        return 'Harian';
      case AppDefaultPeriod.mingguan:
        return 'Mingguan';
      case AppDefaultPeriod.bulanan:
        return 'Bulanan';
      case AppDefaultPeriod.triwulanan:
        return 'Triwulanan';
    }
  }

  static String getLaporanKey(AppDefaultPeriod period) {
    switch (period) {
      case AppDefaultPeriod.harian:
        return 'hari_ini';
      case AppDefaultPeriod.mingguan:
        return 'minggu_ini';
      case AppDefaultPeriod.bulanan:
        return 'bulan_ini';
      case AppDefaultPeriod.triwulanan:
        return 'triwulan_ini';
    }
  }

  static String getLaporanLabel(AppDefaultPeriod period) {
    switch (period) {
      case AppDefaultPeriod.harian:
        return 'Hari ini';
      case AppDefaultPeriod.mingguan:
        return 'Minggu ini';
      case AppDefaultPeriod.bulanan:
        return 'Bulan ini';
      case AppDefaultPeriod.triwulanan:
        return 'Triwulan ini';
    }
  }

  static StatsPeriod getStatsPeriod(AppDefaultPeriod period) {
    switch (period) {
      case AppDefaultPeriod.harian:
        return StatsPeriod.harian;
      case AppDefaultPeriod.mingguan:
        return StatsPeriod.mingguan;
      case AppDefaultPeriod.bulanan:
        return StatsPeriod.bulanan;
      case AppDefaultPeriod.triwulanan:
        return StatsPeriod.triwulanan;
    }
  }

  static Future<Map<String, bool>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      _keyDueDateReminder:
          prefs.getBool(_keyDueDateReminder) ??
          _defaultNotificationSettings[_keyDueDateReminder]!,
      _keyLowStockAlert:
          prefs.getBool(_keyLowStockAlert) ??
          _defaultNotificationSettings[_keyLowStockAlert]!,
      _keyDailyReminder:
          prefs.getBool(_keyDailyReminder) ??
          _defaultNotificationSettings[_keyDailyReminder]!,
    };
  }

  static Future<void> setNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static String get dueDateReminderKey => _keyDueDateReminder;
  static String get lowStockAlertKey => _keyLowStockAlert;
  static String get dailyReminderKey => _keyDailyReminder;
}
