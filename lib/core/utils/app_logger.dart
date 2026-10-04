import 'package:flutter/foundation.dart';

/// Centralized, high-performance Pretty Logger for Flutter & Supabase.
///
/// Features:
/// - Categorized logging: Debug, Info, Success, Warning, Error, Auth, Network, Navigation, Database.
/// - ANSI Color coding for Debug Consoles.
/// - Strict sensitive data sanitization (Passwords: ********, Tokens: [REDACTED]).
/// - Only executes detailed logs when [kDebugMode] is true.
class AppLogger {
  AppLogger._();

  // ─── ANSI Color Codes ───────────────────────────────────────────
  static const String _reset = '\x1B[0m';
  static const String _gray = '\x1B[90m';
  static const String _blue = '\x1B[34m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
  static const String _purple = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _magenta = '\x1B[95m';
  static const String _brightBlue = '\x1B[94m';

  static const String _divider =
      '════════════════════════════════════════════════════';

  // ─── Core Helper ────────────────────────────────────────────────
  static void _log({
    required String header,
    required String color,
    required Map<String, dynamic> items,
    String? rawMessage,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;

    final timestamp = _formatTime(DateTime.now());
    final buffer = StringBuffer();

    buffer.writeln('$color$_divider');
    buffer.writeln(' $header');
    buffer.writeln('$_divider$_reset');

    if (rawMessage != null && rawMessage.isNotEmpty) {
      buffer.writeln('$color📌 Message    : $rawMessage$_reset');
    }

    items.forEach((key, value) {
      if (value != null) {
        final sanitizedValue = _sanitize(key, value);
        buffer.writeln('$color${key.padRight(13)} : $sanitizedValue$_reset');
      }
    });

    buffer.writeln('$color⏱️ Time       : $timestamp$_reset');

    if (error != null) {
      buffer.writeln('$color🔴 Error      : $error$_reset');
      if (error is Exception || error is Error) {
        final errString = error.toString();
        if (errString.contains('SocketException') ||
            errString.contains('Failed host lookup')) {
          buffer.writeln(
            '$color🔴 Type       : SocketException (DNS / Network Error)$_reset',
          );
        }
      }
    }

    if (stackTrace != null) {
      buffer.writeln('$color📜 StackTrace :$_reset');
      final lines = stackTrace.toString().split('\n').take(4);
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          buffer.writeln('$color   $line$_reset');
        }
      }
    }

    buffer.writeln('$color$_divider$_reset');

