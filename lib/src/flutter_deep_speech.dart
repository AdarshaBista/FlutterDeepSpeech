import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter_deep_speech/src/deep_speech_error.dart';
import 'package:flutter_deep_speech/src/deep_speech_result.dart';

typedef ResultCallback = void Function(DeepSpeechResult);
typedef ErrorCallback = void Function(DeepSpeechError);

class FlutterDeepSpeech {
  static const MethodChannel _methodChannel = MethodChannel(
    'adrsh/flutter_deep_speech',
  );

  static const EventChannel _listenEventChannel = EventChannel(
    'adrsh/flutter_deep_speech/listen',
  );

  /// Subscription to the stream created when [listen] is called.
  ///
  /// Gets cancelled once [stop] is called.
  StreamSubscription? _listenEventSub;

  /// Indicates wheather the model has been loaded or not.
  ///
  /// Certain methods (see below) won't do anything unless the model has been loaded.
  bool _modelLoaded = false;

  /// Wheather the microphone permission is granted or not.
  ///
  /// [listen] cannot be called until permission is given.
  bool _hasMicPermission = false;

  /// Indicates wheather the service is listening and transcribing audio.
  ///
  /// Set to [true] after listen is called.
  ///
  /// Calling [listen] while [_isListening] is true won't have any effect.
  /// Calling [stop] while [_isListening] is false won't have any effect.
  bool _isListening = false;

  /// Load models using the specified asset path.
  ///
  /// [modelName] - Name of the .tflite model in the app's external files directory.
  /// [scorerName] - Name of the .scorer file in the app's external files directory.
  ///
  /// Make sure the model and scorer files are copied to the app's external files
  /// directory before calling this method. External files directory refers to the
  /// directory obtained when calling [getExternalFilesDir] on Android. Using
  /// path_provider package (https://pub.dev/packages/path_provider), it refers to the
  /// directory obtained when calling [getExternalStorageDirectory].
  ///
  /// Returns [true] if the models were loaded successfully.
  /// Returns [false] otherwise.
  ///
  /// [listen] and [stop] should only be called after the models have been loaded successfully.
  /// [loadModelFromName] needs to be called again after calling [dispose] if you want to [listen] again.
  Future<bool> loadModelFromName({
    required String modelName,
    required String scorerName,
  }) async {
    if (_modelLoaded) return true;

    final params = {
      'modelName': modelName,
      'scorerName': scorerName,
    };

    return _modelLoaded =
        await _methodChannel.invokeMethod<bool>('loadModelFromName', params) ??
            false;
  }

  /// Request for the microphone permission.
  ///
  /// Returns true if the permission was granted.
  /// Returns false otherwise.
  Future<bool> requestMicPermission() async {
    return _hasMicPermission =
        await _methodChannel.invokeMethod('requestMicPermission');
  }

  /// Start listening to the audio stream.
  ///
  /// The recognized results are passed to the [onResult] callback.
  /// Any errors are passed to the [onError] callback.
  ///
  /// Throws [MicPermissionDeniedException] if microphone permission are not granted.
  ///
  /// This should be called only after [loadModelFromName] returns true.
  /// Otherwise, it won't have any effect.
  Future<void> listen({
    void Function(DeepSpeechError)? onError,
    void Function(DeepSpeechResult)? onResult,
  }) async {
    if (!_modelLoaded || _isListening) return;

    if (!_hasMicPermission) {
      await requestMicPermission();
      if (!_hasMicPermission) {
        throw const MicPermissionDeniedException(
          'Microphone permission denied!',
        );
      }
    }

    _listenEventSub = _listenEventChannel
        .receiveBroadcastStream()
        .distinct()
        .map(_parseResult)
        .listen(
      onResult,
      onDone: stop,
      onError: (error, stackTrace) {
        onError?.call(DeepSpeechError(error: error, stackTrace: stackTrace));
      },
    );

    _isListening = true;
    await _methodChannel.invokeMethod('listen');
  }

  /// Map dynamic [result] to [DeepSpeechResult].
  DeepSpeechResult _parseResult(dynamic result) {
    return DeepSpeechResult.fromMap(Map<String, dynamic>.from(result));
  }

  /// Stop listening to the audio stream.
  ///
  /// Once stopped, the final result is passed to the [onResult] callback in [listen].
  ///
  /// This should be called only after [loadModelFromName] returns true and after calling [listen].
  /// Otherwise, it won't have any effect.
  Future<void> stop() async {
    if (!_modelLoaded || !_isListening) return;

    _isListening = false;
    _listenEventSub?.cancel();
    await _methodChannel.invokeMethod('stop');
  }

  /// Free the models and resources.
  ///
  /// [loadModelFromName] needs to be called again after calling [dispose] if you want to [listen] again.
  Future<void> dispose() async {
    if (!_modelLoaded) return;

    if (_isListening) await stop();
    _modelLoaded = false;
    await _methodChannel.invokeMethod('dispose');
  }
}

class MicPermissionDeniedException implements Exception {
  final String message;

  const MicPermissionDeniedException(this.message);

  @override
  String toString() => message;
}
