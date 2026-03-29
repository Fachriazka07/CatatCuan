import 'package:catatcuan_mobile/core/services/push_notification_service.dart';
import 'package:catatcuan_mobile/core/services/settings_preferences_service.dart';
import 'package:catatcuan_mobile/core/theme/app_theme.dart';
import 'package:catatcuan_mobile/core/utils/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _isLoading = true;
  bool _dueDateReminder = true;
  bool _lowStockAlert = true;
  bool _dailyReminder = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsPreferencesService.getNotificationSettings();
    if (!mounted) return;

    setState(() {
      _dueDateReminder =
          settings[SettingsPreferencesService.dueDateReminderKey] ?? true;
      _lowStockAlert =
          settings[SettingsPreferencesService.lowStockAlertKey] ?? true;
      _dailyReminder =
          settings[SettingsPreferencesService.dailyReminderKey] ?? false;
      _isLoading = false;
    });
  }

  Future<void> _updateSetting({
    required String key,
    required bool value,
    required void Function(bool value) updateState,
  }) async {
    setState(() => updateState(value));
    await SettingsPreferencesService.setNotificationSetting(key, value);
    await PushNotificationService.instance.syncPreferencesForCurrentUser();
  }

  void _showSavedInfo() {
    AppToast.showSuccess(
      context,
      'Preferensi notifikasi sudah diperbarui',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Atur pengingat yang ingin kamu tampilkan di aplikasi. Pengaturan ini bisa diubah kapan saja.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildToggleCard(
                    title: 'Pengingat Hutang Jatuh Tempo',
                    subtitle: 'Ingatkan jika ada piutang kasbon yang mendekati jatuh tempo.',
                    value: _dueDateReminder,
                    onChanged: (value) async {
                      await _updateSetting(
                        key: SettingsPreferencesService.dueDateReminderKey,
                        value: value,
                        updateState: (newValue) =>
                            _dueDateReminder = newValue,
                      );
                      if (!mounted) return;
                      _showSavedInfo();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildToggleCard(
                    title: 'Alert Stok Menipis',
                    subtitle: 'Tampilkan peringatan saat stok produk hampir habis atau sudah habis.',
                    value: _lowStockAlert,
                    onChanged: (value) async {
                      await _updateSetting(
                        key: SettingsPreferencesService.lowStockAlertKey,
                        value: value,
                        updateState: (newValue) => _lowStockAlert = newValue,
                      );
                      if (!mounted) return;
                      _showSavedInfo();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildToggleCard(
                    title: 'Pengingat Catat Hari Ini',
                    subtitle: 'Ingatkan untuk mengecek pencatatan penjualan atau pengeluaran hari ini.',
                    value: _dailyReminder,
                    onChanged: (value) async {
                      await _updateSetting(
                        key: SettingsPreferencesService.dailyReminderKey,
                        value: value,
                        updateState: (newValue) => _dailyReminder = newValue,
                      );
                      if (!mounted) return;
                      _showSavedInfo();
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1EDD8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.5,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppTheme.primary,
            inactiveThumbColor: const Color(0xFFF87171),
            inactiveTrackColor: Colors.transparent,
            trackOutlineColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.transparent;
              }
              return const Color(0xFFFCA5A5);
            }),
            trackOutlineWidth: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return 0;
              }
              return 1.6;
            }),
          ),
        ],
      ),
    );
  }
}
