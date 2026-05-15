import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dockge_app/src/core/domain/domain.dart';
import 'package:dockge_app/src/core/storage/storage.dart';

final localeOverrideProvider =
    NotifierProvider<LocaleOverrideController, Locale?>(
      LocaleOverrideController.new,
    );

class LocaleOverrideController extends Notifier<Locale?> {
  bool _loaded = false;

  @override
  Locale? build() {
    if (!_loaded) {
      _loaded = true;
      _load();
    }
    return null;
  }

  void followSystem() {
    state = null;
    _write(LanguagePreference.system);
  }

  void setLocale(Locale locale) {
    state = locale;
    _write(
      locale.languageCode == 'zh'
          ? LanguagePreference.zhHans
          : LanguagePreference.en,
    );
  }

  Future<void> _load() async {
    final preference = await _read();
    state = switch (preference) {
      LanguagePreference.en => const Locale('en'),
      LanguagePreference.zhHans ||
      LanguagePreference.zhHant => const Locale('zh'),
      LanguagePreference.system => null,
    };
  }

  Future<LanguagePreference> _read() async {
    try {
      return await DockgeLanguageStorage(DockgeSecureStorage()).read();
    } catch (_) {
      return LanguagePreference.system;
    }
  }

  Future<void> _write(LanguagePreference language) async {
    try {
      await DockgeLanguageStorage(DockgeSecureStorage()).write(language);
    } catch (_) {
      // Some test environments do not install the shared_preferences platform.
    }
  }
}
