import 'package:flutter/foundation.dart';
import '../models/recent_file.dart';
import '../models/bookmark.dart';
import '../services/storage_service.dart';
import '../services/purchase_service.dart';

class AppProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isProUnlocked = false;
  bool _isPurchasing = false;
  bool _isLoaded = false;
  List<RecentFile> _recentFiles = [];
  List<Bookmark> _bookmarks = [];

  bool get isDarkMode => _isDarkMode;
  bool get isProUnlocked => _isProUnlocked;
  bool get isPurchasing => _isPurchasing;
  bool get isLoaded => _isLoaded;
  List<RecentFile> get recentFiles => List.unmodifiable(_recentFiles);
  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  Future<void> init() async {
    await StorageService.init();
    await PurchaseService.init();

    _isDarkMode = StorageService.getDarkMode() ?? false;
    _recentFiles = StorageService.getRecentFiles();
    _bookmarks = StorageService.getBookmarks();
    _isProUnlocked = StorageService.isProUnlocked();
    _isLoaded = true;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    StorageService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> addRecentFile(RecentFile file) async {
    await StorageService.addRecentFile(file);
    _recentFiles = StorageService.getRecentFiles();
    notifyListeners();
  }

  Future<void> removeRecentFile(String path) async {
    await StorageService.removeRecentFile(path);
    _recentFiles = StorageService.getRecentFiles();
    notifyListeners();
  }

  Future<void> clearRecentFiles() async {
    await StorageService.clearRecentFiles();
    _recentFiles = [];
    notifyListeners();
  }

  Future<void> addBookmark(Bookmark b) async {
    await StorageService.addBookmark(b);
    _bookmarks = StorageService.getBookmarks();
    notifyListeners();
  }

  Future<void> removeBookmark(String fileId, {int? page}) async {
    await StorageService.removeBookmark(fileId, page: page);
    _bookmarks = StorageService.getBookmarks();
    notifyListeners();
  }

  bool isBookmarked(String fileId, {int? page}) {
    return StorageService.isBookmarked(fileId, page: page);
  }

  Future<PurchaseResult> purchasePro() async {
    _isPurchasing = true;
    notifyListeners();
    final result = await PurchaseService.purchasePro();
    if (result.success) {
      _isProUnlocked = true;
    }
    _isPurchasing = false;
    notifyListeners();
    return result;
  }

  Future<PurchaseResult> restorePurchase() async {
    _isPurchasing = true;
    notifyListeners();
    final result = await PurchaseService.restorePurchase();
    if (result.success) {
      _isProUnlocked = true;
    }
    _isPurchasing = false;
    notifyListeners();
    return result;
  }

  List<RecentFile> get pdfFiles =>
      _recentFiles.where((f) => f.type == FileType.pdf).toList();

  List<RecentFile> get imageFiles =>
      _recentFiles.where((f) => f.type == FileType.image).toList();

  List<RecentFile> get documentFiles => _recentFiles
      .where((f) => f.type == FileType.docx || f.type == FileType.text)
      .toList();

  List<RecentFile> get otherFiles => _recentFiles
      .where((f) => f.type == FileType.zip || f.type == FileType.other)
      .toList();
}
