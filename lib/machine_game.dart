import 'dart:convert'; // Ajout pour jsonDecode
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'user_manager.dart';
import 'play_counter_manager.dart';

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
  bool leverAlreadyHandled = false; // AJOUT

  int lastParticipationId = 0; // AJOUT

  @override
  void initState() {
    super.initState();
    initLastParticipationIdAndWaitForLever();  // MODIF : nouvelle fonction d'init
  }

  Future<void> initLastParticipationIdAndWaitForLever() async {
    final user = await UserManager.getUser();
    if (user == null || user.id == null) return;

    final initResponse = await http.get(Uri.parse('http://192.168.112.120/api/wait_levier.php?id=${user.id}'));
    if (initResponse.statusCode == 200) {
      final initData = jsonDecode(initResponse.body);
      if (initData.containsKey('new_participation_id')) {
        lastParticipationId = initData['new_participation_id'];
      }
    }

    waitForLever();
  }

  void waitForLever() async {
    final user = await UserManager.getUser();
    if (user == null || user.id == null) return;

    while (mounted) {
      if (!leverAlreadyHandled) {
        final response = await http.get(Uri.parse(
            'http://192.168.112.120/api/wait_levier.php?id=${user.id}&lastId=$lastParticipationId'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['levier_actionne'] == true) {
            leverAlreadyHandled = true;
            lastParticipationId = data['new_participation_id'] ?? lastParticipationId;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous ne pouvez plus participez. Revenez demain !')),
      );
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
        while (randomIndexes[0] == randomIndexes[1] &&
            randomIndexes[1] == randomIndexes[2]) {
          randomIndexes[2] = Random().nextInt(symbols.length);
        }
      }

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

  Future<void> _enregistrerPartie(bool isWin) async {
    final user = await UserManager.getUser();
    if (user == null || user.id == null) {
      print('Utilisateur non connecté');
      return;
    }

    final int idTypeGain = isWin ? 1 : 3; // 1 = gain, 3 = perdu
    final int resultatParticipation = isWin ? 1 : 0; // 1 = gagné, 0 = perdu
    final url = Uri.parse('http://192.168.112.120/api/participation.php');

    try {
      final response = await http.post(
        url,
        body: {
          'id_utilisateur': user.id.toString(),
          'id_jeu': '2',
          'id_type_gain': idTypeGain.toString(),
          'resultat_participation': resultatParticipation.toString(),
        },
      );
      print('Réponse participation: ${response.body}');
    } catch (e) {
      print('Erreur lors de l\'enregistrement de la participation: $e');
    }
  }

  Future<void> checkWin() async {
    bool isWin = currentSymbols.every((val) => val == currentSymbols[0]);
    final playCount = await PlayCounterManager.getPlayCount();

    await _enregistrerPartie(isWin);

    if (isWin) {
      if (playCount == 0) {
        await PlayCounterManager.setPlayCountToMax();
        setState(() {
          resultText = "🎉 Vous avez gagné, revenez demain ! 🎉";
        });
      } else {
        await PlayCounterManager.incrementPlayCount();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WinScreen(),
          ),
        );
      }
    } else {
      await PlayCounterManager.incrementPlayCount();
      setState(() {
        resultText = "Vous avez perdu, retentez votre chance !";
      });
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