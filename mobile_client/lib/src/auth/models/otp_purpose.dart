enum OtpPurpose {
  verifyEmail('VERIFY_EMAIL'),
  resetPassword('RESET_PASSWORD'),
  changeEmail('CHANGE_EMAIL');

  const OtpPurpose(this.value);

  final String value;

  static OtpPurpose fromValue(String value) {
    return OtpPurpose.values.firstWhere(
      (item) => item.value == value,
      orElse: () => OtpPurpose.verifyEmail,
    );
  }
}