    debugPrint(buffer.toString());
  }

  // ─── Public API ─────────────────────────────────────────────────

  /// Debug level log
  static void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(
      header: '🐛 DEBUG ${tag != null ? "[$tag]" : ""}',
      color: _gray,
      items: data ?? {},
      rawMessage: message,
    );
  }

  /// Info level log
  static void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(
      header: 'ℹ️ INFO ${tag != null ? "[$tag]" : ""}',
      color: _blue,
      items: data ?? {},
      rawMessage: message,
    );
  }

  /// Success level log
  static void success(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
  }) {
    _log(
      header: '✅ SUCCESS ${tag != null ? "[$tag]" : ""}',
      color: _green,
      items: data ?? {},
      rawMessage: message,
    );
  }

  /// Warning level log
  static void warning(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
  }) {
    _log(
      header: '⚠️ WARNING ${tag != null ? "[$tag]" : ""}',
      color: _yellow,
      items: data ?? {},
      rawMessage: message,
    );
  }

  /// Error level log
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? location,
    Map<String, dynamic>? data,
  }) {
    final map = <String, dynamic>{};
    if (location != null) map['📍 Location'] = location;
    if (data != null) map.addAll(data);

    _log(
      header: '🚨 ERROR',
      color: _red,
      items: map,
      rawMessage: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Auth Logger for Supabase Authentication flow
  static void auth(
    String event, {
    String? email,
    String? userId,
    String? role,
    String? route,
    Duration? duration,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    final isErr = error != null;
    final header = isErr ? '❌ AUTH ERROR' : '🔐 AUTHENTICATION';
    final color = isErr ? _red : _purple;

    final map = <String, dynamic>{'📌 Event': event};
    if (email != null) map['📧 Email'] = email;
    if (userId != null) map['👤 User ID'] = userId;
    if (role != null) map['🎭 Role'] = role;
    if (route != null) map['➡️ Route'] = route;
    if (duration != null) map['⏱️ Duration'] = '${duration.inMilliseconds} ms';
    if (data != null) map.addAll(data);

    _log(
      header: header,
      color: color,
      items: map,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Navigation Logger for GoRouter route transitions
  static void navigation({
    required String from,
    required String to,
    String? role,
    bool isSuccess = true,
    String? reason,
  }) {
    final map = <String, dynamic>{};
    if (role != null) map['👤 Role'] = role;
    map['📍 From'] = from;
    map['➡️ To'] = to;
    map['✅ Result'] = isSuccess ? 'SUCCESS' : 'BLOCKED';
    if (reason != null) map['❓ Reason'] = reason;

    _log(
      header: isSuccess ? '🧭 NAVIGATION' : '⚠️ NAVIGATION FAILED',
      color: isSuccess ? _brightBlue : _yellow,
      items: map,
    );
  }

  /// Network Logger for Supabase HTTP/REST requests
  static void network(
    String method, {
    required String url,
    int? statusCode,
    Duration? duration,
    Object? error,
    Map<String, dynamic>? data,
  }) {
    final isErr = error != null || (statusCode != null && statusCode >= 400);
    final color = isErr ? _red : _cyan;
    final header = isErr ? '❌ NETWORK ERROR' : '🌐 NETWORK';

    final uri = Uri.tryParse(url);
    final host = uri?.host ?? url;
    final endpoint = uri?.path ?? '';

    final map = <String, dynamic>{
      '➡️ Method': method.toUpperCase(),
      '🌐 Host': host,
    };
    if (endpoint.isNotEmpty) map['📍 Endpoint'] = endpoint;
    if (statusCode != null) map['📊 Status'] = statusCode.toString();
    if (duration != null) map['⏱️ Duration'] = '${duration.inMilliseconds} ms';
    map['✅ Result'] = isErr ? 'FAILED' : 'SUCCESS';
    if (data != null) map.addAll(data);

    _log(header: header, color: color, items: map, error: error);
  }

  /// Database Logger for Supabase query operations
  static void database(
    String operation, {
    required String table,
    int? rows,
    Duration? duration,
    Object? error,
    Map<String, dynamic>? data,
  }) {
    final isErr = error != null;
    final color = isErr ? _red : _magenta;
    final header = isErr ? '❌ DATABASE ERROR' : '🗄️ DATABASE';

    final map = <String, dynamic>{
      '📌 Operation': operation.toUpperCase(),
      '📋 Table': table,
    };
    if (rows != null) map['📊 Rows'] = rows;
    if (duration != null) map['⏱️ Duration'] = '${duration.inMilliseconds} ms';
    map['✅ Result'] = isErr ? 'FAILED' : 'SUCCESS';
    if (data != null) map.addAll(data);

    _log(header: header, color: color, items: map, error: error);
  }

  // ─── Domain Specific Action Loggers ──────────────────────────────

  /// Log Cart Actions (ADD_TO_CART_SUCCESS, ADD_TO_CART_FAILED)
  static void logCart(
    String event, {
    required String userId,
    required int productId,
    int? quantity,
    Object? error,
    Duration? duration,
  }) {
    final isSuccess = event.endsWith('SUCCESS');
    _log(
      header: isSuccess ? '🛒 ADD_TO_CART_SUCCESS' : '🛒 ADD_TO_CART_FAILED',
      color: isSuccess ? _green : _red,
      items: {
        'USER ID': userId,
        'PRODUCT ID': productId,
        if (quantity != null) 'QUANTITY': quantity,
        if (duration != null) 'DURATION': '${duration.inMilliseconds} ms',
      },
      error: error,
    );
  }

  /// Log Favorite Actions (FAVORITE_ADDED, FAVORITE_REMOVED)
  static void logFavorite(
    String event, {
    required String userId,
    required int productId,
    Object? error,
  }) {
    final isAdded = event.contains('ADDED');
    _log(
      header: isAdded ? '❤️ FAVORITE_ADDED' : '💔 FAVORITE_REMOVED',
      color: isAdded ? _magenta : _yellow,
      items: {'USER ID': userId, 'PRODUCT ID': productId},
      error: error,
    );
  }

  /// Log Order Actions (ORDER_CREATED, ORDER_CREATE_FAILED)
  static void logOrder(
    String event, {
    required String userId,
    String? orderId,
    int? quantity,
    String? paymentMethod,
    String? orderStatus,
    Object? error,
    Duration? duration,
  }) {
    final isSuccess = event == 'ORDER_CREATED';
    _log(
      header: isSuccess ? '📦 ORDER_CREATED' : '❌ ORDER_CREATE_FAILED',
      color: isSuccess ? _green : _red,
      items: {
        'USER ID': userId,
        if (orderId != null) 'ORDER ID': orderId,
        if (quantity != null) 'QUANTITY': quantity,
        // ignore: use_null_aware_elements
        if (paymentMethod != null) 'PAYMENT METHOD': paymentMethod,
        if (orderStatus != null) 'ORDER STATUS': orderStatus,
        if (duration != null) 'DURATION': '${duration.inMilliseconds} ms',
      },
      error: error,
    );
  }

  /// Log Stock Updates (STOCK_UPDATED)
  static void logStock({
    required int productId,
    required int oldStock,
    required int newStock,
  }) {
    _log(
      header: '📉 STOCK_UPDATED',
      color: _cyan,
      items: {
        'PRODUCT ID': productId,
        'OLD STOCK': oldStock,
        'NEW STOCK': newStock,
      },
    );
  }

  /// Log Admin Actions (ADMIN_ORDER_ACCEPTED, ADMIN_ORDER_REJECTED)
  static void logAdmin(
    String event, {
    required String orderId,
    required String orderStatus,
    Object? error,
  }) {
    final isAccepted = event == 'ADMIN_ORDER_ACCEPTED';
    _log(
      header: isAccepted ? '✅ ADMIN_ORDER_ACCEPTED' : '🚫 ADMIN_ORDER_REJECTED',
      color: isAccepted ? _green : _red,
      items: {'ORDER ID': orderId, 'ORDER STATUS': orderStatus},
      error: error,
    );
  }

  /// Log Notifications (NOTIFICATION_RECEIVED)
  static void logNotification({
    required String userId,
    required String title,
    String? orderId,
  }) {
    _log(
      header: '🔔 NOTIFICATION_RECEIVED',
      color: _brightBlue,
      items: {
        'USER ID': userId,
        'TITLE': title,
        if (orderId != null) 'ORDER ID': orderId,
      },
    );
  }

  // ─── Sensitive Data Redaction ────────────────────────────────────

  static dynamic _sanitize(String key, dynamic value) {
    if (value == null) return null;

    final lowerKey = key.toLowerCase();

    // Redact Passwords
    if (lowerKey.contains('password') ||
        lowerKey.contains('pass') ||
        lowerKey.contains('pwd') ||
        lowerKey.contains('secret')) {
      return '********';
    }

    // Redact Tokens / Keys / JWTs
    if (lowerKey.contains('token') ||
        lowerKey.contains('jwt') ||
        lowerKey.contains('auth') ||
        lowerKey.contains('key')) {
      return '[REDACTED]';
    }

    return value;
  }

  static String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final ms = time.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}
