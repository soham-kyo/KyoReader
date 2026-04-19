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

class DocxPreviewScreen extends StatefulWidget {
  final RecentFile file;

  const DocxPreviewScreen({super.key, required this.file});

  @override
  State<DocxPreviewScreen> createState() => _DocxPreviewScreenState();
}

class _DocxPreviewScreenState extends State<DocxPreviewScreen> {
  String? _text;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app = context.read<AppProvider>();
    if (!app.isProUnlocked) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final bytes = await File(widget.file.path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      String? xml;
      for (final f in archive) {
        if (f.name == 'word/document.xml') {
          xml = String.fromCharCodes(f.content as List<int>);
          break;
        }
      }
      if (xml != null) {
        // Extract readable text from XML
        String text = xml
            .replaceAllMapped(RegExp(r'<w:p[ >].*?</w:p>', dotAll: true), (m) {
              final inner = m.group(0) ?? '';
              final stripped = inner.replaceAll(RegExp(r'<[^>]+>'), '');
              return '$stripped\n\n';
            })
            .replaceAll(RegExp(r'<w:br[^/]*/?>'), '\n')
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&apos;', "'")
            .replaceAll(RegExp(r'\n{3,}'), '\n\n')
            .trim();
        setState(() {
          _text = text.isEmpty ? '(Document appears to be empty)' : text;
          _isLoading = false;
        });
      } else {
        setState(() {
          _text = '(Could not find readable content in this file)';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = Theme.of(context);

    if (!app.isProUnlocked) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.file.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.docxLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: AppColors.docx,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'DOCX Viewer is Pro',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upgrade to KyoReader Pro to open Word documents.',
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
            Text(
              FileUtils.formatSize(widget.file.size),
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
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
                  const Text('Failed to read document'),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _hasError = false;
                      });
                      _load();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(
                _text ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.8,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
    );
  }
}
