import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý tiến trình học tập người dùng lưu local
class UserProgressManager {
  static const _keyXp = 'kns_xp';
  static const _keyStreak = 'kns_streak';
  static const _keyLastActive = 'kns_last_active'; // yyyy-MM-dd
  static const _keyBookmarkedNews = 'kns_bookmarked_news';
  static const _keySavedTips = 'kns_saved_tips';
  static const _keyLikedTips = 'kns_liked_tips';
  static const _keyCompletedSkills = 'kns_completed_skills';
  static const _keyGoal = 'kns_goal';

  // ── XP ──────────────────────────────────────────────────────────────────────
  static Future<int> getXp() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keyXp) ?? 0;
  }

  static Future<void> addXp(int amount) async {
    final p = await SharedPreferences.getInstance();
    final current = p.getInt(_keyXp) ?? 0;
    await p.setInt(_keyXp, current + amount);
    await _updateStreak();
  }

  // ── Streak ───────────────────────────────────────────────────────────────────
  static Future<int> getStreak() async {
    await _checkStreakContinuity();
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keyStreak) ?? 0;
  }

  static Future<void> _updateStreak() async {
    final p = await SharedPreferences.getInstance();
    final today = _today();
    final last = p.getString(_keyLastActive) ?? '';
    if (last == today) return; // already updated today
    final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
    int streak = p.getInt(_keyStreak) ?? 0;
    if (last == yesterday) {
      streak += 1;
    } else {
      streak = 1; // reset
    }
    await p.setInt(_keyStreak, streak);
    await p.setString(_keyLastActive, today);
  }

  static Future<void> _checkStreakContinuity() async {
    final p = await SharedPreferences.getInstance();
    final last = p.getString(_keyLastActive) ?? '';
    if (last.isEmpty) return;
    final yesterday = _dateStr(DateTime.now().subtract(const Duration(days: 1)));
    final today = _today();
    // if last active is not today or yesterday, reset streak
    if (last != today && last != yesterday) {
      await p.setInt(_keyStreak, 0);
    }
  }

  static String _today() => _dateStr(DateTime.now());
  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Bookmarks (Tin tức) ───────────────────────────────────────────────────
  static Future<List<String>> getBookmarkedNewsIds() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_keyBookmarkedNews) ?? [];
  }

  static Future<bool> isNewsBookmarked(String id) async {
    final ids = await getBookmarkedNewsIds();
    return ids.contains(id);
  }

  static Future<void> toggleBookmarkNews(String id, Map<String, dynamic> item) async {
    final p = await SharedPreferences.getInstance();
    final ids = p.getStringList(_keyBookmarkedNews) ?? [];
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    await p.setStringList(_keyBookmarkedNews, ids);
  }

  // ── Saved Tips (Mẹo vặt) ──────────────────────────────────────────────────
  static Future<List<String>> getSavedTipIds() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_keySavedTips) ?? [];
  }

  static Future<bool> isTipSaved(String id) async {
    final ids = await getSavedTipIds();
    return ids.contains(id);
  }

  static Future<void> toggleSaveTip(String id) async {
    final p = await SharedPreferences.getInstance();
    final ids = p.getStringList(_keySavedTips) ?? [];
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
      await addXp(1); // +1 XP khi lưu mẹo
    }
    await p.setStringList(_keySavedTips, ids);
  }

  // ── Liked Tips ────────────────────────────────────────────────────────────
  static Future<List<String>> getLikedTipIds() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_keyLikedTips) ?? [];
  }

  static Future<bool> isTipLiked(String id) async {
    final ids = await getLikedTipIds();
    return ids.contains(id);
  }

  static Future<void> toggleLikeTip(String id) async {
    final p = await SharedPreferences.getInstance();
    final ids = p.getStringList(_keyLikedTips) ?? [];
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
      await addXp(1); // +1 XP
    }
    await p.setStringList(_keyLikedTips, ids);
  }

  // ── Completed Skills ──────────────────────────────────────────────────────
  static Future<List<String>> getCompletedSkillIds() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_keyCompletedSkills) ?? [];
  }

  static Future<void> markSkillCompleted(String id) async {
    final p = await SharedPreferences.getInstance();
    final ids = p.getStringList(_keyCompletedSkills) ?? [];
    if (!ids.contains(id)) {
      ids.add(id);
      await p.setStringList(_keyCompletedSkills, ids);
      await addXp(5); // +5 XP khi hoàn thành kỹ năng
    }
  }

  static Future<bool> isSkillCompleted(String id) async {
    final ids = await getCompletedSkillIds();
    return ids.contains(id);
  }

  // ── Goal ──────────────────────────────────────────────────────────────────
  static Future<String> getGoal() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyGoal) ?? '';
  }

  static Future<void> setGoal(String goal) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyGoal, goal);
  }

  // ── Summary ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getSummary() async {
    final xp = await getXp();
    final streak = await getStreak();
    final completed = await getCompletedSkillIds();
    final saved = await getSavedTipIds();
    final bookmarks = await getBookmarkedNewsIds();
    return {
      'xp': xp,
      'streak': streak,
      'completedSkills': completed.length,
      'savedTips': saved.length,
      'bookmarkedNews': bookmarks.length,
      'level': _levelFromXp(xp),
      'levelLabel': _levelLabel(xp),
    };
  }

  static int _levelFromXp(int xp) {
    if (xp < 20) return 1;
    if (xp < 50) return 2;
    if (xp < 100) return 3;
    if (xp < 200) return 4;
    return 5;
  }

  static String _levelLabel(int xp) {
    if (xp < 20) return 'Người mới';
    if (xp < 50) return 'Học viên';
    if (xp < 100) return 'Tiến bộ';
    if (xp < 200) return 'Xuất sắc';
    return 'Bậc thầy';
  }
}
