# Changelog

## 0.0.3

- Bump Flutter version to 3.7

## 0.0.2

- Bump Flutter version to 3.3

## 0.0.1

- Initial version of Flutter DeepSpeech plugin.

### Supports:
- Basic support for requesting mic permission
- Loading deepspeech models (tflite, scorer) from external files directory
- Initializing speech recognition session using microphone
- Listening and transcribing the recognized speech
- Stopping the speech recognition session

### Limitations
- Only Android is supported
- No support for transcribing audio from files
- No support for  models directly from Flutter assets
- Missing proper error handling
- Missing tests