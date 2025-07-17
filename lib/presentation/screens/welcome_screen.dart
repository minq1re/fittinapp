import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';
import 'instruction_screen.dart';
import '../../internal/app_state.dart';
import '../../data/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    Future<void> handleGender(bool isMale) async {
      // Сбросить состояние теста перед началом нового
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('currentNumber');
      await prefs.remove('totalQuestions');
      await prefs.remove('history');
      final token = await api.createTestTaker(isMale: isMale);
      if (token != null) {
        appState.setGender(isMale);
        appState.setToken(token);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const InstructionScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка соединения с сервером')),
        );
      }
    }
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final maxContentWidth = isMobile ? double.infinity : 1200.0;
    final containerPadding = isMobile ? 12.0 : 24.0;
    final fontSize = isMobile ? 18.0 : 32.0;
    final descFontSize = isMobile ? 14.0 : 24.0;
    final buttonWidth = isMobile ? double.infinity : 320.0;
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(90),
        child: AppHeader(),
      ),
      backgroundColor: const Color(0xFFFFF6ED),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/start.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: containerPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: isMobile ? 16 : 32),
                        Text(
                          'Тест СМиЛ/MMPI',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D2D2D),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isMobile ? 8 : 16),
                        Text(
                          'Стандартизированный метод исследования личности(СМИЛ) – адаптация теста MMPI, сделанная Людмилой Николаевной Собчик. В отличие от оригинальной версии, СМИЛ не имеет клинической направленности и основывается на индивидуально-типологическом подходе автора.',
                          style: TextStyle(
                            fontSize: descFontSize,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF2D2D2D),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isMobile ? 24 : 48),
                        isMobile
                            ? Column(
                                children: [
                                  PrimaryButton(
                                    text: 'ТЕСТ ДЛЯ МУЖЧИН',
                                    width: buttonWidth,
                                    onPressed: () {
                                      handleGender(true);
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  PrimaryButton(
                                    text: 'ТЕСТ ДЛЯ ЖЕНЩИН',
                                    width: buttonWidth,
                                    onPressed: () {
                                      handleGender(false);
                                    },
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  PrimaryButton(
                                    text: 'ТЕСТ ДЛЯ МУЖЧИН',
                                    width: buttonWidth,
                                    onPressed: () {
                                      handleGender(true);
                                    },
                                  ),
                                  const SizedBox(width: 32),
                                  PrimaryButton(
                                    text: 'ТЕСТ ДЛЯ ЖЕНЩИН',
                                    width: buttonWidth,
                                    onPressed: () {
                                      handleGender(false);
                                    },
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 