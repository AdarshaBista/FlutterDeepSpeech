import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:path_provider/path_provider.dart';
import 'package:flutter_deep_speech/flutter_deep_speech.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const tfliteName = 'model.tflite';
  static const scorerName = 'scorer.scorer';

  final FlutterDeepSpeech deepSpeech = FlutterDeepSpeech();

  String text = 'Press and hold to start listening. Let go to stop.';
  bool modelLoaded = false;
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  @override
  void dispose() {
    deepSpeech.dispose();
    super.dispose();
  }

  Future<void> loadModel() async {
    // The models must be copied to the external files directory first.
    await copyModelsToExternalFilesDir();

    modelLoaded = await deepSpeech.loadModelFromName(
      modelName: 'model.tflite',
      scorerName: 'scorer.scorer',
    );
    debugPrint('MODEL LOADED: $modelLoaded');
  }

  Future<void> copyModelsToExternalFilesDir() async {
    final externalFilesDirPath = (await getExternalStorageDirectory())!.path;

    final tfliteDestination = '$externalFilesDirPath/$tfliteName';
    if (!File(tfliteDestination).existsSync()) {
      await copyBytesFromAsset('assets/models/$tfliteName', tfliteDestination);
    }

    final scorerDestination = '$externalFilesDirPath/$scorerName';
    if (!File(scorerDestination).existsSync()) {
      await copyBytesFromAsset('assets/models/$scorerName', scorerDestination);
    }
  }

  Future<void> copyBytesFromAsset(String source, String dest) async {
    final bytes = await rootBundle.load(source);
    final file = await File(dest).writeAsBytes(bytes.buffer.asUint8List());
    debugPrint('Copied $source to ${file.path}');
  }

  Future<void> start() async {
    if (!modelLoaded) {
      debugPrint('ERROR: Model has not been loaded yet!');
      return;
    }

    debugPrint('START LISTENING...');
    setState(() {
      text = 'Go ahead. I\'m listening...';
      isListening = true;
    });

    try {
      await deepSpeech.listen(
        onError: (error) {
          debugPrint('ERROR: ${error.error}');
          debugPrint('STACKTRACE: ${error.stackTrace}');
        },
        onResult: (result) {
          setState(() => text = result.text);
        },
      );
    } on MicPermissionDeniedException catch (e) {
      debugPrint('Error: ${e.toString()}');
      setState(() {
        text = 'Permission denied!';
        isListening = false;
      });
    }
  }

  Future<void> stop() async {
    debugPrint('STOP LISTENING...');
    setState(() => isListening = false);
    await deepSpeech.stop();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter DeepSpeech'),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 24.0),
                ),
              ),
              const Spacer(),
              Listener(
                onPointerUp: (_) => stop(),
                onPointerDown: (_) => start(),
                onPointerCancel: (_) => stop(),
                child: Container(
                  width: 100.0,
                  height: 100.0,
                  decoration: BoxDecoration(
                    color: isListening ? Colors.red : Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      isListening ? 'STOP' : 'START',
                      style: const TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }
}
