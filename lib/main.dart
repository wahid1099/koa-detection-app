import 'dart:io';
import 'package:flutter/material.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/history_screen.dart';
import 'presentation/screens/history_detail_screen.dart';
import 'presentation/screens/image_selection_screen.dart';
import 'presentation/screens/classification_screen.dart';
import 'presentation/screens/settings_screen.dart';

void main() {
  runApp(const KOADetectionApp());
}

class KOADetectionApp extends StatelessWidget {
  const KOADetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KOA Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/history': (context) => const HistoryScreen(),
        '/image-selection': (context) => const ImageSelectionScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/history-detail') {
          final entryId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => HistoryDetailScreen(entryId: entryId),
          );
        }
        if (settings.name == '/classification') {
          final imageFile = settings.arguments as File?;
          if (imageFile != null) {
            return MaterialPageRoute(
              builder: (context) => ClassificationScreen(imageFile: imageFile),
            );
          }
        }
        return null;
      },
    );
  }
}
