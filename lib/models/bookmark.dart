import 'dart:convert';

class Bookmark {
  final String fileId;
  final String fileName;
  final String filePath;
  final int? page;
  final DateTime createdAt;

  const Bookmark({
    required this.fileId,
    required this.fileName,
    required this.filePath,
    this.page,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'fileId': fileId,
    'fileName': fileName,
    'filePath': filePath,
    'page': page,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      fileId: json['fileId'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      page: json['page'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Bookmark.fromJsonString(String s) =>
      Bookmark.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
