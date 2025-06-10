import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Home_page.dart';
import 'user_manager.dart';
import 'play_counter_manager.dart';
import 'dart:async';
import 'package:borneinteractive1/globals.dart';

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});

  @override
  _InscriptionPageState createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  Timer? _badgeTimer;
  bool _isBadgeChecking = false;
  bool _hasAcceptedDataCollection = false;
  String? _uidBadgeDetecte;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDataConsentDialog();
    });

    // Lancer la vérification du badge toutes les 3 secondes (exemple)
    _badgeTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      checkForBadge();
    });
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showDataConsentDialog() {
    bool localConsent = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Consentement de données'),
              content: Row(
                children: [
                  Checkbox(
                    value: localConsent,
                    onChanged: (bool? value) {
                      setState(() {
                        localConsent = value ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'J\'accepte la collecte de mes données pour améliorer le service.',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: localConsent
                      ? () {
                    setState(() {
                      _hasAcceptedDataCollection = true;
                    });
                    Navigator.of(context).pop();
                  }
                      : null,
                  child: const Text('Continuer'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  bool _isEmailValid(String email) {
    return email.contains('@') && email.endsWith('.com');
  }

  bool _isPasswordValid(String password) {
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#\$&*~]'));
    final hasMinLength = password.length >= 12;

    return hasMinLength && hasUppercase && hasSpecialChar;
  }


  Future<void> _register() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    final nom = _nomController.text.trim();
    final prenom = _prenomController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (nom.isEmpty) {
      setState(() {
        _errorMessage = 'Le nom est obligatoire';
        _isLoading = false;
      });
      return;
    }
    if (prenom.isEmpty) {
      setState(() {
        _errorMessage = 'Le prénom est obligatoire';
        _isLoading = false;
      });
      return;
    }
    if (!_isEmailValid(email)) {
      setState(() {
        _errorMessage = 'Adresse email invalide';
        _isLoading = false;
      });
      return;
    }
    if (!_isPasswordValid(password)) {
      setState(() {
        _errorMessage = 'Le mot de passe doit contenir au minimum 12 caractères';
        _isLoading = false;
      });
      return;
    }

    try {
      final url = Uri.parse('${baseUrl}/api/inscriptions');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nom_utilisateur': nom,
          'prenom_utilisateur': prenom,
          'email_utilisateur': email,
          'mdp_utilisateur': password,
          'uid_badge_utilisateur': _uidBadgeDetecte
        }),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        UserManager.setUser(User(
          email: email,
          nom: nom,
          prenom: prenom,
          id: data['id_utilisateur'],
        ));
        await PlayCounterManager.resetPlayState();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Erreur inconnue';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion au serveur';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> checkForBadge() async {
    if (_isBadgeChecking) return;
    _isBadgeChecking = true;

    try {
      final badgeUrl = Uri.parse('${baseUrl}/api/badges');
      final badgeResponse = await http.get(badgeUrl);

      if (badgeResponse.statusCode == 200) {
        final badgeData = json.decode(badgeResponse.body);
        final badgeUid = badgeData != null ? badgeData['badge']?.toString() : null;

        if (badgeUid != null && badgeUid.isNotEmpty) {
          _badgeTimer?.cancel(); // on stoppe les tentatives
          _uidBadgeDetecte = badgeUid; // stocker l'UID pour le formulaire

          final userUrl = Uri.parse('${baseUrl}/api/utilisateurs?badge_uid=$badgeUid');
          final userResponse = await http.get(userUrl);

          if (userResponse.statusCode == 200) {
            final userData = json.decode(userResponse.body);

            if (userData != null && userData['id_utilisateur'] != null) {
              UserManager.setUser(User(
                id: userData['id_utilisateur'],
                nom: userData['nom_utilisateur'] ?? '',
                prenom: userData['prenom_utilisateur'] ?? '',
                email: userData['email_utilisateur'] ?? '',
              ));

              await PlayCounterManager.resetPlayState();

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              }
              return;
            }
          }

          // Si utilisateur non trouvé (404 ou erreur API), on garde l’UID pour inscription
          // Laisser le champ à l’utilisateur visible/inscriptible
          setState(() {
            _uidBadgeDetecte = badgeUid;
          });

          // Recommencer la vérification dans 3 secondes pour un autre badge
          _badgeTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
            checkForBadge();
          });
        }
      }
    } catch (_) {
      // Ignore les erreurs réseaux pour éviter crash
    } finally {
      _isBadgeChecking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final largeurEcran = MediaQuery.of(context).size.width;
    final largeurFormulaire = largeurEcran > 600 ? 500.0 : largeurEcran * 0.9;
    final largeurBouton = largeurEcran > 600 ? 300.0 : largeurEcran * 0.6;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'PlayCiel',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Georgia',
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Si vous êtes client fidèle scannez votre badge. Sinon inscrivez vous !',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),
                SvgPicture.asset(
                  'assets/logo1.svg',
                  height: 120,
                ),
                const SizedBox(height: 30),
                Container(
                  width: largeurFormulaire,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _nomController,
                        label: 'Nom',
                        icon: Icons.person,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _prenomController,
                        label: 'Prénom',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Mot de passe',
                        icon: Icons.lock,
                        obscureText: true,
                      ),
                      if (_uidBadgeDetecte != null) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          enabled: false,
                          initialValue: _uidBadgeDetecte,
                          decoration: const InputDecoration(
                            labelText: 'Badge détecté',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: largeurBouton * 0.6,
                      child: _buildButton(
                        text: _isLoading ? 'Inscription...' : 'Inscription',
                        onPressed: _isLoading ? null : _register,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: largeurBouton * 0.6 - 12,
                      child: _buildButton(
                        text: 'Jouer',
                        onPressed: () async {
                          int count = await PlayCounterManager.getPlayCount();

                          if (count == 0) {
                            await PlayCounterManager.incrementPlayCount();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const HomePage()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Une seule partie est autorisée par jour."),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },

                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.blue.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
