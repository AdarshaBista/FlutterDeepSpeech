package com.adrsh.flutter_deep_speech

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FlutterDeepSpeechPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var listenEventChannel: EventChannel

    private lateinit var deepSpeechService: DeepSpeechService
    private lateinit var permissionsHandler: PermissionsHandler

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        permissionsHandler = PermissionsHandler()
        permissionsHandler.context = flutterPluginBinding.applicationContext

        deepSpeechService = DeepSpeechService()
        deepSpeechService.context = flutterPluginBinding.applicationContext

        methodChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "adrsh/flutter_deep_speech"
        )
        methodChannel.setMethodCallHandler(this)

        listenEventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "adrsh/flutter_deep_speech/listen"
        )
        listenEventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        listenEventChannel.setStreamHandler(null)
        permissionsHandler.dispose()
        deepSpeechService.dispose()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        deepSpeechService.activity = binding.activity
        permissionsHandler.activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        deepSpeechService.activity = null
        permissionsHandler.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        deepSpeechService.activity = binding.activity
        permissionsHandler.activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        deepSpeechService.activity = null
        permissionsHandler.activity = null
    }

    override fun onListen(o: Any?, sink: EventSink) {
        deepSpeechService.listenEventSink = sink
    }

    override fun onCancel(o: Any?) {
        deepSpeechService.listenEventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        deepSpeechService.result = result
        when (call.method) {
            "loadModelFromName" -> {
                val modelName = call.argument<String>("modelName")
                val scorerName = call.argument<String>("scorerName")

                if (modelName.isNullOrBlank() || scorerName.isNullOrBlank()) {
                    result.success(false)
                    return
                }

                deepSpeechService.loadModelFromName(modelName, scorerName)
            }
            "requestMicPermission" -> permissionsHandler.requestMicPermission(result)
            "listen" -> deepSpeechService.listen()
            "stop" -> deepSpeechService.stop()
            "dispose" -> deepSpeechService.dispose()
            else -> result.notImplemented()
        }
    }
}