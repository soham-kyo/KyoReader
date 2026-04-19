import 'dart:io';
import 'package:flutter/material.dart';
import '../models/recent_file.dart';
import '../utils/app_theme.dart';

class FileUtils {
  static FileType detectType(String name, {String? mimeType}) {
    final ext = name.split('.').last.toLowerCase();
    final mime = mimeType?.toLowerCase() ?? '';

    if (mime.contains('pdf') || ext == 'pdf') return FileType.pdf;
    if (mime.startsWith('image/') ||
        ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'].contains(ext)) {
      return FileType.image;
    }
    if (mime.contains('word') ||
        mime.contains('officedocument.wordprocessing') ||
        ['doc', 'docx', 'odt', 'rtf'].contains(ext)) {
      return FileType.docx;
    }
    if (mime.contains('zip') ||
        mime.contains('compressed') ||
        mime.contains('archive') ||
        ['zip', 'tar', 'gz', 'rar', '7z'].contains(ext)) {
      return FileType.zip;
    }
    if (mime.startsWith('text/') ||
        [
          'txt',
          'json',
          'md',
          'csv',
          'xml',
          'html',
          'js',
          'ts',
          'css',
          'yaml',
          'yml',
          'log',
          'dart',
          'py',
          'swift',
          'kt',
          'java',
        ].contains(ext)) {
      return FileType.text;
    }
    return FileType.other;
  }

  static String formatSize(int bytes) {
    if (bytes == 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day} ${_month(date.month)}';
  }

  static String _month(int m) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m];
  }

  static String generateId(String path) {
    return path.hashCode.abs().toRadixString(16) +
        DateTime.now().millisecondsSinceEpoch.toRadixString(16);
  }

  static Future<int> getFileSize(String path) async {
    try {
      return await File(path).length();
    } catch (_) {
      return 0;
    }
  }

  static IconData iconForType(FileType type) {
    switch (type) {
      case FileType.pdf:
        return Icons.picture_as_pdf_rounded;
      case FileType.image:
        return Icons.image_rounded;
      case FileType.text:
        return Icons.code_rounded;
      case FileType.docx:
        return Icons.description_rounded;
      case FileType.zip:
        return Icons.folder_zip_rounded;
      case FileType.other:
      case FileType.any:
        return Icons.insert_drive_file_rounded;
    }
  }

  static Color colorForType(FileType type, {bool dark = false}) {
    if (dark) {
      switch (type) {
        case FileType.pdf:
          return AppColors.pdfDark;
        case FileType.image:
          return AppColors.imageDark;
        case FileType.text:
          return AppColors.textFileDark;
        case FileType.docx:
          return AppColors.docxDark;
        case FileType.zip:
          return AppColors.zipDark;
        case FileType.other:
        case FileType.any:
          return AppColors.otherDark;
      }
    }
    switch (type) {
      case FileType.pdf:
        return AppColors.pdf;
      case FileType.image:
        return AppColors.image;
      case FileType.text:
        return AppColors.textFile;
      case FileType.docx:
        return AppColors.docx;
      case FileType.zip:
        return AppColors.zip;
      case FileType.other:
      case FileType.any:
        return AppColors.other;
    }
  }

  static Color bgColorForType(FileType type, {bool dark = false}) {
    if (dark) {
      switch (type) {
        case FileType.pdf:
          return AppColors.pdfLightDark;
        case FileType.image:
          return AppColors.imageLightDark;
        case FileType.text:
          return AppColors.textFileLightDark;
        case FileType.docx:
          return AppColors.docxLightDark;
        case FileType.zip:
          return AppColors.zipLightDark;
        case FileType.other:
        case FileType.any:
          return AppColors.otherLightDark;
      }
    }
    switch (type) {
      case FileType.pdf:
        return AppColors.pdfLight;
      case FileType.image:
        return AppColors.imageLight;
      case FileType.text:
        return AppColors.textFileLight;
      case FileType.docx:
        return AppColors.docxLight;
      case FileType.zip:
        return AppColors.zipLight;
      case FileType.other:
      case FileType.any:
        return AppColors.otherLight;
    }
  }
}
