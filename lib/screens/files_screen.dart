import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recent_file.dart';
import '../providers/app_provider.dart';
import '../widgets/file_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/quick_preview_sheet.dart';
import 'pdf_viewer_screen.dart';
import 'image_viewer_screen.dart';
import 'text_viewer_screen.dart';
import 'docx_preview_screen.dart';
import 'zip_preview_screen.dart';
import 'upgrade_screen.dart';

enum _Category { all, documents, images, others }

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  _Category _selected = _Category.all;
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RecentFile> _filtered(AppProvider app) {
    List<RecentFile> files;
    switch (_selected) {
      case _Category.all:
        files = app.recentFiles.toList();
        break;
      case _Category.documents:
        files = [...app.pdfFiles, ...app.documentFiles];
        break;
      case _Category.images:
        files = app.imageFiles;
        break;
      case _Category.others:
        files = app.otherFiles;
        break;
    }

    if (_search.isNotEmpty) {
      files = files
          .where((f) => f.name.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    return files;
  }

  void _openFile(RecentFile file) {
    final app = context.read<AppProvider>();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unsupported file format')),
        );
        return;
      case FileType.any:
        throw UnimplementedError();
    }

    final updated = file.copyWith(lastOpened: DateTime.now());
    app.addRecentFile(updated);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final files = _filtered(app);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'Files',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search files…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Category chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: _Category.values.map((cat) {
                  final isSelected = cat == _selected;
                  final label = {
                    _Category.all: 'All',
                    _Category.documents: 'Documents',
                    _Category.images: 'Images',
                    _Category.others: 'Others',
                  }[cat]!;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.dividerColor,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // File list
            Expanded(
              child: files.isEmpty
                  ? EmptyState(
                      icon: Icons.folder_outlined,
                      title:
                          _search.isNotEmpty ? 'No Results' : 'No Files Here',
                      subtitle: _search.isNotEmpty
                          ? 'Try a different search term.'
                          : 'Open some files first to see them here.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: files.length,
                      itemBuilder: (context, i) {
                        final file = files[i];
                        return FileCard(
                          file: file,
                          index: i,
                          showDelete: true,
                          onTap: () => _openFile(file),
                          onLongPress: () =>
                              QuickPreviewSheet.show(context, file),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
