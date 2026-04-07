class RecoverPasswordArgs {
  final String token;
  final String email;

  const RecoverPasswordArgs({
    required this.token,
    required this.email,
  });
}
