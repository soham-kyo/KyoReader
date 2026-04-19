import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:provider/provider.dart';
import '../models/recent_file.dart';
import '../providers/app_provider.dart';
import '../utils/file_utils.dart';
import '../widgets/file_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import '../widgets/quick_preview_sheet.dart';
import 'pdf_viewer_screen.dart';
import 'image_viewer_screen.dart';
import 'text_viewer_screen.dart';
import 'docx_preview_screen.dart';
import 'zip_preview_screen.dart';
import 'upgrade_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isPickingFile = false;

  Future<void> _pickFile() async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);

    try {
      final result = await file_picker.FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: file_picker.FileType.any,
      );

      if (result == null || result.files.isEmpty) return;
      final picked = result.files.first;
      if (picked.path == null) return;

      final path = picked.path!;
      final name = picked.name;
      final mimeType =
          picked.extension != null ? 'application/${picked.extension}' : null;
      final type = FileUtils.detectType(name, mimeType: mimeType);
      final size = picked.size;

      final file = RecentFile(
        id: FileUtils.generateId(path),
        name: name,
        path: path,
        type: type,
        size: size,
        lastOpened: DateTime.now(),
        mimeType: mimeType,
      );

      // ignore: use_build_context_synchronously
      final appProvider = context.read<AppProvider>();
      await appProvider.addRecentFile(file);
      if (mounted) _openFile(file, appProvider);
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  void _openFile(RecentFile file, AppProvider app) {
    // Check pro requirement
    if (file.type.requiresPro && !app.isProUnlocked) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UpgradeScreen()),
      );
      return;
    }

    Widget screen;
    switch (file.type) {
      case FileType.pdf:
        screen = PdfViewerScreen(file: file);
        break;
      case FileType.image:
        screen = ImageViewerScreen(file: file);
        break;
      case FileType.text:
        screen = TextViewerScreen(file: file);
        break;
      case FileType.docx:
        screen = DocxPreviewScreen(file: file);
        break;
      case FileType.zip:
        screen = ZipPreviewScreen(file: file);
        break;
      case FileType.other:
      case FileType.any:
        _showUnsupportedDialog();
        return;
    }

    // Update last opened
    final updated = file.copyWith(lastOpened: DateTime.now());
    context.read<AppProvider>().addRecentFile(updated);

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showUnsupportedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unsupported Format'),
        content: const Text(
          'This file format is not supported by KyoReader. '
          'Try opening it with another app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final recents = app.recentFiles;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KyoReader',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ).animate().fadeIn(duration: 300.ms),
                          Text(
                            'Universal File Reader',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ).animate(delay: 80.ms).fadeIn(duration: 300.ms),
                        ],
                      ),
                    ),
                    if (!app.isProUnlocked)
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UpgradeScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.workspace_premium_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Pro',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate(delay: 100.ms)
                          .fadeIn()
                          .scale(begin: const Offset(0.8, 0.8)),
                    if (app.isProUnlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pro',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Pick file button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: GestureDetector(
                  onTap: _pickFile,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(
                            0.35,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: _isPickingFile
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Open a File',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'PDF, Images, Text, DOCX, ZIP',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.folder_open_rounded,
                          color: Colors.white70,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.05, end: 0),
              ),
            ),

            // Recent files
            if (recents.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.folder_open_rounded,
                  title: 'No Recent Files',
                  subtitle:
                      'Open a file to get started.\nPDF, Images, Text and more.',
                  actionLabel: 'Browse Files',
                  onAction: _pickFile,
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SectionHeader(
                    title: 'Recent Files',
                    actionLabel: 'Clear All',
                    onAction: () => _confirmClearAll(context, app),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final file = recents[i];
                    return FileCard(
                      file: file,
                      index: i,
                      showDelete: true,
                      onTap: () => _openFile(file, context.read<AppProvider>()),
                      onLongPress: () => QuickPreviewSheet.show(context, file),
                    );
                  }, childCount: recents.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
      floatingActionButton: recents.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _pickFile,
              icon: _isPickingFile
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_rounded),
              label: const Text('Open File'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ).animate().scale(
                begin: const Offset(0, 0),
                curve: Curves.elasticOut,
              )
          : null,
    );
  }

  void _confirmClearAll(BuildContext context, AppProvider app) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Recent Files'),
        content: const Text('Remove all files from your recent list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              app.clearRecentFiles();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
