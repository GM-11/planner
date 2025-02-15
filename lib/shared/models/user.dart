import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;

  AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
  });

  factory AppUser.fromUser(User user) {
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      fullName: user.userMetadata?['full_name'],
      avatarUrl: user.userMetadata?['avatar_url'],
    );
  }
}
