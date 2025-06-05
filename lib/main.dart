import 'package:flutter/material.dart';
import 'package:borneinteractive1/inscription_page.dart'; // Remplace par le bon chemin vers ta page

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AccueilConcours(),
      routes: {
        '/inscription': (context) => const InscriptionPage(), // Ta vraie page ici
      },
    );
  }
}

class AccueilConcours extends StatelessWidget {
  const AccueilConcours({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: 50, left: 30, child: Icon(Icons.circle, color: Colors.white24, size: 20)),
            Positioned(top: 150, right: 50, child: Icon(Icons.star, color: Colors.white24, size: 25)),
            Positioned(bottom: 80, left: 60, child: Icon(Icons.square, color: Colors.white24, size: 18)),
            Positioned(bottom: 120, right: 40, child: Icon(Icons.circle_outlined, color: Colors.white24, size: 22)),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'JEU CONCOURS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'VIENS TENTER TA CHANCE POUR GAGNER\nUN DE NOS NOMBREUX LOTS !',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/inscription');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('JOUER'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
