import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class L10n {
  static const supportedLocales = <Locale>[
    Locale('en'),
  ];

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];
}
