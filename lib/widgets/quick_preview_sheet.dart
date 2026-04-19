import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recent_file.dart';
import '../providers/app_provider.dart';
import '../utils/file_utils.dart';
import '../screens/pdf_viewer_screen.dart';
import '../screens/image_viewer_screen.dart';
import '../screens/text_viewer_screen.dart';

class QuickPreviewSheet extends StatelessWidget {
  final RecentFile file;

  const QuickPreviewSheet({super.key, required this.file});

  static Future<void> show(BuildContext context, RecentFile file) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickPreviewSheet(file: file),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<AppProvider>().isDarkMode;
    final color = FileUtils.colorForType(file.type, dark: isDark);
    final bgColor = FileUtils.bgColorForType(file.type, dark: isDark);
    final icon = FileUtils.iconForType(file.type);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // File info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${file.type.label} · ${FileUtils.formatSize(file.size)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          // Actions
          _ActionRow(
            icon: Icons.open_in_full_rounded,
            label: 'Open File',
            color: theme.colorScheme.primary,
            onTap: () {
              Navigator.pop(context);
              _openFile(context);
            },
          ),
          _ActionRow(
            icon: Icons.delete_outline_rounded,
            label: 'Remove from Recents',
            color: Colors.red,
            onTap: () {
              Navigator.pop(context);
              context.read<AppProvider>().removeRecentFile(file.path);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _openFile(BuildContext context) {
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
      default:
        screen = PdfViewerScreen(file: file);
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
