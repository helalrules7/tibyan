import 'package:flutter/material.dart';

import 'src/ui/start_screen.dart';

void main() => runApp(const ReviewApp());

class ReviewApp extends StatelessWidget {
  const ReviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تبيان: أداة المراجعة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E5E4E),
        useMaterial3: true,
      ),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const StartScreen(),
    );
  }
}
