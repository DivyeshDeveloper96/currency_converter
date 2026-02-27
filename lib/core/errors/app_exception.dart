/// Base class for all app-level exceptions.
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection. Showing cached data.']);
}

class ServerException extends AppException {
  final int? statusCode;
  const ServerException({this.statusCode, String message = 'Something went wrong on our end.'})
      : super(message);
}

class CacheException extends AppException {
  const CacheException([super.message = 'Failed to read local data.']);
}

class InvalidInputException extends AppException {
  const InvalidInputException([super.message = 'Please enter a valid amount.']);
}

class RateNotFoundException extends AppException {
  final String currencyCode;
  const RateNotFoundException(this.currencyCode)
      : super('Exchange rate not available for $currencyCode.');
}
