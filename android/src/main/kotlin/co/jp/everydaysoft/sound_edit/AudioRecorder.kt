import android.content.Context
import android.media.MediaRecorder
import android.util.Log
import java.io.File
import java.io.IOException
import java.nio.file.Paths.get
import kotlin.io.path.pathString

class AudioRecorder(private val context: Context) {
    private var recorder: MediaRecorder? = null
    private val Log_Tag = "AudioRecorder"

    fun recordStart(path: String) {
        val file = getFlutterAssetsDirectory(context)
        val fileName = get(file.path, path)
        @Suppress("DEPRECATION")
        MediaRecorder().apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)
            setOutputFile(fileName.pathString)
            setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB)
            try {
                prepare()
            } catch (e: IOException) {
                Log.e(Log_Tag, "prepare() failed")
            }
            start()
        }.also { recorder = it }
    }

    private fun getFlutterAssetsDirectory(context: Context): File {
        val appDir = context.filesDir
        val path = appDir.path.split("files").first()
        return File("${path}/app_flutter/")
    }

    fun recordStop() {
        recorder?.apply {
            stop()
            release()
        }
        recorder = null
    }
}
