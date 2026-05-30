import 'package:reservpy/src/core/supabase/supabase_config.dart';
import 'package:reservpy/src/shared/models/models.dart';

class NotificationRepository {
  final _client = SupabaseConfig.client;

  /// Fetch notifications for the current user, ordered by newest first.
  Future<List<AppNotification>> fetchForUser(String userId) async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return data.map((json) => AppNotification.fromJson(json)).toList();
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  /// Mark all notifications as read for a user.
  Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  /// Create a notification.
  Future<void> create({
    required String userId,
    String? businessId,
    required NotificationType type,
    required String title,
    required String body,
    String? reservationId,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'business_id': businessId,
      'type': type.name,
      'title': title,
      'body': body,
      'reservation_id': reservationId,
    });
  }
}
