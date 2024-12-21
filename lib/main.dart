import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rei_da_tapioca/controllers/navigation/navigation_controller.dart';
import 'package:rei_da_tapioca/screens/home/home_screen.dart';
import 'package:rei_da_tapioca/screens/login/login_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rei_da_tapioca/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('pt_BR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery.sizeOf(context).width;
    return MaterialApp(
      title: 'Rei da Tapioca',
      supportedLocales: [
        const Locale('pt', 'BR'),
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppConstants.appPrimaryColor),
        useMaterial3: true,
      ),
      home: LoginScreen(),
    );
  }
}

