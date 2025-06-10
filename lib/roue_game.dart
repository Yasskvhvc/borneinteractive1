import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'reward_manager.dart';
import 'Home_page.dart';
import 'user_manager.dart';
import 'dart:convert';
import 'play_counter_manager.dart';
import 'package:borneinteractive1/globals.dart';

class RoueGamePage extends StatefulWidget {
  const RoueGamePage({super.key});

  @override
  State<RoueGamePage> createState() => _RoueGamePageState();
}

class _RoueGamePageState extends State<RoueGamePage> with SingleTickerProviderStateMixin {
  bool _jetonRequisVisible = false;
  bool _jetonPresent = false;

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

    _verifierJeton();
  }

  Future<void> _verifierJeton() async {
    if (_jetonPresent) {
      print("Jeton déjà présent, pas besoin de vérifier.");
      return;
    }

    try {
      final response = await http.get(Uri.parse('${baseUrl}/api/jetons'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final jetonPresent = jsonData['jeton'] == true;
        setState(() {
          _jetonPresent = jetonPresent;
          _jetonRequisVisible = !jetonPresent;
        });
      } else {
        print('❌ Erreur lors de la vérification du jeton');
        setState(() {
          _jetonRequisVisible = true;
          _jetonPresent = false;
        });
      }
    } catch (e) {
      print('❌ Exception lors de la vérification du jeton : $e');
      setState(() {
        _jetonRequisVisible = true;
        _jetonPresent = false;
      });
    }
  }

  Future<void> _tournerRoue() async {
    if (_enRotation) return;

    final playCount = await PlayCounterManager.getPlayCount();
    if (playCount >= 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous avez assez joué pour aujourd\'hui. Revenez demain !')),
        );
      }
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
    final url = Uri.parse('${baseUrl}/api/participations');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_utilisateur': user.id.toString(),
          'id_jeu': '1',
          'id_type_gain': idTypeGain.toString(),
          'resultat_participation': resultatParticipation.toString(),
        }),
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

    // Correction: on inverse la logique pour trouver l'index correct (la roue tourne dans le sens horaire)
    int index = (options.length - (angleNormalise / angleParOption).floor() - 1) % options.length;

    final resultat = options[index];
    print("Résultat de la roue : '$resultat'");

    setState(() {
      _resultat = resultat;
      _modalVisible = true;
    });

    RewardManager.setReward(resultat.toLowerCase().trim() != 'perdu');
    await _enregistrerPartie(resultat);

    final playCount = await PlayCounterManager.getPlayCount();

    if (resultat.toLowerCase().trim() != 'perdu') {
      if (playCount == 0) {
        await PlayCounterManager.setPlayCountToMax();
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

    final estPerdu = (_resultat?.toLowerCase().trim() == 'perdu');

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

  Widget _buildJetonModal() {
    if (!_jetonRequisVisible) return const SizedBox.shrink();

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black54,
          ),
        ),
        Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.vpn_key, size: 48, color: Colors.pink),
                const SizedBox(height: 16),
                const Text(
                  'Jeton requis',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Veuillez insérer un jeton pour jouer à la roue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _verifierJeton();
                  },
                  child: const Text('Réessayer'),
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D324D),
                  Color(0xFF7F5A83),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      height: 300,
                      child: Transform.rotate(
                        angle: _angle,
                        child: CustomPaint(
                          painter: RouePainter(options: options, couleurs: couleurs),
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 0,
                      child: Icon(Icons.arrow_drop_down_circle, size: 48, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: (_jetonPresent && !_enRotation) ? _tournerRoue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_jetonPresent && !_enRotation) ? Colors.pink : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  ),
                  child: const Text('Jouer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          _buildModal(),
          _buildJetonModal(),
        ],
      ),
    );
  }
}

class RouePainter extends CustomPainter {
  final List<String> options;
  final List<Color> couleurs;

  RouePainter({required this.options, required this.couleurs});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final rayon = size.width / 2;

    final paint = Paint()..style = PaintingStyle.fill;
    final textPainter = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr);

    final angleParOption = 2 * pi / options.length;

    for (int i = 0; i < options.length; i++) {
      final debutAngle = i * angleParOption;
      paint.color = couleurs[i];

      canvas.drawArc(Rect.fromCircle(center: centre, radius: rayon), debutAngle, angleParOption, true, paint);

      final textAngle = debutAngle + angleParOption / 2;

      canvas.save();
      canvas.translate(centre.dx, centre.dy);
      canvas.rotate(textAngle);

      final texte = options[i];
      final style = TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      );

      textPainter.text = TextSpan(text: texte, style: style);
      textPainter.layout(maxWidth: rayon * 0.8);
      canvas.translate(rayon * 0.6, -textPainter.height / 2);
      textPainter.paint(canvas, Offset(0, 0));

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
