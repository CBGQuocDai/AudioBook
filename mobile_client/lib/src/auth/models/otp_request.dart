class OtpRequest {
  final String email;

  const OtpRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}
