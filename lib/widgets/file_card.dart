import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/recent_file.dart';
import '../providers/app_provider.dart';
import '../utils/file_utils.dart';

class FileCard extends StatelessWidget {
  final RecentFile file;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool showDelete;
  final int index;

  const FileCard({
    super.key,
    required this.file,
    required this.onTap,
    this.onLongPress,
    this.showDelete = false,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDarkMode;
    final theme = Theme.of(context);
    final color = FileUtils.colorForType(file.type, dark: isDark);
    final bgColor = FileUtils.bgColorForType(file.type, dark: isDark);
    final icon = FileUtils.iconForType(file.type);

    return Animate(
      effects: [
        FadeEffect(duration: 250.ms, delay: (index * 40).ms),
        SlideEffect(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
          duration: 300.ms,
          delay: (index * 40).ms,
          curve: Curves.easeOut,
        ),
      ],
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              file.type.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            FileUtils.formatSize(file.size),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '·',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            FileUtils.formatDate(file.lastOpened),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Action button
                if (showDelete)
                  Consumer<AppProvider>(
                    builder: (_, app, __) => GestureDetector(
                      onTap: () => _confirmDelete(context, app),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider app) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove File'),
        content: const Text('Remove this file from recents?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              app.removeRecentFile(file.path);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
