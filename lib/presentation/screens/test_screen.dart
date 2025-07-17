import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';
import 'result_screen.dart';
import 'package:provider/provider.dart';
import '../../internal/app_state.dart';
import '../../data/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'welcome_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class QuestionHistoryEntry {
  final Map<String, dynamic> question;
  String? selectedOption;
  QuestionHistoryEntry({required this.question, this.selectedOption});
}

class _TestScreenState extends State<TestScreen> {
  Map<String, dynamic>? currentQuestion;
  bool loading = true;
  bool error = false;
  String? errorMessage;
  String? lastToken;
  int? lastStatusCode;
  String? lastResponseBody;
  Map<String, String>? lastRequestHeaders;
  late ApiService api;
  int totalQuestions = 0;
  int currentNumber = 1;
  List<QuestionHistoryEntry> history = [];
  bool testCompleted = false;
  bool autoCompleting = false;
  
  double get progress => totalQuestions > 0 ? (currentNumber / totalQuestions * 100).clamp(0, 100) : 0;
  bool get isLastQuestion => currentNumber == totalQuestions;

  @override
  void initState() {
    super.initState();
    api = Provider.of<ApiService>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.token != null) {
      api.setToken(appState.token!);
      lastToken = appState.token!;
    }
    _tryRestoreOrInit();
  }

  Future<void> _initTest() async {
    final count = await api.getQuestionCount();
    setState(() {
      totalQuestions = count ?? 0;
      currentNumber = 1;
    });
    await loadNextQuestion();
  }

  Future<void> _saveTestState() async {
    final prefs = await SharedPreferences.getInstance();
    final appState = Provider.of<AppState>(context, listen: false);
    await prefs.setString('token', appState.token ?? '');
    await prefs.setInt('currentNumber', currentNumber);
    await prefs.setInt('totalQuestions', totalQuestions);
    final historyJson = history.map((e) => {
      'question': e.question,
      'selectedOption': e.selectedOption,
    }).toList();
    await prefs.setString('history', jsonEncode(historyJson));
  }

  Future<bool> _restoreTestState() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final savedCurrent = prefs.getInt('currentNumber');
    final savedTotal = prefs.getInt('totalQuestions');
    final historyStr = prefs.getString('history');
    if (token != null && token.isNotEmpty && savedCurrent != null && savedTotal != null && historyStr != null) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.setToken(token);
      currentNumber = savedCurrent;
      totalQuestions = savedTotal;
      final List<dynamic> histList = jsonDecode(historyStr);
      history = histList.map((e) => QuestionHistoryEntry(
        question: Map<String, dynamic>.from(e['question']),
        selectedOption: e['selectedOption'],
      )).toList();
      if (history.isNotEmpty) {
        currentQuestion = history.last.question;
      }
      setState(() {});
      return true;
    }
    return false;
  }

  Future<void> loadNextQuestion() async {
    setState(() {
      loading = true;
      error = false;
      errorMessage = null;
      lastStatusCode = null;
      lastResponseBody = null;
      lastRequestHeaders = null;
    });
    final appState = Provider.of<AppState>(context, listen: false);
    final headers = api.authHeaders();
    lastRequestHeaders = headers;
    lastToken = appState.token;
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/question/random'),
      headers: headers,
    );
    lastStatusCode = response.statusCode;
    lastResponseBody = response.body;
    if (response.statusCode == 200) {
      final question = jsonDecode(response.body);
      setState(() {
        currentQuestion = question;
        history.add(QuestionHistoryEntry(question: question));
        loading = false;
        testCompleted = false;
      });
      await _saveTestState();
    } else if (response.statusCode == 404) {
      setState(() {
        loading = false;
        testCompleted = true;
      });
    }
  }

  Future<void> sendAnswer(String option) async {
    if (currentQuestion == null) return;
    final ok = await api.sendAnswer(
      questionId: currentQuestion!['id'],
      option: option,
    );
    if (ok) {
      setState(() {
        history.last.selectedOption = option;
        currentNumber++;
      });
      await _saveTestState();
      await loadNextQuestion();
    } else {
      setState(() {
        error = true;
      });
    }
  }

  Future<void> autoCompleteTest() async {
    setState(() { autoCompleting = true; });
    try {
      while (mounted) {
        if (currentQuestion == null) break;
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/answer'),
          headers: api.authHeaders(),
          body: jsonEncode({'question': currentQuestion!['id'], 'option': 'yes'}),
        );
        if (response.statusCode == 200) {
          final next = await http.get(
            Uri.parse('${ApiService.baseUrl}/question/random'),
            headers: api.authHeaders(),
          );
          if (next.statusCode == 200) {
            final question = jsonDecode(next.body);
            setState(() {
              currentQuestion = question;
              history.add(QuestionHistoryEntry(question: question, selectedOption: 'yes'));
              currentNumber++;
            });
            await _saveTestState();
            continue;
          } else if (next.statusCode == 404) {
            break;
          } else if (next.statusCode == 403) {
            break;
          } else {
            setState(() { error = true; });
            break;
          }
        } else if (response.statusCode == 403) {
          break;
        } else {
          setState(() { error = true; });
          break;
        }
      }
    } catch (e) {
      setState(() { error = true; errorMessage = 'Ошибка автопрохождения: $e'; });
    }
    setState(() { autoCompleting = false; });
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ResultScreen()),
      );
    }
  }

  void goToPreviousQuestion() async {
    if (currentNumber <= 1 || history.length <= 1) return;
    setState(() {
      history.removeLast();
      currentNumber--;
      currentQuestion = history.last.question;
    });
    await _saveTestState();
  }

  void _resetTestState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('currentNumber');
    await prefs.remove('totalQuestions');
    await prefs.remove('history');
  }

  Future<void> _tryRestoreOrInit() async {
    final restored = await _restoreTestState();
    if (!restored) {
      await _initTest();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final containerPadding = isMobile ? 12.0 : 72.0;
    final containerVertical = isMobile ? 16.0 : 48.0;
    final fontSize = isMobile ? 16.0 : 22.0;
    final questionFontSize = isMobile ? 18.0 : 22.0;
    final buttonFontSize = isMobile ? 16.0 : 20.0;
    final buttonWidth = double.infinity;
    final maxContentWidth = isMobile ? double.infinity : 1000.0;
    final progressFontSize = isMobile ? 16.0 : 22.0;
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
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: containerPadding, vertical: containerVertical),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD5B8),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Основная карточка с вопросом и кнопками
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0), // чтобы не наезжать на кнопку назад
                            child: loading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFFF8800),
                                    ),
                                  )
                                : error
                                    ? Column(
                                        children: [
                                          Text(
                                            errorMessage ?? 'Ошибка отправки ответа. Попробуйте ещё раз.',
                                            style: TextStyle(color: Colors.red, fontSize: fontSize),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 16),
                                          if (lastToken != null) ...[
                                            Text('Текущий токен:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                                            SelectableText(lastToken!),
                                          ],
                                          if (lastStatusCode != null) ...[
                                            Text('HTTP статус: $lastStatusCode', style: TextStyle(fontSize: fontSize)),
                                          ],
                                          if (lastResponseBody != null) ...[
                                            Text('Ответ сервера:', style: TextStyle(fontSize: fontSize)),
                                            SelectableText(lastResponseBody!),
                                          ],
                                          if (lastRequestHeaders != null) ...[
                                            Text('Заголовки запроса:', style: TextStyle(fontSize: fontSize)),
                                            SelectableText(lastRequestHeaders.toString()),
                                          ],
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: loadNextQuestion,
                                            child: Text('Повторить попытку', style: TextStyle(fontSize: buttonFontSize)),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: () {
                                              final appState = Provider.of<AppState>(context, listen: false);
                                              appState.reset();
                                              _resetTestState();
                                              Navigator.of(context).pushAndRemoveUntil(
                                                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                                                (route) => false,
                                              );
                                            },
                                            child: Text('Начать заново', style: TextStyle(fontSize: buttonFontSize)),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Вопрос $currentNumber из $totalQuestions (${totalQuestions > 0 ? (currentNumber / totalQuestions * 100).clamp(0, 100).toStringAsFixed(0) : '0'}%)',
                                                  style: TextStyle(
                                                    fontSize: progressFontSize,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFFFF8800),
                                                  ),
                                                  textAlign: TextAlign.left,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            currentQuestion?['text'] ?? '',
                                            style: TextStyle(
                                              fontSize: questionFontSize,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF2D2D2D),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 32),
                                          ...['yes', 'no', 'idk'].map((option) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                                            child: SizedBox(
                                              width: buttonWidth,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFFFF954B),
                                                  foregroundColor: const Color(0xFF2D2D2D),
                                                  textStyle: TextStyle(
                                                    fontSize: buttonFontSize,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                ),
                                                onPressed: autoCompleting ? null : () => sendAnswer(option),
                                                child: Text(
                                                  option == 'yes'
                                                      ? 'Верно'
                                                      : option == 'no'
                                                      ? 'Не верно'
                                                      : 'Не знаю',
                                                ),
                                              ),
                                            ),
                                          )),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            width: buttonWidth,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.deepOrange,
                                                foregroundColor: Colors.white,
                                                textStyle: TextStyle(
                                                  fontSize: buttonFontSize,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                              ),
                                              onPressed: autoCompleting ? null : autoCompleteTest,
                                              child: autoCompleting
                                                  ? Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child: CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2,
                                                          ),
                                                        ),
                                                        SizedBox(width: 12),
                                                        Text('Автоматически пройти тест...'),
                                                      ],
                                                    )
                                                  : Text('Пройти тест автоматически'),
                                            ),
                                          ),
                                          if (testCompleted) ...[
                                            const SizedBox(height: 32),
                                            PrimaryButton(
                                              text: 'Завершить',
                                              width: buttonWidth,
                                              onPressed: () {
                                                Navigator.of(context).pushReplacement(
                                                  MaterialPageRoute(builder: (context) => const ResultScreen()),
                                                );
                                              },
                                            ),
                                          ],
                                          SizedBox(height: 28),
                                          Row(
                                            children: [
                                              if (currentNumber > 1 && !loading && !error)
                                                SizedBox(
                                                  height: 56,
                                                  width: 56,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFFFF954B),
                                                      foregroundColor: const Color(0xFF2D2D2D),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      padding: EdgeInsets.zero,
                                                    ),
                                                    onPressed: goToPreviousQuestion,
                                                    child: Center(
                                                      child: Icon(Icons.arrow_back, size: 32, color: const Color(0xFF2D2D2D)),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                          ),
                        ],
                      ),
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