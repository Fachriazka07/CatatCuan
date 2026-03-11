import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import '../theme/app_theme.dart';

class AppToast {
  static void showSuccess(BuildContext context, String message, {String? title}) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      title: title != null ? Text(title) : const Text('Berhasil'),
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
      primaryColor: AppTheme.primary,
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.textPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: BorderRadius.circular(12),

      showProgressBar: false,
    );
  }

  static void showError(BuildContext context, String message, {String? title}) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      title: title != null ? Text(title) : const Text('Gagal'),
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      primaryColor: AppTheme.error,
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.textPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: BorderRadius.circular(12),

      showProgressBar: false,
    );
  }

  static void showWarning(BuildContext context, String message, {String? title}) {
    toastification.show(
      context: context,
      type: ToastificationType.warning,
      style: ToastificationStyle.flatColored,
      title: title != null ? Text(title) : const Text('Peringatan'),
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      primaryColor: AppTheme.secondary,
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.textPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: BorderRadius.circular(12),

      showProgressBar: false,
    );
  }

  static void showInfo(BuildContext context, String message, {String? title}) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      title: title != null ? Text(title) : const Text('Info'),
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
      primaryColor: Colors.blue,
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.textPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: BorderRadius.circular(12),

      showProgressBar: false,
    );
  }
}
