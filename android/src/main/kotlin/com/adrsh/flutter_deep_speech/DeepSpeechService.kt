package com.adrsh.flutter_deep_speech

import android.app.Activity
import android.content.Context
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log

import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodChannel.Result

import org.deepspeech.libdeepspeech.DeepSpeechModel

import java.io.File
import java.util.concurrent.atomic.AtomicBoolean

class DeepSpeechService {
    private val logTag = "DeepSpeechService"

    var context: Context? = null
    var activity: Activity? = null
    var result: Result? = null
    var listenEventSink: EventSink? = null

    private lateinit var model: DeepSpeechModel
    private var transcriptionThread: Thread? = null
    private var isRecording: AtomicBoolean = AtomicBoolean(false)

    private fun logError(message: String) {
        Log.e(logTag, message)
    }

    fun loadModelFromName(modelName: String, scorerName: String) {
        if (context == null) {
            logError("Context is not available yet!")
            result?.success(false)
            return
        }

        val modelsPath = context!!.getExternalFilesDir(null).toString()
        val tflitePath = "$modelsPath/$modelName"
        val scorerPath = "$modelsPath/$scorerName"

        for (path in listOf(tflitePath, scorerPath)) {
            if (!File(path).exists()) {
                logError("Model loading failed: $path does not exist!")
                result?.success(false)
                return
            }
        }

        model = DeepSpeechModel(tflitePath)
        model.enableExternalScorer(scorerPath)

        result?.success(true)
    }

    fun listen() {
        if (isRecording.compareAndSet(false, true)) {
            transcriptionThread = Thread({ transcribe() }, "TranscriptionThread")
            transcriptionThread?.start()
        }
    }

    fun stop() {
        isRecording.set(false)
    }

    fun dispose() {
        model.freeModel()
        context = null
        activity = null
        result = null
        listenEventSink = null
    }

    private fun transcribe() {
        val audioBufferSize = 2048
        val audioData = ShortArray(audioBufferSize)

        model.let { model ->
            val streamContext = model.createStream()
            val recorder = AudioRecord(
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                model.sampleRate(),
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                audioBufferSize
            )
            recorder.startRecording()

            while (isRecording.get()) {
                recorder.read(audioData, 0, audioBufferSize)
                model.feedAudioContent(streamContext, audioData, audioData.size)

                val decodedText = model.intermediateDecode(streamContext)
                sendListenResult(decodedText, false)
            }

            val decodedText = model.finishStream(streamContext)
            sendListenResult(decodedText, true)

            recorder.stop()
            recorder.release()
        }
    }

    private fun sendListenResult(decodedText: String, isFinal: Boolean) {
        val resultsMap: HashMap<String, Any> = HashMap()
        resultsMap["text"] = decodedText
        resultsMap["isFinal"] = isFinal
        activity?.runOnUiThread { listenEventSink?.success(resultsMap) }
    }
}