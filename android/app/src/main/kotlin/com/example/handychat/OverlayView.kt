package com.example.handychat

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.AttributeSet
import android.view.View
import androidx.core.content.ContextCompat
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import kotlin.math.max
import kotlin.math.min

class OverlayView(context: Context?, attrs: AttributeSet?) : View(context, attrs) {

    private var results: HandLandmarkerResult? = null
    private val linePaint = Paint()
    private val pointPaint = Paint()
    private var scaleFactor: Float = 1f
    private var imageWidth: Int = 1
    private var imageHeight: Int = 1

    init {
        initPaints()
    }

    fun clear() {
        results = null
        invalidate()  // Simply call invalidate, no need to reset Paints
    }

    private fun initPaints() {
        context?.let { ctx ->
            linePaint.color = ContextCompat.getColor(ctx, R.color.mp_color_primary)
        } ?: run {
            linePaint.color = Color.RED  // Default color if context is null
        }

        linePaint.strokeWidth = LANDMARK_STROKE_WIDTH
        linePaint.style = Paint.Style.STROKE

        pointPaint.color = Color.YELLOW
        pointPaint.strokeWidth = LANDMARK_STROKE_WIDTH
        pointPaint.style = Paint.Style.FILL
    }

    override fun draw(canvas: Canvas) {
        super.draw(canvas)

        results?.let { handLandmarkerResult ->
            for (landmark in handLandmarkerResult.landmarks()) {
                for (normalizedLandmark in landmark) {
                    val x = normalizedLandmark.x() * width
                    val y = normalizedLandmark.y() * height
                    canvas.drawPoint(x, y, pointPaint)
                }

                HandLandmarker.HAND_CONNECTIONS.forEach { connection ->
                    connection?.let {
                        val start = landmark[it.start()]
                        val end = landmark[it.end()]

                        val startX = start.x() * width
                        val startY = start.y() * height
                        val endX = end.x() * width
                        val endY = end.y() * height

                        canvas.drawLine(startX, startY, endX, endY, linePaint)
                    }
                }
            }
        }
    }

    fun setResults(
        handLandmarkerResults: HandLandmarkerResult,
        imageHeight: Int,
        imageWidth: Int,
        runningMode: RunningMode = RunningMode.IMAGE
    ) {
        results = handLandmarkerResults
        this.imageHeight = imageHeight
        this.imageWidth = imageWidth

        scaleFactor = when (runningMode) {
            RunningMode.IMAGE, RunningMode.VIDEO -> {
                min(width.toFloat() / imageWidth, height.toFloat() / imageHeight)
            }
            RunningMode.LIVE_STREAM -> {
                max(width.toFloat() / imageWidth, height.toFloat() / imageHeight)
            }
        }
        invalidate()
    }

    companion object {
        private const val LANDMARK_STROKE_WIDTH = 8F
    }
}
