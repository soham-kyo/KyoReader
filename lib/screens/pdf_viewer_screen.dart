import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:provider/provider.dart';
import '../models/recent_file.dart';
import '../models/bookmark.dart';
import '../providers/app_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final RecentFile file;

  const PdfViewerScreen({super.key, required this.file});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final _pdfController = PdfViewerController();
  final _pageController = TextEditingController();
  bool _showSearch = false;
  bool _isLoading = true;
  bool _hasError = false;
  int _currentPage = 1;
  int _totalPages = 0;
  final _searchTextController = TextEditingController();
  bool _isBookmarked = false;
  PdfTextSearchResult? _searchResult;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  void _checkBookmark() {
    final app = context.read<AppProvider>();
    setState(() {
      _isBookmarked = app.isBookmarked(widget.file.id, page: _currentPage);
    });
  }

  @override
  void dispose() {
    _pdfController.dispose();
    _searchResult?.dispose();
    _pageController.dispose();
    _searchTextController.dispose();
    super.dispose();
  }

  void _toggleBookmark() {
    final app = context.read<AppProvider>();
    if (_isBookmarked) {
      app.removeBookmark(widget.file.id, page: _currentPage);
      setState(() => _isBookmarked = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bookmark removed')));
    } else {
      app.addBookmark(
        Bookmark(
          fileId: widget.file.id,
          fileName: widget.file.name,
          filePath: widget.file.path,
          page: _currentPage,
          createdAt: DateTime.now(),
        ),
      );
      setState(() => _isBookmarked = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Page $_currentPage bookmarked')));
    }
  }

  void _goToPage() {
    _pageController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Go to Page'),
        content: TextField(
          controller: _pageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: 'Page 1 – $_totalPages'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(_pageController.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                _pdfController.jumpToPage(page);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.file.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_totalPages > 0)
              Text(
                'Page $_currentPage of $_totalPages',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: _isBookmarked ? Colors.amber : Colors.white70,
            ),
            onPressed: _toggleBookmark,
            tooltip: 'Bookmark',
          ),
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: _showSearch ? theme.colorScheme.primary : Colors.white70,
            ),
            onPressed: () => setState(() => _showSearch = !_showSearch),
            tooltip: 'Search',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
            onSelected: (v) {
              if (v == 'page') _goToPage();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'page', child: Text('Go to Page')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (_showSearch)
            Container(
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchTextController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: 'Search in PDF…',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white.withOpacity(0.5),
                          size: 18,
                        ),
                      ),
                      onChanged: (v) {
                        if (v.isNotEmpty) {
                          _searchResult?.dispose();
                          _searchResult = _pdfController.searchText(v);
                        } else {
                          _searchResult?.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.navigate_before_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: () => _searchResult?.previousInstance(),
                    tooltip: 'Previous',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.navigate_next_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: () => _searchResult?.nextInstance(),
                    tooltip: 'Next',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      _searchResult?.clear();
                      _searchResult?.dispose();
                      _searchResult = null;
                      _searchTextController.clear();
                      setState(() => _showSearch = false);
                    },
                  ),
                ],
              ),
            ),

          // PDF viewer
          Expanded(
            child: SizedBox.expand(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SfPdfViewer.file(
                      File(widget.file.path),
                      controller: _pdfController,
                      onDocumentLoaded: (details) {
                        setState(() {
                          _isLoading = false;
                          _totalPages = details.document.pages.count;
                        });
                      },
                      onDocumentLoadFailed: (_) {
                        setState(() {
                          _isLoading = false;
                          _hasError = true;
                        });
                      },
                      onPageChanged: (details) {
                        setState(() {
                          _currentPage = details.newPageNumber;
                          _isBookmarked =
                              context.read<AppProvider>().isBookmarked(
                                    widget.file.id,
                                    page: _currentPage,
                                  );
                        });
                      },
                      enableTextSelection: true,
                      canShowScrollStatus: true,
                      canShowPaginationDialog: false,
                    ),
                  ),
                  if (_isLoading)
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Loading PDF…',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  if (_hasError)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red,
                            size: 52,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load PDF',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(() {
                              _hasError = false;
                              _isLoading = true;
                            }),
                            child: const Text(
                              'Retry',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Page navigation bar
          if (!_isLoading && !_hasError && _totalPages > 0)
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.first_page_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: _currentPage > 1
                        ? () => _pdfController.jumpToPage(1)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: _currentPage > 1
                        ? () => _pdfController.previousPage()
                        : null,
                  ),
                  GestureDetector(
                    onTap: _goToPage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_currentPage / $_totalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: _currentPage < _totalPages
                        ? () => _pdfController.nextPage()
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.last_page_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: _currentPage < _totalPages
                        ? () => _pdfController.jumpToPage(_totalPages)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
