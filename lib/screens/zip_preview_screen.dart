import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/recent_file.dart';
import '../providers/app_provider.dart';
import '../utils/file_utils.dart';
import '../utils/app_theme.dart';
import 'upgrade_screen.dart';

class ZipPreviewScreen extends StatefulWidget {
  final RecentFile file;

  const ZipPreviewScreen({super.key, required this.file});

  @override
  State<ZipPreviewScreen> createState() => _ZipPreviewScreenState();
}

class _ZipPreviewScreenState extends State<ZipPreviewScreen> {
  List<ArchiveFile>? _entries;
  bool _isLoading = true;
  bool _hasError = false;
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadZip();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadZip() async {
    final app = context.read<AppProvider>();
    if (!app.isProUnlocked) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final bytes = await File(widget.file.path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final entries = archive.files.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  List<ArchiveFile> get _filteredEntries {
    if (_search.isEmpty || _entries == null) return _entries ?? [];
    return _entries!
        .where((e) => e.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  int get _totalSize {
    return _entries?.fold<int>(0, (sum, e) => sum + e.size) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);

    if (!app.isProUnlocked) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.file.name)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.zipLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: AppColors.zip,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'ZIP Viewer is Pro',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upgrade to Pro to browse ZIP archives.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UpgradeScreen()),
                  ),
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: const Text('Upgrade to Pro'),
                ),
              ],
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
          ),
        ),
      );
    }

    final filtered = _filteredEntries;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            if (_entries != null)
              Text(
                '${_entries!.length} items · ${FileUtils.formatSize(_totalSize)}',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!_isLoading && _entries != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search in archive…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                ),
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red.shade400,
                          size: 52,
                        ),
                        const SizedBox(height: 16),
                        const Text('Failed to read archive'),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _hasError = false;
                            });
                            _loadZip();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : filtered.isEmpty
                ? const Center(child: Text('No matching files'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final entry = filtered[i];
                      final isDir =
                          entry.isFile == false || entry.name.endsWith('/');
                      final name = entry.name.split('/').last.isEmpty
                          ? entry.name
                                .split('/')
                                .where((s) => s.isNotEmpty)
                                .last
                          : entry.name.split('/').last;
                      final dir = entry.name.contains('/')
                          ? entry.name.substring(0, entry.name.lastIndexOf('/'))
                          : '';

                      return Animate(
                        effects: [
                          FadeEffect(duration: 200.ms, delay: (i * 20).ms),
                          SlideEffect(
                            begin: const Offset(0, 0.05),
                            end: Offset.zero,
                            duration: 200.ms,
                            delay: (i * 20).ms,
                          ),
                        ],
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isDir
                                      ? Icons.folder_rounded
                                      : Icons.insert_drive_file_rounded,
                                  size: 20,
                                  color: isDir
                                      ? AppColors.zip
                                      : theme.colorScheme.onSurface.withOpacity(
                                          0.4,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name.isEmpty ? entry.name : name,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                      if (dir.isNotEmpty)
                                        Text(
                                          dir,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.4),
                                                fontSize: 11,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (!isDir)
                                  Text(
                                    FileUtils.formatSize(entry.size),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.4),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
