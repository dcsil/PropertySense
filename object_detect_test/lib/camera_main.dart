import 'package:flutter/material.dart';
import 'package:object_detect_test/ui/views/camera_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const seedColor = Colors.deepPurple;

  runApp(MaterialApp(
    title: 'PropertySense',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light),
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
      useMaterial3: true,
    ),
    themeMode: ThemeMode.system, // follow system dark/light
    home: CameraScreen(),
  ));
}