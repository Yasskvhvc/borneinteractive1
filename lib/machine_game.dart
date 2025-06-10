import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'user_manager.dart';
import 'play_counter_manager.dart';
import 'package:borneinteractive1/globals.dart';

class MachineGame extends StatefulWidget {
  const MachineGame({super.key});

  @override
  State<MachineGame> createState() => _MachineGameState();
}

class _MachineGameState extends State<MachineGame> {
  final List<String> symbols = ["🍒", "🍋", "🔔", "⭐", "🍉"];
  List<String> currentSymbols = ["🍒", "🍋", "🔔"];
  String resultText = "Tirez le levier pour jouer !";
  bool isSpinning = false;
  bool leverAlreadyHandled = false;

  @override
  void initState() {
    super.initState();
    waitForLever();
  }

  void waitForLever() async {
    final user = await UserManager.getUser();
    if (user == null || user.id == null) return;

    while (mounted) {
      if (!leverAlreadyHandled) {
        final response = await http.get(Uri.parse('${baseUrl}/api/leviers'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['levier'] == true) {
            leverAlreadyHandled = true;
            startGame();
          }
        }
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void startGame() {
    if (!isSpinning) {
      spinReels();
    }
  }

  Future<void> spinReels() async {
    if (isSpinning) return;

    final playCount = await PlayCounterManager.getPlayCount();
    if (playCount >= 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous ne pouvez plus participez. Revenez demain !')),
        );
      }
      return;
    }

    setState(() {
      isSpinning = true;
    });

    Future.delayed(const Duration(milliseconds: 1000), () async {
      List<int> randomIndexes = [
        Random().nextInt(symbols.length),
        Random().nextInt(symbols.length),
        Random().nextInt(symbols.length),
      ];

      if (Random().nextDouble() < 0.5) {
        while (randomIndexes[0] == randomIndexes[1] && randomIndexes[1] == randomIndexes[2]) {
          randomIndexes[2] = Random().nextInt(symbols.length);
        }
      }

      if (!mounted) return;

      setState(() {
        currentSymbols = [
          symbols[randomIndexes[0]],
          symbols[randomIndexes[1]],
          symbols[randomIndexes[2]],
        ];
        isSpinning = false;
      });

      await checkWin();
      leverAlreadyHandled = false;
    });
  }

  Future<void> sendResultToArduino(bool isWin) async {
    final ipArduino = '192.168.1.50'; // Mets ici l'IP de ton Arduino
    final url = Uri.parse('http://$ipArduino/result');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'result': isWin ? 'gain' : 'perte'}),
      );

      if (response.statusCode == 200) {
        print('Résultat envoyé à l\'Arduino: ${isWin ? 'gain' : 'perte'}');
      } else {
        print('Erreur Arduino: code ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur en envoyant le résultat à l\'Arduino: $e');
    }
  }

  Future<void> _enregistrerPartie(bool isWin) async {
    final user = await UserManager.getUser();
    if (user == null || user.id == null) {
      print('Utilisateur non connecté');
      return;
    }

    final int idTypeGain = isWin ? 1 : 3;
    final int resultatParticipation = isWin ? 1 : 0;
    final url = Uri.parse('${baseUrl}/api/participations');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_utilisateur': user.id.toString(),
          'id_jeu': '2',
          'id_type_gain': idTypeGain.toString(),
          'resultat_participation': resultatParticipation.toString(),
        }),
      );
      print('Réponse participation: ${response.body}');
    } catch (e) {
      print('Erreur lors de l\'enregistrement de la participation: $e');
    }
  }

  Future<void> checkWin() async {
    bool isWin = currentSymbols.every((val) => val == currentSymbols[0]);
    final playCount = await PlayCounterManager.getPlayCount();

    await sendResultToArduino(isWin);
    await _enregistrerPartie(isWin);

    if (isWin) {
      if (playCount == 0) {
        await PlayCounterManager.setPlayCountToMax();
        if (mounted) {
          setState(() {
            resultText = "🎉 Vous avez gagné, revenez demain ! 🎉";
          });
        }
      } else {
        await PlayCounterManager.incrementPlayCount();
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WinScreen(),
            ),
          );
        }
      }
    } else {
      await PlayCounterManager.incrementPlayCount();
      if (mounted) {
        setState(() {
          resultText = "Vous avez perdu, retentez votre chance !";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF222222),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                width: 380,
                height: 400,
                child: Stack(
                  children: [
                    Container(
                      width: 300,
                      height: 400,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCC0000),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD700),
                          width: 10,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(255, 215, 0, 0.8),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "🎰 jeu roulette 🎰",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: currentSymbols
                                  .map(
                                    (symbol) => Text(
                                  symbol,
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: Colors.black,
                                  ),
                                ),
                              )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            resultText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 50,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: spinReels,
                        child: SizedBox(
                          width: 40,
                          height: 120,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform: Matrix4.rotationZ(
                              isSpinning ? pi / 2 : 30 * pi / 180,
                            ),
                            alignment: Alignment.bottomCenter,
                            width: 10,
                            height: 100,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC0C0C0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                tooltip: 'Retour',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WinScreen extends StatelessWidget {
  const WinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E08),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "🎉 Bravo, vous avez gagné un lot ! 🎉",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Profitez de votre récompense !",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Rejouer",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
