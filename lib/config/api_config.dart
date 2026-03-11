/// API Configuration
/// Easy switching between localhost and production environments
class ApiConfig {
  // Change this to switch between environments
  // static const String _environment = 'localhost'; 
  static const String _environment = 'production';

  // API Base URLs
  static const String _localhostApi = 'http://192.168.1.5:5000/api';
  static const String _productionApi = 'https://hrms-backend-zzzc.onrender.com/api';

  /// Get the current API base URL based on environment
  static String get baseUrl {
    switch (_environment) {
      case 'localhost':
        return _localhostApi;
      case 'production':
        return _productionApi;
      default:
        return _localhostApi;
    }
  }

  /// Get the current environment
  static String get environment => _environment;

  /// Helper to build full endpoint URLs
  static String endpoint(String path) {
    return '$baseUrl/$path';
  }

  /// Debugging: Print current configuration
  static void printConfig() {
    print('═════════════════════════════════════════');
    print('API Configuration:');
    print('Environment: $environment');
    print('Base URL: $baseUrl');
    print('═════════════════════════════════════════');
  }
}
