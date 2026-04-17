/// Simple console logger for the app.
/// In production you can replace this with a real logging package (e.g. logger).
class AppLogger {
  static void info(String message) {
    // ignore: avoid_print
    print('[INFO] $message');
  }

  static void warning(String message) {
    // ignore: avoid_print
    print('[WARN] $message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    // ignore: avoid_print
    print('[ERROR] $message${error != null ? ' | $error' : ''}');
    if (stackTrace != null) {
      // ignore: avoid_print
      print(stackTrace);
    }
  }
}
