import 'package:flutter/material.dart';

class RecompensePage extends StatelessWidget {
  const RecompensePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Récompense reçue'),
        backgroundColor: const Color(0xFF1565C0),
        centerTitle: true,
        elevation: 2,
      ),
      body: const Center(
        child: Text(
          'Voici votre récompense !',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}