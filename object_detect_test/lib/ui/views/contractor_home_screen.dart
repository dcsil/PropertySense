
import 'package:flutter/material.dart';

class ContractorHomeScreen extends StatelessWidget {
  const ContractorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key('contractor_home_screen'),
      appBar: AppBar(
        title: const Text('Contractor Home Page'),
      ),
      body: const Center(
        child: Text('Welcome to the Contractor Home Page!'),
      ),
    );
  }
}