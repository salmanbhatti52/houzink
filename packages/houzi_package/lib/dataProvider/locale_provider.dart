import 'package:flutter/material.dart';
import 'package:houzi_package/files/generic_methods/utility_methods.dart';
import 'package:houzi_package/files/hive_storage_files/hive_storage_manager.dart';
import 'package:houzi_package/l10n/l10n.dart';
typedef DefaultLanguageCodeHook = String Function();
class LocaleProvider extends ChangeNotifier {

  Locale? _locale;
  Locale? get locale => _locale;

  static LocaleProvider? _localeProvider;

  factory LocaleProvider() {
    _localeProvider ??= LocaleProvider._internal();
    return _localeProvider!;
  }

  LocaleProvider._internal(){
    DefaultLanguageCodeHook defaultLanguageCodeHook = UtilityMethods.defaultLanguageCode;
    String defaultLanguage = defaultLanguageCodeHook();

    String localeFromStorage = HiveStorageManager.readLanguageSelection() ?? defaultLanguage;
    _locale = Locale(localeFromStorage);
    notifyListeners();
  }

  void setLocale(Locale locale) {
    if (!L10n.getAllLanguagesLocale().contains(locale)) return;
    _locale = locale;
    HiveStorageManager.storeLanguageSelection(locale: _locale!);
    notifyListeners();
  }
}
