import 'app_failure.dart';

sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = ResultSuccess<T>;

  const factory Result.failure(AppFailure failure) = ResultFailure<T>;

  bool get isSuccess => this is ResultSuccess<T>;

  bool get isFailure => this is ResultFailure<T>;

  T? get valueOrNull {
    return switch (this) {
      ResultSuccess<T>(:final value) => value,
      ResultFailure<T>() => null,
    };
  }

  AppFailure? get failureOrNull {
    return switch (this) {
      ResultSuccess<T>() => null,
      ResultFailure<T>(:final failure) => failure,
    };
  }

  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    return switch (this) {
      ResultSuccess<T>(:final value) => success(value),
      ResultFailure<T>(failure: final appFailure) => failure(appFailure),
    };
  }

  R fold<R>(
    R Function(AppFailure failure) onFailure,
    R Function(T value) onSuccess,
  ) {
    return when(success: onSuccess, failure: onFailure);
  }

  Result<R> map<R>(R Function(T value) mapper) {
    return switch (this) {
      ResultSuccess<T>(:final value) => Result<R>.success(mapper(value)),
      ResultFailure<T>(:final failure) => Result<R>.failure(failure),
    };
  }

  T getOrElse(T Function(AppFailure failure) fallback) {
    return switch (this) {
      ResultSuccess<T>(:final value) => value,
      ResultFailure<T>(:final failure) => fallback(failure),
    };
  }
}

final class ResultSuccess<T> extends Result<T> {
  const ResultSuccess(this.value);

  final T value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ResultSuccess<T> && other.value == value;
  }

  @override
  int get hashCode => Object.hash(ResultSuccess<T>, value);
}

final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);

  final AppFailure failure;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ResultFailure<T> && other.failure == failure;
  }

  @override
  int get hashCode => Object.hash(ResultFailure<T>, failure);
}
