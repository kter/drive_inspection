import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

/// Settings screen providing access to app configuration.
///
/// Currently includes theme settings with Light/Dark/Auto options,
/// with room for future configuration options like units, calibration,
/// data management, etc.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '戻る',
        ),
      ),
      body: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return ListView(
            children: [
              // Theme settings section header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'テーマ設定',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

              // Light theme option
              RadioListTile<ThemeMode>(
                title: const Text('ライトモード'),
                subtitle: const Text('常に明るいテーマを使用'),
                value: ThemeMode.light,
                groupValue: themeService.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeService.setThemeMode(value);
                  }
                },
                secondary: Icon(
                  Icons.wb_sunny,
                  color: themeService.themeMode == ThemeMode.light
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              ),

              // Dark theme option
              RadioListTile<ThemeMode>(
                title: const Text('ダークモード'),
                subtitle: const Text('常に暗いテーマを使用'),
                value: ThemeMode.dark,
                groupValue: themeService.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeService.setThemeMode(value);
                  }
                },
                secondary: Icon(
                  Icons.nightlight_round,
                  color: themeService.themeMode == ThemeMode.dark
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              ),

              // Auto (Follow System) theme option
              RadioListTile<ThemeMode>(
                title: const Text('自動（システムに従う）'),
                subtitle: const Text('デバイスの設定に合わせてテーマを切り替え'),
                value: ThemeMode.system,
                groupValue: themeService.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeService.setThemeMode(value);
                  }
                },
                secondary: Icon(
                  Icons.brightness_auto,
                  color: themeService.themeMode == ThemeMode.system
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              ),

              const Divider(),

              // Future settings sections placeholder
              ListTile(
                leading: Icon(Icons.info_outline,
                    color: Theme.of(context).colorScheme.outline),
                title: Text(
                  'その他の設定は今後追加予定',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                enabled: false,
              ),
            ],
          );
        },
      ),
    );
  }
}
