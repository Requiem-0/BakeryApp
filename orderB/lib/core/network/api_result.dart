import '../errors/api_failure.dart';

/// Lightweight Result wrapper used by repositories.
///
/// Use [ApiResult.success] / [ApiResult.failure] factories. Inspect via
/// [isSuccess] / [isFailure] and read [data] or [failure] directly.
class ApiResult<T> {
  final T? data;
  final ApiFailure? failure;
  final bool isSuccess;

  const ApiResult._({
    this.data,
    this.failure,
    required this.isSuccess,
  });

  factory ApiResult.success(T data) =>
      ApiResult._(data: data, isSuccess: true);

  factory ApiResult.failure(ApiFailure failure) =>
      ApiResult._(failure: failure, isSuccess: false);

  bool get isFailure => !isSuccess;
}
