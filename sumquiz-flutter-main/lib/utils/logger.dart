import 'dart:developer' as developer;

class Logger {
  static void log(String message) {
    developer.log(message, name: 'sumquiz_app');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'sumquiz_app.error',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
