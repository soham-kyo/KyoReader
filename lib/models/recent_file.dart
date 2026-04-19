import 'dart:convert';

enum FileType { pdf, image, text, docx, zip, other, any }

extension FileTypeExtension on FileType {
  String get label {
    switch (this) {
      case FileType.pdf:
        return 'PDF';
      case FileType.image:
        return 'Image';
      case FileType.text:
        return 'Text';
      case FileType.docx:
        return 'Document';
      case FileType.zip:
        return 'Archive';
      case FileType.other:
        return 'Other';
      case FileType.any: //
        throw UnimplementedError();
    }
  }

  bool get requiresPro => this == FileType.docx || this == FileType.zip;
}

class RecentFile {
  final String id;
  final String name;
  final String path;
  final FileType type;
  final int size;
  final DateTime lastOpened;
  final String? mimeType;

  const RecentFile({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.lastOpened,
    this.mimeType,
  });

  RecentFile copyWith({DateTime? lastOpened}) {
    return RecentFile(
      id: id,
      name: name,
      path: path,
      type: type,
      size: size,
      lastOpened: lastOpened ?? this.lastOpened,
      mimeType: mimeType,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'type': type.name,
        'size': size,
        'lastOpened': lastOpened.millisecondsSinceEpoch,
        'mimeType': mimeType,
      };

  factory RecentFile.fromJson(Map<String, dynamic> json) {
    return RecentFile(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      type: FileType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FileType.other,
      ),
      size: json['size'] as int,
      lastOpened: DateTime.fromMillisecondsSinceEpoch(
        json['lastOpened'] as int,
      ),
      mimeType: json['mimeType'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory RecentFile.fromJsonString(String s) =>
      RecentFile.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
