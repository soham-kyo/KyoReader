import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recent_file.dart';
import '../utils/file_utils.dart';

class TextViewerScreen extends StatefulWidget {
  final RecentFile file;

  const TextViewerScreen({super.key, required this.file});

  @override
  State<TextViewerScreen> createState() => _TextViewerScreenState();
}

class _TextViewerScreenState extends State<TextViewerScreen> {
  String? _content;
  String? _error;
  bool _isLoading = true;
  bool _isMonospace = false;
  double _fontSize = 14;
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFile() async {
    try {
      final file = File(widget.file.path);
      final raw = await file.readAsString();
      final ext = widget.file.name.split('.').last.toLowerCase();

      String content = raw;
      if (ext == 'json') {
        try {
          final obj = jsonDecode(raw);
          const encoder = JsonEncoder.withIndent('  ');
          content = encoder.convert(obj);
        } catch (_) {
          content = raw;
        }
      }

      setState(() {
        _content = content;
        _isLoading = false;
        _isMonospace = [
          'json',
          'js',
          'ts',
          'dart',
          'py',
          'swift',
          'kt',
          'java',
          'css',
          'html',
          'xml',
          'yaml',
          'yml',
          'csv',
          'log',
        ].contains(ext);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_content == null) return;
    Clipboard.setData(ClipboardData(text: _content!));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  int get _matchCount {
    if (_searchQuery.isEmpty || _content == null) return 0;
    return RegExp(
      RegExp.escape(_searchQuery),
      caseSensitive: false,
    ).allMatches(_content!).length;
  }

  List<TextSpan> _buildSpans(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }
    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final lowerQ = query.toLowerCase();
    int start = 0;
    while (true) {
      final idx = lower.indexOf(lowerQ, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: const TextStyle(
            backgroundColor: Color(0xFFFFEB3B),
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = idx + query.length;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.file.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_content != null)
              Text(
                '${_content!.split('\n').length} lines · ${FileUtils.formatSize(widget.file.size)}',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
          ],
        ),
        actions: [
          if (_content != null) ...[
            IconButton(
              icon: Icon(
                Icons.search_rounded,
                color: _showSearch ? theme.colorScheme.primary : null,
              ),
              onPressed: () => setState(() => _showSearch = !_showSearch),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) {
                switch (v) {
                  case 'copy':
                    _copyToClipboard();
                  case 'mono':
                    setState(() => _isMonospace = !_isMonospace);
                  case 'bigger':
                    setState(() => _fontSize = (_fontSize + 2).clamp(10, 30));
                  case 'smaller':
                    setState(() => _fontSize = (_fontSize - 2).clamp(10, 30));
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'copy', child: Text('Copy All')),
                PopupMenuItem(
                  value: 'mono',
                  child: Text(
                    _isMonospace ? 'Proportional Font' : 'Monospace Font',
                  ),
                ),
                const PopupMenuItem(
                  value: 'bigger',
                  child: Text('Increase Font Size'),
                ),
                const PopupMenuItem(
                  value: 'smaller',
                  child: Text('Decrease Font Size'),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (_showSearch)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: const InputDecoration(
                        hintText: 'Search in file…',
                        prefixIcon: Icon(Icons.search_rounded, size: 18),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '$_matchCount matches',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
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
                        const Text('Failed to read file'),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _loadFile();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: _isMonospace ? 'monospace' : null,
                          fontSize: _fontSize,
                          height: 1.6,
                          color: theme.colorScheme.onSurface,
                        ),
                        children: _buildSpans(_content ?? '', _searchQuery),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
