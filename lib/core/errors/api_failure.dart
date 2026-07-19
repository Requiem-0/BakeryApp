/// Plain failure type returned by the API/repository layer.
///
/// Intentionally not a sealed hierarchy — the consumer only needs a
/// human-readable message and an optional HTTP status code.
class ApiFailure implements Exception {
  final String message;
  final int? statusCode;

  const ApiFailure({required this.message, this.statusCode});

  @override
  String toString() =>
      'ApiFailure(${statusCode ?? '-'}): $message';
}
