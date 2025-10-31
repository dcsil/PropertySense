
import 'package:flutter/material.dart';
import 'package:object_detect_test/utils/widget_keys.dart';

class HomeOwnerHomeScreen extends StatelessWidget {
  const HomeOwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: WidgetKeys.homeOwnerHomePage,
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: const Center(
        child: Text('Welcome to the Home Page!'),
      ),
    );
  }
}