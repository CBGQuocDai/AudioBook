class FileDto {
  final int? id;
  final String? filePath;
  final String? fileName;

  FileDto({
    this.id,
    this.filePath,
    this.fileName,
  });

  factory FileDto.fromJson(Map<String, dynamic> json) {
    return FileDto(
      id: json['id'],
      filePath: json['filePath'],
      fileName: json['fileName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'fileName': fileName,
    };
  }
}