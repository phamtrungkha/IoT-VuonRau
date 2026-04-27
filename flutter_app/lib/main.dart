import 'package:flutter/material.dart';
import 'package:vuonrau/l10n/app_localizations.dart';

import 'app/app_config.dart';
import 'pages/dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
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
