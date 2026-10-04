import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/utils/app_logger.dart';
import '../models/notification_model.dart';

final notificationsProvider = StateNotifierProvider<NotificationsNotifier,
    AsyncValue<List<NotificationModel>>>(
  (ref) => NotificationsNotifier(),
);

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  StreamSubscription? _realtimeSubscription;

  NotificationsNotifier() : super(const AsyncValue.data([])) {
    loadNotifications();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadNotifications() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      state = const AsyncValue.loading();
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final notifications = (response as List)
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribeRealtime() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      _realtimeSubscription = supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .listen((data) {
            final list = data
                .map((json) => NotificationModel.fromJson(json))
                .toList();

            // Log newest notification if present
            if (list.isNotEmpty && state.value != null && list.length > (state.value?.length ?? 0)) {
              final newest = list.first;
              AppLogger.logNotification(
                userId: userId,
                title: newest.title,
                orderId: newest.relatedOrderId,
              );
            }

            state = AsyncValue.data(list);
          });
    } catch (e) {
      AppLogger.error('Realtime notification error: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);

      final current = state.value ?? [];
      final updated = current.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      state = AsyncValue.data(updated);
    } catch (e) {
      await loadNotifications();
    }
  }
}

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider).value ?? [];
  return notifs.where((n) => !n.isRead).length;
});
