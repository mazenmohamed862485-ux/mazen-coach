import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'data/local/database_helper.dart';
import 'data/local/preferences_helper.dart';
import 'data/remote/gas_api_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/workout_provider.dart';
import 'presentation/providers/nutrition_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(const MazenCoachApp());
}

class MazenCoachApp extends StatelessWidget {
  const MazenCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseHelper.instance;
    final prefs = PreferencesHelper.instance;
    final api = GasApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(api: api, db: db, prefs: prefs),
        ),
        ChangeNotifierProxyProvider<AuthProvider, WorkoutProvider>(
          create: (_) => WorkoutProvider(db: db, api: api),
          update: (_, auth, workout) {
            workout?.setUser(auth.user?.uid);
            return workout ?? WorkoutProvider(db: db, api: api);
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, NutritionProvider>(
          create: (_) => NutritionProvider(db: db, api: api),
          update: (_, auth, nutrition) {
            nutrition?.setUser(
              auth.user?.uid,
              targetCalories: auth.user?.dailyCalories ?? 2000,
            );
            return nutrition ?? NutritionProvider(db: db, api: api);
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'MAZEN COACH',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeProvider.themeMode,
            locale: const Locale('ar', 'SA'),
            supportedLocales: const [
              Locale('ar', 'SA'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
