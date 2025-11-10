class Auth {
  final String id;
  final String email;
  final DateTime createdDate;
  final bool isEmailVerified;

  Auth({required this.id, required this.email, required this.createdDate, required this.isEmailVerified});
}