import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'roue_game.dart';
import 'reward_manager.dart';
import 'user_manager.dart';
import 'play_counter_manager.dart';
import 'machine_game.dart';
import 'Accueil_concours.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const double quizRight = 240;
  static const double quizBottom = 490;
  static const double roueLeft = 120;
  static const double roueTop = 380;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  final StringBuffer _scanBuffer = StringBuffer();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
      PlayCounterManager.resetPlayState();
    }
  }

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final String key = event.logicalKey.keyLabel;
      if (key == 'Enter') {
        String scannedCode = _scanBuffer.toString().trim();
        scannedCode = scannedCode.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
        _scanBuffer.clear();

        if (scannedCode == 'ROUE') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoueGamePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Code inconnu : $scannedCode')),
          );
        }
      } else {
        _scanBuffer.write(key);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    const double roueWidth = 260;
    const double roueHeight = 320;
    const double buttonWidth = 260;
    const double buttonHeight = 54;
    const double espaceBoutonRoue = 20;

    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: _handleKey,
      child: Scaffold(
        body: Stack(
          children: [
            CustomPaint(
              size: size,
              painter: ConfettiBackgroundPainter(),
            ),
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SvgPicture.asset(
                          'assets/logo1.svg',
                          height: 100,
                        ),
                      ),
                      const Center(
                        child: Text(
                          'PlayCiel',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'CustomFont',
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 6,
                                color: Colors.black38,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white, size: 36),
                            onPressed: () {
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (context) {
                                  bool showRecompense = false;
                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                                        content: SizedBox(
                                          width: 320,
                                          child: showRecompense
                                              ? Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'Récompense reçue',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1565C0),
                                                ),
                                              ),
                                              const SizedBox(height: 32),
                                              ValueListenableBuilder<bool>(
                                                valueListenable: RewardManager.hasReward,
                                                builder: (context, hasReward, _) {
                                                  if (!hasReward) {
                                                    return const Text(
                                                      'Aucune récompense pour le moment.',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        color: Color(0xFF1565C0),
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    );
                                                  }
                                                  return Column(
                                                    children: [
                                                      const Text(
                                                        'Vous avez gagné une récompense !',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          color: Color(0xFF1565C0),
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                      const SizedBox(height: 16),
                                                      ElevatedButton.icon(
                                                        onPressed: () async {
                                                          await printLabel();
                                                        },
                                                        icon: const Icon(Icons.print),
                                                        label: const Text('Imprimer le ticket'),
                                                      ),

                                                    ],
                                                  );
                                                },
                                              ),
                                              const SizedBox(height: 32),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Fermer'),
                                              ),
                                            ],
                                          )
                                              : Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading: const Icon(Icons.card_giftcard),
                                                title: const Text('Récompense'),
                                                onTap: () {
                                                  setState(() {
                                                    showRecompense = true;
                                                  });
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(Icons.person),
                                                title: const Text('Profil'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return ValueListenableBuilder<User?>(
                                                        valueListenable: UserManager.currentUser,
                                                        builder: (context, user, _) {
                                                          return AlertDialog(
                                                            title: const Text('Profil'),
                                                            content: user == null
                                                                ? const Text('Aucune information utilisateur.')
                                                                : Column(
                                                              mainAxisSize: MainAxisSize.min,
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                if (user.nom != null && user.nom!.isNotEmpty)
                                                                  Text('Nom : \${user.nom}'),
                                                                if (user.prenom != null && user.prenom!.isNotEmpty)
                                                                  Text('Prénom : \${user.prenom}'),
                                                                Text('Email : \${user.email}'),
                                                              ],
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () => Navigator.pop(context),
                                                                child: const Text('Fermer'),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(Icons.logout),
                                                title: const Text('Déconnexion'),
                                                onTap: () async {
                                                  Navigator.pop(context);
                                                  await PlayCounterManager.resetPlayState();
                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => AccueilConcours()),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Choisis le jeu de ton choix !',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFC107),
                      fontFamily: 'CustomFont',
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 6,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
            Positioned(
              left: HomePage.roueLeft + roueWidth / 2 - buttonWidth / 2 + 29,
              top: HomePage.roueTop - buttonHeight - espaceBoutonRoue,
              child: _buildGameButton(
                context,
                'Roue des étoiles',
                Icons.star,
                    () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RoueGamePage()),
                  );
                },
                fontSize: 24,
                iconSize: 32,
                width: buttonWidth,
                height: buttonHeight,
              ),
            ),
            Positioned(
              left: HomePage.roueLeft,
              top: HomePage.roueTop,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: SvgPicture.asset(
                  'assets/roue.svg',
                  height: roueHeight,
                  width: roueWidth,
                ),
              ),
            ),
            Positioned(
              right: 140,
              bottom: 410,
              child: _buildGameButton(
                context,
                'Roulette magique',
                Icons.cloud,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MachineGame()),
                  );
                },
              ),
            ),
            Positioned(
              right: 100,
              bottom: 75,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SvgPicture.asset(
                  'assets/roulette.svg',
                  width: 320,
                  height: 320,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameButton(
      BuildContext context,
      String title,
      IconData icon,
      VoidCallback onPressed, {
        double fontSize = 24,
        double iconSize = 32,
        double? width,
        double? height,
      }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        label: Text(
          title,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1565C0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: Colors.black45,
        ),
      ),
    );
  }
}

Future<void> printLabel() async {
  const printerIp = '192.168.112.153';
  const port = 9100;

  final message = "Bravo ! Vous pouvez récupérer votre récompense !";

  final rawData = utf8.encode('$message\n\n\n\n\n');

  try {
    final socket = await Socket.connect(printerIp, port, timeout: Duration(seconds: 5));
    print("✅ Connecté à l'imprimante");

    socket.add(rawData);
    await socket.flush();
    await socket.close();

    print("✅ Étiquette imprimée !");
  } catch (e) {
    print("❌ Erreur d’impression : $e");
  }
}


class ConfettiBackgroundPainter extends CustomPainter {
  final Random _random = Random();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      colors: [const Color(0xFF1E88E5), const Color(0xFF64B5F6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    for (int i = 0; i < 150; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final radius = _random.nextDouble() * 3 + 1.5;
      final color = Colors.white.withOpacity(_random.nextDouble() * 0.6 + 0.4);
      canvas.drawCircle(Offset(x, y), radius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
