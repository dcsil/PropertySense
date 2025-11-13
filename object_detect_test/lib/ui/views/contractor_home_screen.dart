
import 'package:flutter/material.dart';
import 'package:object_detect_test/utils/widget_keys.dart';

class ContractorHomeScreen extends StatelessWidget {
  const ContractorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: WidgetKeys.contractorHomePage,
      appBar: AppBar(
        title: const Text('Contractor Home Page'),
      ),
      body: const Center(
        child: Text('Welcome to the Contractor Home Page!'),
      ),
    );
  }
}