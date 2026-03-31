class AvatarFile {
  final int? id;
  final String? filePath;
  final String? fileName;

  const AvatarFile({
    this.id,
    this.filePath,
    this.fileName,
  });

  factory AvatarFile.fromJson(Map<String, dynamic> json) {
    return AvatarFile(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      filePath: json['filePath']?.toString(),
      fileName: json['fileName']?.toString(),
    );
  }
}
