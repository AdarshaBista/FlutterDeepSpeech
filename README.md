# Flutter DeepSpeech

Flutter plugin for speech recognition and transcription using [DeepSpeech](https://github.com/mozilla/DeepSpeech).

## Usage

**Step 1:**

Add the plugin as a dependency in your `pubspec.yaml`
```
flutter_deep_speech:
  git:
    url: git://github.com/AdarshaBista/FlutterDeepSpeech.git
```

**Step 2:**

Add permission for microphone in `AndroidManifest.xml`
```
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

**Step 3:**
Use the plugin. See the example app for the complete usage.

**Note:**
You need to obtain a `tflite` model and `scorer` file to use the plugin. You can download the files from the [DeepSpeech](https://github.com/mozilla/DeepSpeech) repository. Once downloaded, place the files inside `assets/models/` directory of your project. The models are not loaded from the assets directory directly, but are copied to the app's external files directory first and then loaded from there (See the example app). The copying of the files is not handled by the plugin.

## Features

See the Changelog for supported features and limitations.

## References

Android version referenced from [android_mic_streaming](https://github.com/mozilla/DeepSpeech-examples/tree/r0.9/android_mic_streaming) example.
