import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';
import '../widgets/expandable_section.dart';
import '../../data/api_service.dart';
import 'dart:async';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class _BarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final int max;
  final int min;
  final String? subtitle;
  const _BarChart({required this.data, this.max = 120, this.min = 0, this.subtitle});

  Color _barColor(int value) {
    if (value >= 71) return Colors.redAccent;
    if (value >= 30) return Colors.green;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(subtitle!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ),
        ...data.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              SizedBox(
                width: 220,
                child: Text(item['name'], style: const TextStyle(fontSize: 16)),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: ((item['value'] - min) / (max - min)).clamp(0.0, 1.0),
                      child: Container(
                        height: 22,
                        decoration: BoxDecoration(
                          color: _barColor(item['value']),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 32,
                child: Text(item['value'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class ResultScreen extends StatefulWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool loading = true;
  String? errorMessage;
  List<Map<String, dynamic>> mainScales = [];
  List<Map<String, dynamic>> otherScales = [];
  Map<String, dynamic>? uiAnalysis;
  late ApiService api;
  final GlobalKey repaintBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    api = Provider.of<ApiService>(context, listen: false);
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final resultId = await api.getResultId();
      if (resultId == null) {
        setState(() {
          errorMessage = 'Не удалось получить результат теста (id не получен).';
          loading = false;
        });
        return;
      }
      final main = await api.getMainCategoryResults(resultId);
      final other = await api.getOtherCategoryResults(resultId);
      final ui = await api.getUiAnalysisResult(resultId);
      if (main == null) {
        setState(() {
          errorMessage = 'Не удалось получить основные шкалы.';
          loading = false;
        });
        return;
      }
      setState(() {
        mainScales = main;
        otherScales = other ?? [];
        uiAnalysis = ui;
        loading = false;
      });
    } on http.ClientException catch (e) {
      setState(() {
        errorMessage = 'Ошибка сети: $e';
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка загрузки результатов: $e';
        loading = false;
      });
    }
  }

  Future<void> _saveAsPdf() async {
    try {
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Не удалось найти область для сохранения');
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      await Printing.sharePdf(
        bytes: pngBytes,
        filename: 'smil_mmpi_result.png',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final contentPadding = isMobile ? 8.0 : 48.0;
    final maxContentWidth = isMobile ? double.infinity : 1000.0;
    final titleFontSize = isMobile ? 20.0 : 28.0;
    final errorFontSize = isMobile ? 14.0 : 18.0;
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(90),
        child: AppHeader(),
      ),
      // backgroundColor не задаём, чтобы не перекрывать фон
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          // SafeArea и RepaintBoundary только для контента
          SafeArea(
            child: RepaintBoundary(
              key: repaintBoundaryKey,
              child: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: contentPadding, vertical: isMobile ? 12 : 24),
                      child: loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF8800),
                              ),
                            )
                          : errorMessage != null
                              ? Center(child: Text(errorMessage!, style: TextStyle(color: Colors.red, fontSize: errorFontSize)))
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(height: isMobile ? 8 : 16),
                                    Text(
                                      'Результаты теста СМиЛ/MMPI',
                                      style: TextStyle(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    ExpandableSection(
                                      title: 'Основные шкалы',
                                      initiallyExpanded: true,
                                      child: _BarChart(
                                        data: mainScales.map((e) => {
                                          'name': e['category_name'],
                                          'value': e['score'],
                                          'max': e['max_score'],
                                        }).toList(),
                                        max: 120,
                                        min: 0,
                                      ),
                                    ),
                                    ExpandableSection(
                                      title: 'Дополнительные шкалы',
                                      child: _BarChart(
                                        data: otherScales.map((e) => {
                                          'name': e['category_name'],
                                          'value': e['score'],
                                          'max': e['max_score'],
                                        }).toList(),
                                        max: 120,
                                        min: 0,
                                      ),
                                    ),
                                    ExpandableSection(
                                      title: 'Расчеты',
                                      child: uiAnalysis == null
                                          ? Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                                              child: Text(
                                                'Нет дополнительных расчетов.',
                                                style: TextStyle(
                                                  fontSize: isMobile ? 14.0 : 18.0,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            )
                                          : _UiAnalysisView(uiAnalysis: uiAnalysis!, isMobile: isMobile),
                                    ),
                                    const SizedBox(height: 32),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        PrimaryButton(
                                          text: 'ПОДЕЛИТЬСЯ',
                                          width: 300,
                                          onPressed: () {},
                                        ),
                                        const SizedBox(width: 32),
                                        PrimaryButton(
                                          text: 'СОХРАНИТЬ',
                                          width: 300,
                                          onPressed: _saveAsPdf,
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
          ),
        ],
      ),
    );
  }
}

class _UiAnalysisView extends StatelessWidget {
  final Map<String, dynamic> uiAnalysis;
  final bool isMobile;
  const _UiAnalysisView({required this.uiAnalysis, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];
    if (uiAnalysis.containsKey('text') && uiAnalysis['text'] != null && (uiAnalysis['text'] as String).isNotEmpty) {
      items.add(Padding(
        padding: EdgeInsets.only(bottom: isMobile ? 8 : 16),
        child: Text(
          uiAnalysis['text'],
          style: TextStyle(fontSize: isMobile ? 15 : 19, color: const Color(0xFF2D2D2D)),
        ),
      ));
    }
    uiAnalysis.forEach((key, value) {
      if (key == 'text' || value == null || (value is String && value.isEmpty)) return;
      items.add(Padding(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: isMobile ? 100 : 200,
              child: Text(
                key,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 14 : 18,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontSize: isMobile ? 14 : 18,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
            ),
          ],
        ),
      ));
    });
    if (items.isEmpty) {
      return Text(
        'Нет данных для отображения.',
        style: TextStyle(fontSize: isMobile ? 14 : 18, color: Colors.grey[700]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
    );
  }
} 