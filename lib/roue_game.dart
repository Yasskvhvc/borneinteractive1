// Fichier: roue_game_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'reward_manager.dart';
import 'Home_page.dart';
import 'user_manager.dart';
import 'play_counter_manager.dart';

class RoueGamePage extends StatefulWidget {
  const RoueGamePage({super.key});

  @override
  State<RoueGamePage> createState() => _RoueGamePageState();
}

class _RoueGamePageState extends State<RoueGamePage> with SingleTickerProviderStateMixin {
  final List<String> options = [
    'Perdu',
    '20 % de réduction',
    'Perdu',
    '30 % de réduction !',
    'Perdu',
    '20 % de réduction'
  ];

  final List<Color> couleurs = [
    Color(0xFFFF6384),
    Color(0xFFFF9F40),
    Color(0xFFFF6384),
    Color(0xFFFF9F40),
    Color(0xFFFF6384),
    Color(0xFFFF9F40),
  ];

  late AnimationController _controller;
  late Animation<double> _animation;
  double _angle = 0;
  bool _enRotation = false;
  String? _resultat;
  bool _modalVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _controller.addListener(() {
      setState(() {
        _angle = _animation.value;
      });
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _enRotation = false;
        });
        _afficherResultat();
      }
    });
  }

  Future<void> _tournerRoue() async {
    if (_enRotation) return;

    final playCount = await PlayCounterManager.getPlayCount();
    if (playCount >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous avez assez joué pour aujourd\'hui. Revenez demain !')),
      );
      return;
    }

    setState(() {
      _enRotation = true;
      _modalVisible = false;
    });

    final random = Random();
    final tours = 5 + random.nextDouble() * 5;
    final angleFinal = tours * 2 * pi + random.nextDouble() * 2 * pi;

    final courbe = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _animation = Tween<double>(begin: _angle, end: _angle + angleFinal).animate(courbe);

    _controller.reset();
    _controller.forward();
  }

  int getIdTypeGain(String resultat) {
    switch (resultat) {
      case '20 % de réduction':
        return 1;
      case '30 % de réduction !':
        return 2;
      default:
        return 3;
    }
  }

  Future<void> _enregistrerPartie(String resultat) async {
    final user = await UserManager.getUser();
    if (user == null || user.id == null) {
      print('❌ Utilisateur non connecté. Requête annulée.');
      return;
    }

    final idTypeGain = getIdTypeGain(resultat);
    final resultatParticipation = (idTypeGain == 3) ? 0 : 1;
    final url = Uri.parse('http://192.168.112.120/api/participation.php');

    print("📡 Envoi de la participation :");
    print("🔹 id_utilisateur = ${user.id}");
    print("🔹 id_jeu = 1");
    print("🔹 id_type_gain = $idTypeGain");
    print("🔹 resultat_participation = $resultatParticipation");

    try {
      final response = await http.post(
        url,
        body: {
          'id_utilisateur': user.id.toString(),
          'id_jeu': '1',
          'id_type_gain': idTypeGain.toString(),
          'resultat_participation': resultatParticipation.toString(),
        },
      );

      print('✅ Réponse serveur : ${response.statusCode}');
      print('📝 Body : ${response.body}');
    } catch (e) {
      print('❌ Exception HTTP : $e');
    }
  }


  Future<void> _afficherResultat() async {
    final angleParOption = 2 * pi / options.length;
    double angleNormalise = (_angle % (2 * pi) + 2 * pi) % (2 * pi);
    int index = (angleNormalise / angleParOption).floor();
    index = (index + 1) % options.length;

    final resultat = options[index];
    setState(() {
      _resultat = resultat;
      _modalVisible = true;
    });

    RewardManager.setReward(resultat != 'Perdu');
    await _enregistrerPartie(resultat);

    final playCount = await PlayCounterManager.getPlayCount();

    if (resultat != 'Perdu') {
      if (playCount == 0) {
        await PlayCounterManager.setPlayCountToMax();
        // Affiche un snackbar avec le message "Vous avez gagné, revenez demain !"
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 Vous avez gagné, revenez demain ! 🎉')),
          );
        }
      } else {
        await PlayCounterManager.incrementPlayCount();
      }
    } else {
      await PlayCounterManager.incrementPlayCount();
    }


    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildModal() {
    if (!_modalVisible) return const SizedBox.shrink();
    final estPerdu = _resultat == 'Perdu';

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _modalVisible = false),
            child: Container(color: Colors.black54),
          ),
        ),
        Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: estPerdu
                    ? [Color(0xFFdc3545), Color(0xFFc82333)]
                    : [Color(0xFF28a745), Color(0xFF20c997)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: estPerdu
                      ? Color(0xFFdc3545).withOpacity(0.3)
                      : Color(0xFF28a745).withOpacity(0.3),
                  blurRadius: 25,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  estPerdu ? '😕 Perdu !' : '🎉 Gagné !',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  estPerdu
                      ? 'Pas de chance cette fois-ci. Retentez votre chance !'
                      : 'Félicitations ! Vous avez gagné : $_resultat',
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: () => setState(() => _modalVisible = false),
                  child: const Text('Fermer', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      backgroundColor: null,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF003C), Color(0xFF6800F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Roue des étoiles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: Offset(3, 3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 400,
                    height: 400,
                    child: CustomPaint(
                      painter: RouePainter(
                        options: options,
                        couleurs: couleurs,
                        angle: _angle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _enRotation ? null : _tournerRoue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      elevation: 8,
                      shadowColor: Colors.pinkAccent.withOpacity(0.3),
                    ),
                    child: const Text('Tourner la roue'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_modalVisible) _buildModal(),
        ],
      ),
    );
  }
}

class RouePainter extends CustomPainter {
  final List<String> options;
  final List<Color> couleurs;
  final double angle;

  RouePainter({
    required this.options,
    required this.couleurs,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rayon = min(size.width, size.height) / 2 - 10;
    final angleParOption = 2 * pi / options.length;
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.bold,
    );

    final shadowPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, rayon + 10, shadowPaint);

    for (int i = 0; i < options.length; i++) {
      final startAngle = i * angleParOption + angle;
      final paint = Paint()..color = couleurs[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: rayon),
        startAngle,
        angleParOption,
        true,
        paint,
      );

      final textAngle = startAngle + angleParOption / 2;
      final textRadius = rayon - 20;
      final textOffset = Offset(
        center.dx + textRadius * cos(textAngle),
        center.dy + textRadius * sin(textAngle),
      );

      final textSpan = TextSpan(text: options[i], style: textStyle);
      final tp = TextPainter(text: textSpan, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      tp.layout();
      canvas.save();
      canvas.translate(textOffset.dx, textOffset.dy);
      canvas.rotate(textAngle + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    final flechePaint = Paint()..color = Colors.black;
    final flechePath = Path();
    final flecheCenter = Offset(center.dx + rayon, center.dy);

    canvas.save();
    canvas.translate(flecheCenter.dx, flecheCenter.dy);
    canvas.rotate(pi / 2);
    flechePath.moveTo(-15, 0);
    flechePath.lineTo(0, 20);
    flechePath.lineTo(15, 0);
    flechePath.close();
    canvas.drawPath(flechePath, flechePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RouePainter oldDelegate) =>
      oldDelegate.angle != angle;
}
