/// Result of the recognition and transcription done by the model.
///
/// Returned through the [onResult] callback on [listen].
class DeepSpeechResult {
  /// The transcribed text.
  final String text;

  /// Inidicates wheather this is the final result.
  /// Typically, the result obtained after calling [stop] will have [isFinal] set to true.
  /// No more results are returned in the current session after [isFinal] is true.
  final bool isFinal;

  DeepSpeechResult({
    required this.text,
    required this.isFinal,
  });

  factory DeepSpeechResult.fromMap(Map<String, dynamic> map) {
    return DeepSpeechResult(
      text: map['text'] ?? '',
      isFinal: map['isFinal'] ?? false,
    );
  }
}
