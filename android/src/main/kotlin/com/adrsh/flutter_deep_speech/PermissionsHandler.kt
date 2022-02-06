package com.adrsh.flutter_deep_speech

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener

class PermissionsHandler : RequestPermissionsResultListener {
    var activity: Activity? = null
    var context: Context? = null

    private var result: Result? = null

    fun requestMicPermission(result: Result) {
        if (context == null || activity == null) return
        this.result = result

        if (ContextCompat.checkSelfPermission(
                context!!,
                MICROPHONE_PERMISSION
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        ActivityCompat.requestPermissions(
            activity!!,
            arrayOf(MICROPHONE_PERMISSION),
            MICROPHONE_PERMISSION_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == MICROPHONE_PERMISSION_CODE) {
            val granted =
                grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            result!!.success(granted)
            return granted
        }
        result!!.success(false)
        return false
    }

    fun dispose() {
        context = null
        activity = null
    }

    companion object {
        private const val MICROPHONE_PERMISSION_CODE = 1
        private const val MICROPHONE_PERMISSION = Manifest.permission.RECORD_AUDIO
    }
}