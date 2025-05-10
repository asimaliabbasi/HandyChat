package com.example.handychat

import android.graphics.*
import android.os.Bundle
import android.os.SystemClock
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    private val channelName = "handychat"
    private var handLandmarker: HandLandmarker? = null
    private var imageWidth: Int = 1
    private var imageHeight: Int = 1
    private lateinit var methodChannel: MethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setupHandLandmarker()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "handMarker" -> {
                    try {
                        val landMarkers = detectHandMarks(call.arguments as Map<*, *>)
                        val resultPoints = mapPointsAndLines(landMarkers)
                        result.success(mapOf(
                            "points" to resultPoints?.points,
                            "lines" to resultPoints?.lines
                        ))
                    } catch (e: Exception) {
                        result.error("Kotlin => ", e.message, e.stackTraceToString())
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setupHandLandmarker() {
        val baseOptions = BaseOptions.builder()
            .setDelegate(Delegate.CPU) // Change to GPU if required
            .setModelAssetPath(MP_HAND_LANDMARKER_TASK)
            .build()

        val options = HandLandmarker.HandLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setMinHandDetectionConfidence(DEFAULT_HAND_DETECTION_CONFIDENCE.toFloat())
            .setMinTrackingConfidence(DEFAULT_HAND_TRACKING_CONFIDENCE.toFloat())
            .setMinHandPresenceConfidence(DEFAULT_HAND_PRESENCE_CONFIDENCE.toFloat())
            .setNumHands(DEFAULT_NUM_HANDS)
            .setResultListener { result, image -> returnLivestreamResult(result, image) }
            .setErrorListener { error -> returnLivestreamError(error) }
            .setRunningMode(RunningMode.LIVE_STREAM)
            .build()

        handLandmarker = HandLandmarker.createFromOptions(this, options)
    }

    private fun detectHandMarks(arguments: Map<*, *>): List<HandLandmarkerResult>? {
        val bytes = arguments["bytes"] as ByteArray
        val width = arguments["width"] as Int
        val height = arguments["height"] as Int
        val isFrontCamera = arguments["isFrontCamera"] as Boolean // Receive flag

        val bitmap = decodeYUV420ToBitmap(bytes, width, height) ?: return null

        val rotatedBitmap = if (isFrontCamera) {
            rotateBitmap(bitmap, 90f) // Change rotation for front camera
        } else {
            rotateBitmap(bitmap, -90f)
        }

        val mirroredBitmap = mirrorBitmap(rotatedBitmap) // Keep mirroring logic

        val mpImage = BitmapImageBuilder(mirroredBitmap).build()
        val frameTime = SystemClock.uptimeMillis()

        imageWidth = mirroredBitmap.width
        imageHeight = mirroredBitmap.height

        handLandmarker?.detectAsync(mpImage, frameTime)
        return null
    }


    private fun returnLivestreamResult(result: HandLandmarkerResult, image: MPImage) {
        val resultPoints = mapPointsAndLines(listOf(result))
        runOnUiThread {
            methodChannel.invokeMethod(
                "handLandmarkerResult", mapOf(
                    "points" to resultPoints?.points,
                    "lines" to resultPoints?.lines
                )
            )
        }
    }

    private fun returnLivestreamError(error: RuntimeException) {
        runOnUiThread {
            methodChannel.invokeMethod("handLandmarkerError", error.message)
        }
    }

    private fun mapPointsAndLines(handMarks: List<HandLandmarkerResult>?): ResultPoints? {
        if (handMarks == null) return null
        val points = mutableListOf<List<Float>>()
        val lines = mutableListOf<List<List<Float>>>()

        for (handMark in handMarks) {
            for (landmark in handMark.landmarks()) {
                val tempPoints = mutableListOf<List<Float>>()
                for (normalizedLandmark in landmark) {
                    val x = normalizedLandmark.x() * imageWidth
                    val y = normalizedLandmark.y() * imageHeight
                    tempPoints.add(listOf(x, y))
                }
                points.addAll(tempPoints)

                HandLandmarker.HAND_CONNECTIONS?.let { connections ->
                    for (connection in connections) {
                        val startIndex = connection.start()
                        val endIndex = connection.end()
                        if (startIndex < tempPoints.size && endIndex < tempPoints.size) {
                            val start = tempPoints[startIndex]
                            val end = tempPoints[endIndex]
                            lines.add(listOf(start, end))
                        }
                    }
                }
            }
        }

        return ResultPoints(points, lines)
    }

    private fun decodeYUV420ToBitmap(data: ByteArray, width: Int, height: Int): Bitmap? {
        return try {
            val yuvImage = YuvImage(data, ImageFormat.NV21, width, height, null)
            val out = ByteArrayOutputStream()
            yuvImage.compressToJpeg(Rect(0, 0, width, height), 100, out)
            val jpegData = out.toByteArray()
            val originalBitmap = BitmapFactory.decodeByteArray(jpegData, 0, jpegData.size)

            // Flip the bitmap horizontally to fix the mirrored issue
            val matrix = Matrix().apply {
                preScale(-1f, 1f)
            }
            Bitmap.createBitmap(originalBitmap, 0, 0, originalBitmap.width, originalBitmap.height, matrix, true)
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }


    private fun rotateBitmap(source: Bitmap, angle: Float): Bitmap {
        val matrix = Matrix()
        matrix.postRotate(angle)
        return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
    }

    private fun mirrorBitmap(source: Bitmap): Bitmap {
        val matrix = Matrix()
        matrix.preScale(-1f, 1f)
        return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
    }

    companion object {
        private const val MP_HAND_LANDMARKER_TASK = "hand_landmarker.task"
        private const val DEFAULT_HAND_DETECTION_CONFIDENCE = 0.5F
        private const val DEFAULT_HAND_TRACKING_CONFIDENCE = 0.5F
        private const val DEFAULT_HAND_PRESENCE_CONFIDENCE = 0.5F
        private const val DEFAULT_NUM_HANDS = 1
    }

    data class ResultPoints(
        val points: List<List<Float>>,
        val lines: List<List<List<Float>>>
    )
}
