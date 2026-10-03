import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

/// Choices the user makes on the phone: language and low-data mode. Kept in
/// a small JSON file so they survive restarts without signing in.
class AppSettings extends ChangeNotifier {
  AppSettings({Locale locale = const Locale('hi'), bool lowData = false})
    : _locale = locale,
      _lowData = lowData;

  /// Loads saved settings from [file]; missing or broken files give defaults.
  static Future<AppSettings> load(Future<File> Function() file) async {
    final s = AppSettings();
    s._file = file;
    try {
      final f = await file();
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        final code = j['language'];
        if (code == 'hi' || code == 'en') s._locale = Locale(code as String);
        s._lowData = j['low_data'] == true;
      }
    } on Object {
      // Unreadable settings are not worth failing for.
    }
    return s;
  }

  /// Called after the user changes language (to keep the profile in step).
  void Function(String code)? onLanguageChanged;

  Future<File> Function()? _file;
  Locale _locale;
  bool _lowData;

  Locale get locale => _locale;
  bool get lowData => _lowData;

  void setLanguage(String code) {
    if (_locale.languageCode == code) return;
    _locale = Locale(code);
    _save();
    notifyListeners();
    onLanguageChanged?.call(code);
  }

  void setLowData(bool value) {
    if (_lowData == value) return;
    _lowData = value;
    _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final file = _file;
    if (file == null) return;
    try {
      await (await file()).writeAsString(
        jsonEncode({'language': _locale.languageCode, 'low_data': _lowData}),
      );
    } on Object {
      // Not saved: the choice still applies until the app closes.
    }
  }
}

/// Makes [AppSettings] available to every screen and rebuilds dependants.
class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()?.notifier;

  static bool lowDataOf(BuildContext context) =>
      maybeOf(context)?.lowData ?? false;
}
