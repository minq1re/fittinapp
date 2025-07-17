import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double? width;
  final IconData? icon;

  const PrimaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.width,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 200,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8800),
          foregroundColor: const Color(0xFF2D2D2D),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: icon != null
            ? Icon(icon, size: 28, color: const Color(0xFF2D2D2D))
            : Text(text),
      ),
    );
  }
} 