class ClientResponse {
  final int id;
  final String? email;
  final String? name;
  final String? avatarUrl;
  final String? role;
  final bool? active;
  final String? tier;
  final int? totalCredit;

  ClientResponse({
    required this.id,
    this.email,
    this.name,
    this.avatarUrl,
    this.role,
    this.active,
    this.tier,
    this.totalCredit,
  });

  factory ClientResponse.fromJson(Map<String, dynamic> json) {
    String? finalAvatarUrl = json['avatarUrl'];
    
    if (finalAvatarUrl == null && json['avatarFile'] != null) {
      final avatarFile = json['avatarFile'];
      if (avatarFile is Map<String, dynamic>) {
        finalAvatarUrl = avatarFile['fileUrl'] ?? avatarFile['filePath'];
      }
    }

    return ClientResponse(
      id: json['id'] ?? 0,
      email: json['email'],
      name: json['name'],
      avatarUrl: finalAvatarUrl,
      role: json['role'],
      active: json['active'],
      tier: json['tier'],
      totalCredit: json['totalCredit'],
    );
  }
}
