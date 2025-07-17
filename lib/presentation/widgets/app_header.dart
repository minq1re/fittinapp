import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final logoHeight = isMobile ? 48.0 : width < 1000 ? 80.0 : 120.0;
    final fontSize = isMobile ? 18.0 : width < 1000 ? 32.0 : 48.0;
    
    return Container(
      color: const Color(0xFF333333),
      padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 8, horizontal: isMobile ? 8 : 24),
      child: Row(
        children: [
          Image.asset('assets/images/fittin.png', height: logoHeight),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Стандартизированный метод исследования личности',
              style: TextStyle(
                fontFamily: 'Gilroy',
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
} 