import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileCacheService {
  static Directory? _cacheDir;

  static Future<void> init() async {
    final appDir = await getApplicationCacheDirectory();
    _cacheDir = Directory(p.join(appDir.path, 'kyoreader_cache'));
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
  }

  static String _cacheKey(String filePath) {
    final bytes = utf8.encode(filePath);
    return md5.convert(bytes).toString();
  }

  static Future<File?> getCachedFile(String originalPath) async {
    if (_cacheDir == null) await init();
    final key = _cacheKey(originalPath);
    final cached = File(p.join(_cacheDir!.path, key));
    if (await cached.exists()) {
      final original = File(originalPath);
      if (await original.exists()) {
        final origStat = await original.stat();
        final cacheStat = await cached.stat();
        if (cacheStat.modified.isAfter(origStat.modified)) {
          return cached;
        }
      }
    }
    return null;
  }

  static Future<File> cacheFile(String originalPath) async {
    if (_cacheDir == null) await init();
    final key = _cacheKey(originalPath);
    final dest = File(p.join(_cacheDir!.path, key));
    await File(originalPath).copy(dest.path);
    return dest;
  }

  static Future<void> clearCache() async {
    if (_cacheDir != null && await _cacheDir!.exists()) {
      await _cacheDir!.delete(recursive: true);
      await _cacheDir!.create(recursive: true);
    }
  }

  static Future<int> getCacheSize() async {
    if (_cacheDir == null) await init();
    if (!await _cacheDir!.exists()) return 0;
    int total = 0;
    await for (final entity in _cacheDir!.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}
