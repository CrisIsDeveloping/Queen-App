import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class DailyStreakResult {
  final bool isNewStreak;
  final int coinsEarned;
  final int newStreakCount;
  final int newLevel;

  DailyStreakResult({
    required this.isNewStreak,
    required this.coinsEarned,
    required this.newStreakCount,
    required this.newLevel,
  });
}

class GamificationService {
  final SupabaseClient _supabaseClient;

  GamificationService(this._supabaseClient);

  /// Niveles basados en la experiencia (monedas totales)
  int _calculateLevel(int totalCoins) {
    if (totalCoins < 50) return 1;
    if (totalCoins < 150) return 2;
    return 3;
  }

  /// Chequea la racha diaria.
  /// - Si last_login == null → Primer login: racha = 1, +5 monedas, SIEMPRE muestra recompensa.
  /// - 24h–48h → Racha + 1, +5 monedas.
  /// - > 48h → Racha reinicia a 1, +5 monedas.
  /// - < 24h → null (ya reclamó hoy).
  Future<DailyStreakResult?> checkDailyLogin(String userId) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select('last_login, streak_count, coins, level')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      final lastLoginStr = response['last_login'] as String?;
      final streakCount = response['streak_count'] as int? ?? 0;
      final coins = response['coins'] as int? ?? 0;
      const int coinsToAward = 5;

      final now = DateTime.now();

      int newStreakCount = streakCount;
      int newCoins = coins;
      bool isNewStreak = false;

      if (lastLoginStr == null) {
        // PRIMER login — siempre recompensa
        isNewStreak = true;
        newStreakCount = 1;
        newCoins = coins + coinsToAward;
      } else {
        final lastLogin = DateTime.parse(lastLoginStr).toLocal();
        final differenceHours = now.difference(lastLogin).inHours;

        if (differenceHours >= 24 && differenceHours <= 48) {
          // Racha mantenida
          isNewStreak = true;
          newStreakCount = streakCount + 1;
          newCoins = coins + coinsToAward;
        } else if (differenceHours > 48) {
          // Racha perdida, reinicia
          isNewStreak = true;
          newStreakCount = 1;
          newCoins = coins + coinsToAward;
        }
        // < 24h → ya reclamó, no hacemos nada más que actualizar last_login
      }

      final newLevel = _calculateLevel(newCoins);

      // Actualizar DB (siempre actualizamos last_login, sólo actualizamos racha/monedas si hay premio)
      await _supabaseClient.from('profiles').update({
        'last_login': now.toUtc().toIso8601String(),
        if (isNewStreak) 'streak_count': newStreakCount,
        if (isNewStreak) 'coins': newCoins,
        if (isNewStreak) 'level': newLevel,
      }).eq('user_id', userId);

      if (isNewStreak) {
        return DailyStreakResult(
          isNewStreak: true,
          coinsEarned: coinsToAward,
          newStreakCount: newStreakCount,
          newLevel: newLevel,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error en GamificationService checkDailyLogin: $e');
      return null;
    }
  }

  /// Añade monedas por compras y recalcula el nivel
  Future<void> addCoinsAndCheckLevel(String userId, int coinsEarned) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select('coins')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return;

      final currentCoins = response['coins'] as int? ?? 0;
      final newCoins = currentCoins + coinsEarned;
      final newLevel = _calculateLevel(newCoins);

      await _supabaseClient.from('profiles').update({
        'coins': newCoins,
        'level': newLevel,
      }).eq('user_id', userId);
    } catch (e) {
      debugPrint('Error en GamificationService addCoins: $e');
    }
  }
}
