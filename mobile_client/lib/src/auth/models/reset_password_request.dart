class ResetPasswordRequest {
  final String password;

  const ResetPasswordRequest({required this.password});

  Map<String, dynamic> toJson() {
    return {
      'password': password,
    };
  }
}
