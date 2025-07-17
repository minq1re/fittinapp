import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';
import 'test_screen.dart';

class InstructionScreen extends StatelessWidget {
  const InstructionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final containerPadding = isMobile ? 12.0 : 72.0;
    final fontSize = isMobile ? 16.0 : 18.0;
    final titleFontSize = isMobile ? 22.0 : 28.0;
    final buttonWidth = isMobile ? double.infinity : 400.0;
    final maxContentWidth = isMobile ? double.infinity : 1000.0;
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(90),
        child: AppHeader(),
      ),
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
          Padding(
            padding: EdgeInsets.only(left: containerPadding, right: 0, top: isMobile ? 12 : 24, bottom: isMobile ? 12 : 24),
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Инструкция',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2D2D2D),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Вам предъявлена серия утверждений. Оценивая каждое из них, не тратьте много времени на раздумья. Наиболее естественна первая непосредственная реакция.\nВнимательно вчитывайтесь в текст, дочитывая до конца каждое утверждение и оценивая его как верное или неверное по отношению к вам. Старайтесь отвечать искренно, иначе ваши ответы будут распознаны как недостоверные и опрос придется повторить. Разбирайтесь с опросником как бы наедине с самим собой – «Какой я на самом деле?». Тогда вам будет интересна интерпретация полученных данных. Она касается лишь особенностей вашего темперамента и описывает ваши устойчивые профессионально важные качества.\n\nЕсли ваш ответ – «верно», то поставьте крестик в регистрационном листе над соответствующим опроснику номером. Если ваш ответ – «неверно», то поставьте крестик под соответствующим номером. Обращайте внимание на утверждения с двойными отрицаниями, например, «У меня никогда не было припадков с судорогами»: если не было, то ваш ответ – «верно», и, наоборот, если это с вами было, то ответ «неверно». Если некоторые утверждения вызывают большие сомнения, ориентируйтесь в вашем ответе на то, что все-таки предположительно больше свойственно вам. Если утверждение верно по отношению к вам в одних ситуациях и неверно в других, то остановитесь на том ответе, который больше подходит в настоящий момент. Только если утверждение к вам вообще не подходит, вы можете номер этого утверждения на регистрационном листе обвести кружочком. Однако избыток кружочков в регистрационном листе также приведет к недостоверности результатов.\n\nОтвечая даже на достаточно интимные вопросы, не смущайтесь, так как ваши ответы никто не станет читать и анализировать: вся обработка данных ведется автоматически. Экспериментатор не имеет доступа к конкретным ответам, получая результаты лишь в виде обобщенных показателей, которые могут оказаться интересными и полезными для вас.',
                        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w400, color: const Color(0xFF2D2D2D)),
                        textAlign: TextAlign.left,
                      ),
                      SizedBox(height: isMobile ? 16 : 32),
                      Center(
                        child: SizedBox(
                          height: 56,
                          width: buttonWidth,
                          child: PrimaryButton(
                            text: 'НАЧАТЬ ТЕСТ',
                            width: buttonWidth,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const TestScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
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