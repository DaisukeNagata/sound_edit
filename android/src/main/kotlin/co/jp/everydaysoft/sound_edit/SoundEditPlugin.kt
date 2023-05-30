package co.jp.everydaysoft.sound_edit

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import AudioRecorder
import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.media.MediaMetadataRetriever
import android.media.MediaPlayer
import android.net.Uri
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.arthenica.mobileffmpeg.Config
import com.arthenica.mobileffmpeg.ExecuteCallback
import com.arthenica.mobileffmpeg.FFmpeg
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.IOException
import java.nio.file.Paths
import kotlin.io.path.nameWithoutExtension
import kotlin.io.path.pathString


/** SoundEditPlugin */
class SoundEditPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener,
    PluginRegistry.ActivityResultListener {
    private var permissionRequestCode: Int = 12345
    private var isMediaPlayingFlg = true
    private var mediaPlayer = MediaPlayer()
    private var activity: Activity? = null
    private lateinit var audioRecorder: AudioRecorder
    private lateinit var player: AudioTrack
    private lateinit var context: Context
    private lateinit var musicChanelMusic: MethodChannel
    private lateinit var musicChanelNameTrim: MethodChannel
    private lateinit var musicChanelNameDrag: MethodChannel
    private lateinit var musicChanelNameRecord: MethodChannel

    companion object {
        private const val SamplingRate = 44100
        private const val METHOD_CHANNEL_NAME_MUSIC = "co.jp.everydaysoft.sound_edit/music"
        private const val METHOD_CHANNEL_NAME_TRIM = "co.jp.everydaysoft.sound_edit/trim"
        private const val METHOD_CHANNEL_NAME_DRAG = "co.jp.everydaysoft.sound_edit/drag"
        private const val METHOD_CHANNEL_NAME_RECORD = "co.jp.everydaysoft.sound_edit/record"
        const val METHOD_PAUSE = "audioPause"
        const val METHOD_STOP = "audioStop"
        const val METHOD_RECORD_STOP = "recordStop"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {

        context = flutterPluginBinding.applicationContext
        player = truck()
        audioRecorder = AudioRecorder(flutterPluginBinding.applicationContext)

        musicChanelMusic =
            MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME_MUSIC)
        musicChanelMusic.setMethodCallHandler(this)

        musicChanelNameTrim =
            MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME_TRIM)
        musicChanelNameTrim.setMethodCallHandler(this)

        musicChanelNameDrag =
            MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME_DRAG)
        musicChanelNameDrag.setMethodCallHandler(this)

        musicChanelNameRecord =
            MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL_NAME_RECORD)
        musicChanelNameRecord.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            METHOD_PAUSE -> {
                mediaPlayer.pause()
                isMediaPlayingFlg = false
            }

            METHOD_STOP -> {
                audioStop()
            }

            METHOD_RECORD_STOP -> {
                audioRecorder.recordStop()
                result.success("")
            }

            else -> {
                if (call.method.contains("play")) {
                    val word = call.method.replace("play/", "")
                    if (isMediaPlayingFlg) {
                        audioPlay(word, onCompleted = {
                            result.success("")
                        })
                    } else {
                        isMediaPlayingFlg = true
                        mediaPlayer.start()
                    }
                } else if (call.method.contains("drag")) {
                    val word = call.method.replace("drag/", "")
                    val pathList = word.split(",").map { it.trim() }
                    if (checkIfFileExists(
                            context,
                            pathList.last()
                        ) || pathList.size == 4 || pathList.last() == ".wav"
                    ) {
                        result.success(1.0)
                        return
                    }
                    val callback =
                        ExecuteCallback { _, returnCode ->
                            if (returnCode == Config.RETURN_CODE_SUCCESS) {
                                print(returnCode)
                            } else {
                                print(returnCode)
                            }
                        }
                    val requestList = convertAudioFiles(
                        context,
                        word,
                        callback
                    )
                    CoroutineScope(Dispatchers.Main).launch {
                        try {
                            val duration =
                                withContext(Dispatchers.IO) {
                                    getTotalDurationFromFilePaths(
                                        requestList
                                    )
                                }
                            result.success(duration)
                        } catch (e: Exception) {
                            result.success(1.0)
                        }
                    }
                } else if (call.method.contains("trim")) {
                    val word = call.method.replace("trim/", "")
                    val pathSplit =
                        word.split(",").mapNotNull { it.trim().toDoubleOrNull() }
                    val nonDoubleStrings =
                        word.split(",").filter { it.trim().toDoubleOrNull() == null }
                            .map { it.trim() }
                    val nonDoubleStringsAsOneString = nonDoubleStrings.joinToString(separator = ",")
                    val callback =
                        ExecuteCallback { _, returnCode ->
                            if (returnCode == Config.RETURN_CODE_SUCCESS) {
                                print(returnCode)
                            } else {
                                print(returnCode)
                            }
                        }
                    val requestList = convertAndMergeAudioFiles(
                        context,
                        nonDoubleStringsAsOneString,
                        pathSplit.first(),
                        pathSplit.last(),
                        callback,
                    )
                    CoroutineScope(Dispatchers.Main).launch {
                        try {
                            val duration =
                                withContext(Dispatchers.IO) {
                                    getTotalDurationFromFilePaths(
                                        arrayOf(requestList)
                                    )
                                }
                            result.success(duration)
                        } catch (e: Exception) {
                            result.success(0.0)
                        }
                    }

                } else if (call.method == "recordStop" ) {
                    audioRecorder.recordStop()
                    result.success("")
                } else {
                    audioRecorder.recordStart(call.method)
                }
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)

        // Check permission here and request if not granted
        if (ContextCompat.checkSelfPermission(
                binding.activity,
                Manifest.permission.RECORD_AUDIO
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                binding.activity,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                permissionRequestCode
            )
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        this.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray

    )
            : Boolean {
        return true
    }

    override fun onActivityResult(
        requestCode: Int, resultCode: Int, data: Intent?
    )
            : Boolean {
        return false
    }

    private fun convertAndMergeAudioFiles(
        context: Context,
        inputFilePaths: String,
        startTime: Double,
        endTime: Double,
        callback: ExecuteCallback
    ): String {
        val pathSplit = inputFilePaths.split(",").map { it.trim() }
        val lastIndex = pathSplit.last()
        val pathSplitFiltered = pathSplit.dropLast(1)
        val outputFiles = Array(size = pathSplitFiltered.size) { "" }
        try {
            for (i in pathSplitFiltered.indices) {
                val file = getFlutterAssetsDirectory(context)
                val filePath = Paths.get(file.path, pathSplitFiltered[i])
                val inputFile = filePath.toFile()

                if (!inputFile.exists() || !inputFile.canRead()) {
                    throw Exception("Input file does not exist or cannot be read.")
                }
                val tempOutputFile =
                    File(
                        inputFile.parent,
                        "${inputFile.nameWithoutExtension}_converted.wav"
                    )

                val command = arrayOf(
                    "-y",
                    "-i",
                    inputFile.path,
                    "-ar",
                    SamplingRate.toString(),
                    "-ab",
                    "${AudioFormat.ENCODING_PCM_16BIT}k",
                    "-c:a",
                    "pcm_s16le",
                    "-ac",
                    "2",
                    tempOutputFile.path,
                )
                FFmpeg.execute(command)

                tempOutputFile.copyTo(inputFile, overwrite = true)
                tempOutputFile.delete()

                if (inputFile.path != "") {
                    outputFiles[i] = inputFile.path
                }
            }

            // Merge converted files
            val file = getFlutterAssetsDirectory(context)
            val mergedFile = Paths.get(file.path, lastIndex)
            val mergeCommand = mutableListOf<String>()
            mergeCommand.add("-y")
            outputFiles.forEach { mergeCommand.addAll(listOf("-i", it)) }
            mergeCommand.addAll(
                listOf(
                    "-filter_complex",
                    "concat=n=${outputFiles.size}:v=0:a=1",
                    "-vn",
                    mergedFile.pathString
                )
            )
            FFmpeg.execute(mergeCommand.toTypedArray())

            // After merging, trim the merged file from startTime to endTime
            val tempTrimmedFile =
                File(file.path, "${mergedFile.nameWithoutExtension}_trimmed.wav")
            val startTimeString = String.format("%.3f", startTime * 0.01)
            val endTimeString = String.format(
                "%.3f",
                (endTime - startTime) * 0.01
            ) // Here, the duration should be passed instead of end time
            val trimCommand = arrayOf(
                "-y",
                "-i",
                mergedFile.pathString,
                "-ss",
                startTimeString,
                "-t",
                endTimeString,
                tempTrimmedFile.absolutePath
            )
            FFmpeg.execute(trimCommand)

            // Overwrite the original merged file with the trimmed file
            tempTrimmedFile.copyTo(mergedFile.toFile(), overwrite = true)
            tempTrimmedFile.delete()

            return mergedFile.pathString
        } catch (e: Exception) {
            callback.apply(-1, Config.RETURN_CODE_CANCEL)
            e.printStackTrace()
            return ""
        }
    }

    private fun convertAudioFiles(
        context: Context,
        inputFilePaths: String,
        callback: ExecuteCallback
    )

            : Array<String> {
        val pathSplit = inputFilePaths.split(",").map { it.trim() }
        val outputFiles = Array(pathSplit.size) { "" }
        try {
            for (i in pathSplit.indices) {
                val file = getFlutterAssetsDirectory(context)
                val filePath = Paths.get(file.path, pathSplit[i])
                val inputFile = File(filePath.pathString)
                if (!inputFile.exists() || !inputFile.canRead()) {
                    throw Exception("Input file does not exist or cannot be read.")
                }

                val command = arrayOf(
                    "-y",
                    "-i",
                    inputFile.path,
                    "-ar",
                    SamplingRate.toString(),
                    "-ab",
                    "${AudioFormat.ENCODING_PCM_16BIT}k",
                    "-c:a",
                    "pcm_s16le",
                    "-ac",
                    "2",
                    inputFile.path
                )
                FFmpeg.executeAsync(command, callback)
                outputFiles[i] = inputFile.path
            }
        } catch (e: Exception) {
            callback.apply(-1, Config.RETURN_CODE_CANCEL)
        }
        return outputFiles
    }

    private fun getFlutterAssetsDirectory(context: Context)
            : File {
        val appDir = context.filesDir
        val path = appDir.path.split("files").first()
        return File("${path}/app_flutter/")
    }

    private fun checkIfFileExists(context: Context, fileName: String)
            : Boolean {
        val appDir = context.filesDir
        val path = appDir.path.split("files").first()
        val file = File("${path}/app_flutter/$fileName")
        return file.exists()
    }

    private fun truck(): AudioTrack {
        val bufSize: Int = AudioTrack.getMinBufferSize(
            SamplingRate,
            AudioFormat.CHANNEL_OUT_STEREO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        return AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(SamplingRate)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_STEREO)
                    .build()
            )
            .setBufferSizeInBytes(bufSize)
            .setTransferMode(AudioTrack.MODE_STREAM)
            .build()
    }

    private fun audioPlay(
        path: String, onCompleted: ()
        -> Unit
    ) {
        val file = getFlutterAssetsDirectory(context)
        val filePath = Paths.get(file.path, path)
        mediaPlayer.apply {
            try {
                setDataSource(context, Uri.parse(filePath.pathString))
                prepare()
                start()
                setOnCompletionListener {
                    Log.d("debug", "end of audio")
                    reset()
                    audioStop()
                    onCompleted()
                }
            } catch (e: IOException) {
                Log.e("IOException", "prepare() failed")
            }
        }
    }

    private fun audioStop() {
        mediaPlayer.apply {
            this.stop()
            this.reset()
            this.release()
            mediaPlayer = MediaPlayer()
        }
    }

    private suspend fun getTotalDurationFromFilePaths(filePaths: Array<String>): Double {
        return coroutineScope {
            val durationDeferred = filePaths.map { filePath ->
                async {
                    val fileUri = Uri.fromFile(File(filePath))
                    getAudioDuration(fileUri)
                }
            }
            val durations = durationDeferred.map { it.await() }
            durations.sum()
        }
    }

    private fun getAudioDuration(uri: Uri): Double {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(context, uri)
            val durationStr =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            val durationMs = durationStr?.toLong() ?: 0L
            durationMs.toDouble() / 1000.0
        } catch (e: IllegalArgumentException) {
            0.0
        } finally {
            retriever.release()
        }
    }
}

