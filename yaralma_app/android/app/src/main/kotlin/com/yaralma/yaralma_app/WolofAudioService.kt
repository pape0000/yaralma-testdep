package com.yaralma.yaralma_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.IBinder
import android.util.Base64
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream
import java.net.HttpURLConnection
import java.net.URL

/**
 * Foreground Service for real-time Wolof audio monitoring.
 * Captures audio from YouTube/Netflix and sends to ASR for transcription.
 */
class WolofAudioService : Service() {

    private var mediaProjection: MediaProjection? = null
    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    companion object {
        const val CHANNEL_ID = "wolof_guardian_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "com.yaralma.START_AUDIO_CAPTURE"
        const val ACTION_STOP = "com.yaralma.STOP_AUDIO_CAPTURE"
        const val EXTRA_RESULT_CODE = "resultCode"
        const val EXTRA_RESULT_DATA = "resultData"

        private const val SAMPLE_RATE = 16000
        private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
        private const val CHUNK_DURATION_MS = 3000 // 3 seconds per chunk
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, -1)
                val resultData = intent.getParcelableExtra<Intent>(EXTRA_RESULT_DATA)
                if (resultCode != -1 && resultData != null) {
                    startForeground(NOTIFICATION_ID, createNotification())
                    startAudioCapture(resultCode, resultData)
                }
            }
            ACTION_STOP -> {
                stopAudioCapture()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Wolof Guardian",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Real-time audio monitoring for content protection"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Wolof Guardian Active")
            .setContentText("Monitoring audio for inappropriate content")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }

    private fun startAudioCapture(resultCode: Int, resultData: Intent) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            // Audio capture requires Android 10+
            return
        }

        try {
            val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            mediaProjection = projectionManager.getMediaProjection(resultCode, resultData)

            val config = AudioPlaybackCaptureConfiguration.Builder(mediaProjection!!)
                .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
                .build()

            val bufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)

            audioRecord = AudioRecord.Builder()
                .setAudioPlaybackCaptureConfig(config)
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AUDIO_FORMAT)
                        .setSampleRate(SAMPLE_RATE)
                        .setChannelMask(CHANNEL_CONFIG)
                        .build()
                )
                .setBufferSizeInBytes(bufferSize * 2)
                .build()

            isRecording = true
            audioRecord?.startRecording()

            // Start processing audio chunks
            serviceScope.launch {
                processAudioStream()
            }
        } catch (e: Exception) {
            e.printStackTrace()
            stopSelf()
        }
    }

    private suspend fun processAudioStream() {
        val bufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)
        val buffer = ShortArray(bufferSize)
        val chunkBuffer = ByteArrayOutputStream()
        val samplesPerChunk = (SAMPLE_RATE * CHUNK_DURATION_MS) / 1000

        var samplesCollected = 0

        while (isRecording && audioRecord?.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
            val read = audioRecord?.read(buffer, 0, bufferSize) ?: 0
            if (read > 0) {
                // Convert shorts to bytes
                for (i in 0 until read) {
                    chunkBuffer.write(buffer[i].toInt() and 0xFF)
                    chunkBuffer.write((buffer[i].toInt() shr 8) and 0xFF)
                }
                samplesCollected += read

                // Process chunk when we have enough samples
                if (samplesCollected >= samplesPerChunk) {
                    val audioData = chunkBuffer.toByteArray()
                    chunkBuffer.reset()
                    samplesCollected = 0

                    // Process in background
                    launch {
                        processAudioChunk(audioData)
                    }
                }
            }
        }
    }

    private suspend fun processAudioChunk(audioData: ByteArray) {
        try {
            val prefs = getSharedPreferences("yaralma_override", Context.MODE_PRIVATE)
            val apiUrl = prefs.getString("wolof_api_url", null) ?: return

            // Convert to WAV format with header
            val wavData = createWavFile(audioData, SAMPLE_RATE, 1, 16)
            val base64Audio = Base64.encodeToString(wavData, Base64.NO_WRAP)

            // Send to transcription API
            val transcription = transcribeAudio(apiUrl, base64Audio) ?: return

            // Check for blocked content
            val shouldMute = checkForBlockedContent(apiUrl, transcription)

            if (shouldMute) {
                triggerMute()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun transcribeAudio(apiUrl: String, audioBase64: String): String? {
        return try {
            val url = URL("$apiUrl/api/wolof-transcribe")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.doOutput = true

            val body = """{"audioBase64":"$audioBase64"}"""
            connection.outputStream.write(body.toByteArray())

            if (connection.responseCode == 200) {
                val response = connection.inputStream.bufferedReader().readText()
                // Simple JSON parsing
                val match = Regex(""""transcription"\s*:\s*"([^"]+)"""").find(response)
                match?.groupValues?.get(1)
            } else null
        } catch (e: Exception) {
            null
        }
    }

    private fun checkForBlockedContent(apiUrl: String, transcription: String): Boolean {
        return try {
            val url = URL("$apiUrl/api/wolof-check")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.doOutput = true

            val body = """{"transcription":"$transcription"}"""
            connection.outputStream.write(body.toByteArray())

            if (connection.responseCode == 200) {
                val response = connection.inputStream.bufferedReader().readText()
                response.contains(""""shouldMute"\s*:\s*true""".toRegex())
            } else false
        } catch (e: Exception) {
            false
        }
    }

    private fun triggerMute() {
        // Set mute flag in SharedPreferences
        val prefs = getSharedPreferences("yaralma_override", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("audio_muted", true).apply()

        // Broadcast to accessibility service
        val intent = Intent("com.yaralma.MUTE_AUDIO")
        sendBroadcast(intent)

        // Auto-unmute after 5 seconds
        serviceScope.launch {
            delay(5000)
            prefs.edit().putBoolean("audio_muted", false).apply()
            sendBroadcast(Intent("com.yaralma.UNMUTE_AUDIO"))
        }
    }

    private fun createWavFile(pcmData: ByteArray, sampleRate: Int, channels: Int, bitsPerSample: Int): ByteArray {
        val byteRate = sampleRate * channels * bitsPerSample / 8
        val blockAlign = channels * bitsPerSample / 8
        val dataSize = pcmData.size
        val fileSize = 36 + dataSize

        val header = ByteArray(44)
        // RIFF header
        header[0] = 'R'.code.toByte()
        header[1] = 'I'.code.toByte()
        header[2] = 'F'.code.toByte()
        header[3] = 'F'.code.toByte()
        writeInt(header, 4, fileSize)
        header[8] = 'W'.code.toByte()
        header[9] = 'A'.code.toByte()
        header[10] = 'V'.code.toByte()
        header[11] = 'E'.code.toByte()
        // fmt chunk
        header[12] = 'f'.code.toByte()
        header[13] = 'm'.code.toByte()
        header[14] = 't'.code.toByte()
        header[15] = ' '.code.toByte()
        writeInt(header, 16, 16) // chunk size
        writeShort(header, 20, 1) // PCM format
        writeShort(header, 22, channels.toShort())
        writeInt(header, 24, sampleRate)
        writeInt(header, 28, byteRate)
        writeShort(header, 32, blockAlign.toShort())
        writeShort(header, 34, bitsPerSample.toShort())
        // data chunk
        header[36] = 'd'.code.toByte()
        header[37] = 'a'.code.toByte()
        header[38] = 't'.code.toByte()
        header[39] = 'a'.code.toByte()
        writeInt(header, 40, dataSize)

        return header + pcmData
    }

    private fun writeInt(data: ByteArray, offset: Int, value: Int) {
        data[offset] = (value and 0xFF).toByte()
        data[offset + 1] = ((value shr 8) and 0xFF).toByte()
        data[offset + 2] = ((value shr 16) and 0xFF).toByte()
        data[offset + 3] = ((value shr 24) and 0xFF).toByte()
    }

    private fun writeShort(data: ByteArray, offset: Int, value: Short) {
        data[offset] = (value.toInt() and 0xFF).toByte()
        data[offset + 1] = ((value.toInt() shr 8) and 0xFF).toByte()
    }

    private fun stopAudioCapture() {
        isRecording = false
        serviceScope.cancel()
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
        mediaProjection?.stop()
        mediaProjection = null
    }

    override fun onDestroy() {
        stopAudioCapture()
        super.onDestroy()
    }
}
