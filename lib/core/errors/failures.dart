/// Failure types for propagating errors through layers
library;

sealed class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class LocationFailure extends Failure {
  final bool isPermanentlyDenied;
  const LocationFailure(super.message, {this.isPermanentlyDenied = false});
}

class GeminiFailure extends Failure {
  const GeminiFailure(super.message);
}

class JsonParseFailure extends Failure {
  const JsonParseFailure(super.message);
}

class NoDataFailure extends Failure {
  const NoDataFailure(super.message);
}

class PlacesFailure extends Failure {
  const PlacesFailure(super.message);
}
