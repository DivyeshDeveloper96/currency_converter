class AppConstants {
  AppConstants._();

  // Replace with your apilayer.com API key
  static const String apiKey = 'LfJk8oAqwLr5ZGQW43ajiTpHLXhngyDa';
  static const String baseUrl = 'https://api.apilayer.com/exchangerates_data';

  static const String defaultBaseCurrency = 'USD';

  // How long before we consider cached rates stale (1 hour)
  static const int cacheExpiryMinutes = 60;

  // DB config
  static const String dbName = 'currency_converter.db';
  static const int dbVersion = 1;

  // Shared prefs keys
  static const String prefBaseCurrency = 'base_currency';
  static const String prefLastFetchedAt = 'last_fetched_at';
}
