import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';

class Translator {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  Translator(this.locale);

  Future<void> load() async {
    String jsonString = await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
  }

  String get(String key) {
    return _localizedStrings[key] ?? key;
  }
} 