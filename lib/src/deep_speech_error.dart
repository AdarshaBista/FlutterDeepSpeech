/// Any error that can occur while the listening session is in progress.
///
/// Returned through the [onError] callback on [listen].
class DeepSpeechError {
  final Object error;
  final StackTrace stackTrace;

  DeepSpeechError({
    required this.error,
    required this.stackTrace,
  });
}
