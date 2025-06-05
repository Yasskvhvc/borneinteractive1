import 'package:shared_preferences/shared_preferences.dart';

class PlayCounterManager {
  static const _keyCount = 'play_count';
  static const _keyDate = 'play_date';

  /// Retourne le nombre de parties jouées aujourd'hui (tous jeux confondus)
  static Future<int> getPlayCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final lastDate = prefs.getString(_keyDate);

    // Si la date sauvegardée est aujourd'hui, retourne le compteur
    if (lastDate != null && lastDate == _dateString(today)) {
      return prefs.getInt(_keyCount) ?? 0;
    } else {
      // Sinon, réinitialise le compteur pour aujourd'hui
      await prefs.setInt(_keyCount, 0);
      await prefs.setString(_keyDate, _dateString(today));
      return 0;
    }
  }

  /// Incrémente le nombre de parties jouées aujourd'hui (tous jeux confondus)
  static Future<void> incrementPlayCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final lastDate = prefs.getString(_keyDate);

    if (lastDate != null && lastDate == _dateString(today)) {
      int count = prefs.getInt(_keyCount) ?? 0;
      await prefs.setInt(_keyCount, count + 1);
    } else {
      // Si nouvelle journée, réinitialise
      await prefs.setInt(_keyCount, 1);
      await prefs.setString(_keyDate, _dateString(today));
    }
  }

  /// Réinitialise manuellement le compteur (utile pour debug ou admin)
  static Future<void> resetPlayState() async {
    final prefs = await SharedPreferences.getInstance();
    // Supprime les données pour forcer une réinitialisation complète
    await prefs.remove(_keyCount);
    await prefs.remove(_keyDate);
  }

  /// Définit le nombre de parties à 2 pour bloquer une nouvelle tentative aujourd'hui
  static Future<void> setPlayCountToMax() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCount, 2);
    await prefs.setString(_keyDate, _dateString(DateTime.now()));
  }

  /// Supprime complètement les données de jeu pour l'utilisateur actuel
  static Future<void> clearPlayData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCount);
    await prefs.remove(_keyDate);
  }

  /// Formate la date au format YYYY-MM-DD
  static String _dateString(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
