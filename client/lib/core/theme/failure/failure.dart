// ignore_for_file: public_member_api_docs, sort_constructors_first
class UserFailure {
  final String message;
  UserFailure([this.message = 'Unexpected error']);

  @override
  String toString() => 'UserFailure(message: $message)';
}
