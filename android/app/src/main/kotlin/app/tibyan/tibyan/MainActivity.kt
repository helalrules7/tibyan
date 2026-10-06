package app.tibyan.tibyan

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// AudioServiceActivity keeps one Flutter engine for the app and the
// background recitation service.
class MainActivity : AudioServiceActivity() {
    private var pendingSave: Pair<List<String>, MethodChannel.Result>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // «Save to Photos» for shared verse pictures: Pictures/Tibyan,
        // through MediaStore (no permission from Android 10 on).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.tibyan/photos")
            .setMethodCallHandler { call, result ->
                if (call.method != "saveImages") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val paths = call.argument<List<String>>("paths") ?: emptyList()
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
                    checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
                    PackageManager.PERMISSION_GRANTED
                ) {
                    pendingSave = paths to result
                    requestPermissions(
                        arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                        SAVE_REQUEST,
                    )
                    return@setMethodCallHandler
                }
                saveAll(paths, result)
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != SAVE_REQUEST) return
        val (paths, result) = pendingSave ?: return
        pendingSave = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            saveAll(paths, result)
        } else {
            result.success(false)
        }
    }

    private fun saveAll(paths: List<String>, result: MethodChannel.Result) {
        Thread {
            val ok = try {
                paths.all { saveImage(File(it)) }
            } catch (e: Exception) {
                false
            }
            runOnUiThread { result.success(ok) }
        }.start()
    }

    private fun saveImage(file: File): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            @Suppress("DEPRECATION")
            val dir = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
                "Tibyan",
            )
            if (!dir.exists() && !dir.mkdirs()) return false
            val out = File(dir, file.name)
            file.copyTo(out, overwrite = true)
            MediaScannerConnection.scanFile(this, arrayOf(out.path), arrayOf("image/png"), null)
            return true
        }
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, file.name)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/Tibyan")
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            values,
        ) ?: return false
        contentResolver.openOutputStream(uri)?.use { out ->
            file.inputStream().use { it.copyTo(out) }
        } ?: return false
        values.clear()
        values.put(MediaStore.Images.Media.IS_PENDING, 0)
        contentResolver.update(uri, values, null, null)
        return true
    }

    private companion object {
        const val SAVE_REQUEST = 7301
    }
}
