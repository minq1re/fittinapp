import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'internal/app_state.dart';
import 'presentation/screens/welcome_screen.dart';
import 'data/api_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        Provider(create: (_) => ApiService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'СМИЛ/MMPI',
      theme: ThemeData(
        fontFamily: 'Gilroy',
        scaffoldBackgroundColor: const Color(0xFFFFF6ED),
      ),
      home: const WelcomeScreen(),
    );
  }
}