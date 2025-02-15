import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:planner/shared/constant.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../shared/models/user.dart';

class AuthRepository {
  final _supabase = SupabaseService.client;

  Future<void> signUp(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.session == null && response.user == null) {
        throw 'Failed to sign up';
      }

      final currentId = await OneSignal.User.getOnesignalId();
      final userId = response.user!.id;

      try {
        final deviceExists = await _supabase
            .from('user_devices')
            .select()
            .eq('user_id', userId);

        if (deviceExists.isEmpty) {
          try {
            await _supabase.from('user_devices').insert({
              'user_id': userId.toString(), // Ensure it's a string
              'signal_ids': "$currentId${AppConstants.delimeter}",
            });
          } catch (insertError) {
            rethrow;
          }
        } else {
          try {
            var signalIds = (deviceExists.first['signal_ids'] as String).split(
              AppConstants.delimeter,
            );

            // First try without .select().single()
            await _supabase
                .from('user_devices')
                .update({
                  'signal_ids': [
                    ...signalIds,
                    currentId,
                  ].join(AppConstants.delimeter),
                })
                .eq('user_id', userId);

            await _supabase
                .from('user_devices')
                .select()
                .eq('user_id', userId)
                .single();
          } catch (updateError) {
            rethrow;
          }
        }
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session == null) {
        throw 'Failed to sign in';
      }

      final currentId = await OneSignal.User.getOnesignalId();
      final userId = response.user!.id;

      try {
        final deviceExists = await _supabase
            .from('user_devices')
            .select()
            .eq('user_id', userId);

        if (deviceExists.isEmpty) {
          try {
            await _supabase.from('user_devices').insert({
              'user_id': userId.toString(), // Ensure it's a string
              'signal_ids': "$currentId${AppConstants.delimeter}",
            });
          } catch (insertError) {
            rethrow;
          }
        } else {
          try {
            var signalIds = (deviceExists.first['signal_ids'] as String).split(
              AppConstants.delimeter,
            );

            // First try without .select().single()
            await _supabase
                .from('user_devices')
                .update({
                  'signal_ids': [
                    ...signalIds,
                    currentId,
                  ].join(AppConstants.delimeter),
                })
                .eq('user_id', userId);

            // Then fetch the updated record

            await _supabase
                .from('user_devices')
                .select()
                .eq('user_id', userId)
                .single();
          } catch (updateError) {
            rethrow;
          }
        }
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'your-app-scheme://auth/reset-password',
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> resetPassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  AppUser? getCurrentUser() {
    final user = _supabase.auth.currentUser;
    return user != null ? AppUser.fromUser(user) : null;
  }

  Stream<AppUser?> authStateChanges() {
    return _supabase.auth.onAuthStateChange.map((event) {
      return event.session?.user != null
          ? AppUser.fromUser(event.session!.user)
          : null;
    });
  }

  String _handleAuthException(dynamic error) {
    if (error is AuthException) {
      return error.message;
    }
    return 'An unexpected error occurred';
  }
}
