import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Dark navigation bar and status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppConstants.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const JRonixVpnApp());
}

class JRonixVpnApp extends StatelessWidget {
  const JRonixVpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
