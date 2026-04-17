import 'package:flutter/material.dart';
import 'package:vuonrau/l10n/app_localizations.dart';

import 'pages/dashboard_page.dart';

void main() {
  runApp(const VuonRauApp());
}

class VuonRauApp extends StatelessWidget {
  const VuonRauApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DashboardPage(),
    );
  }
}
