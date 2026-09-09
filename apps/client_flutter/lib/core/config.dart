class AppConfig {
  static const environment = String.fromEnvironment('APP_ENV');
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static void validate() {
    if (!['development', 'staging', 'production'].contains(environment)) {
      throw StateError('APP_ENV is required');
    }
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme)) {
      throw StateError('API_BASE_URL is required');
    }
    if (environment != 'development' && uri.scheme != 'https') {
      throw StateError('HTTPS is required outside development');
    }
  }
}
