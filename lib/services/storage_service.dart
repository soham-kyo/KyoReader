import 'package:shared_preferences/shared_preferences.dart';
import '../models/recent_file.dart';
import '../models/bookmark.dart';

class StorageService {
  static const _keyRecent = 'kyoreader_recent_files';
  static const _keyBookmarks = 'kyoreader_bookmarks';
  static const _keyDarkMode = 'kyoreader_dark_mode';
  static const _keyProUnlocked = 'kyoreader_pro_unlocked';
  static const _keyPurchaseToken = 'kyoreader_purchase_token';
  static const _maxRecent = 20;

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    if (_prefs == null) throw StateError('StorageService not initialized');
    return _prefs!;
  }

  // ─── Recent Files ──────────────────────────────────────────────────────────

  static List<RecentFile> getRecentFiles() {
    final raw = _p.getStringList(_keyRecent) ?? [];
    return raw
        .map((s) {
          try {
            return RecentFile.fromJsonString(s);
          } catch (_) {
            return null;
          }
        })
        .whereType<RecentFile>()
        .toList();
  }

  static Future<void> addRecentFile(RecentFile file) async {
    final files = getRecentFiles();
    files.removeWhere((f) => f.path == file.path);
    files.insert(0, file);
    final trimmed = files.take(_maxRecent).toList();
    await _p.setStringList(
      _keyRecent,
      trimmed.map((f) => f.toJsonString()).toList(),
    );
  }

  static Future<void> removeRecentFile(String path) async {
    final files = getRecentFiles();
    files.removeWhere((f) => f.path == path);
    await _p.setStringList(
      _keyRecent,
      files.map((f) => f.toJsonString()).toList(),
    );
  }

  static Future<void> clearRecentFiles() async {
    await _p.remove(_keyRecent);
  }

  // ─── Bookmarks ─────────────────────────────────────────────────────────────

  static List<Bookmark> getBookmarks() {
    final raw = _p.getStringList(_keyBookmarks) ?? [];
    return raw
        .map((s) {
          try {
            return Bookmark.fromJsonString(s);
          } catch (_) {
            return null;
          }
        })
        .whereType<Bookmark>()
        .toList();
  }

  static Future<void> addBookmark(Bookmark b) async {
    final list = getBookmarks();
    list.removeWhere((x) => x.fileId == b.fileId && x.page == b.page);
    list.insert(0, b);
    await _p.setStringList(
      _keyBookmarks,
      list.map((b) => b.toJsonString()).toList(),
    );
  }

  static Future<void> removeBookmark(String fileId, {int? page}) async {
    final list = getBookmarks();
    list.removeWhere((b) => b.fileId == fileId && b.page == page);
    await _p.setStringList(
      _keyBookmarks,
      list.map((b) => b.toJsonString()).toList(),
    );
  }

  static bool isBookmarked(String fileId, {int? page}) {
    return getBookmarks().any((b) => b.fileId == fileId && b.page == page);
  }

  // ─── Dark Mode ─────────────────────────────────────────────────────────────

  static bool? getDarkMode() {
    return _p.containsKey(_keyDarkMode) ? _p.getBool(_keyDarkMode) : null;
  }

  static Future<void> setDarkMode(bool value) async {
    await _p.setBool(_keyDarkMode, value);
  }

  // ─── Pro Purchase ──────────────────────────────────────────────────────────

  static bool isProUnlocked() {
    return _p.getBool(_keyProUnlocked) ?? false;
  }

  static Future<void> setProUnlocked({
    required bool value,
    String? token,
  }) async {
    await _p.setBool(_keyProUnlocked, value);
    if (token != null) {
      await _p.setString(_keyPurchaseToken, token);
    }
  }

  static String? getPurchaseToken() {
    return _p.getString(_keyPurchaseToken);
  }
}
