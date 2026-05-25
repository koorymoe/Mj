import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'screens/quotation_screen.dart';

void main() => runApp(const AmaniApp());

class AmaniApp extends StatelessWidget {
  const AmaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الأماني - عروض الأسعار',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const QuotationScreen(),
    );
  }
}
