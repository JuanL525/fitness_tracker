package com.example.fitness_flutter

import android.os.Handler
import android.os.Looper
import android.os.Bundle
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import kotlin.math.sqrt
import io.flutter.plugin.common.EventChannel

// Importaciones adicionales para GPS
import android.Manifest
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import androidx.core.app.ActivityCompat

/**
 * MainActivity: punto de entrada de la aplicación Android
 * - Extiende FlutterFragmentActivity (necesario para BiometricPrompt)
 * - Configura los Platform Channels aquí
 */
class MainActivity: FlutterFragmentActivity() {

    // PASO 1: Definir nombres de los canales (DEBE coincidir con Dart)
    private val BIOMETRIC_CHANNEL = "com.example.fitness_flutter/biometric"
    private val ACCELEROMETER_CHANNEL = "com.example.fitness_flutter/accelerometer"
    private val GPS_CHANNEL = "com.example.fitness_flutter/gps"
    
    // Constante para permisos de GPS
    private val LOCATION_PERMISSION_REQUEST_CODE = 1001

    // PASO 2: Variables para biometría
    private lateinit var executor: Executor
    private lateinit var biometricPrompt: BiometricPrompt
    private var pendingResult: MethodChannel.Result? = null

    /**
     * configureFlutterEngine: se llama al iniciar la app
     * AQUÍ configuramos TODOS los Platform Channels
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Inicializar Platform Channel de Acelerómetro
        setupAccelerometerChannel(flutterEngine)
        
        // Inicializar Platform Channel de GPS
        setupGpsChannel(flutterEngine)

        // Inicializar executor para biometría
        executor = ContextCompat.getMainExecutor(this)

        // CONFIGURAR PLATFORM CHANNEL - BIOMETRÍA
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BIOMETRIC_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkBiometricSupport" -> {
                    // Flutter llamó a checkBiometricSupport()
                    val canAuth = checkBiometricSupport()
                    result.success(canAuth)  // Enviamos respuesta
                }

                "authenticate" -> {
                    // Guardamos result para responder después (async)
                    pendingResult = result
                    showBiometricPrompt()
                }

                else -> {
                    // Método no reconocido
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Verificar si el dispositivo soporta biometría
     */
    private fun checkBiometricSupport(): Boolean {
        val biometricManager = BiometricManager.from(this)

        return when (biometricManager.canAuthenticate(
            BiometricManager.Authenticators.BIOMETRIC_STRONG
        )) {
            BiometricManager.BIOMETRIC_SUCCESS -> true
            else -> false
        }
    }

    /**
     * Mostrar diálogo de autenticación biométrica
     */
    private fun showBiometricPrompt() {
        // Configurar información del diálogo
        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Autenticación Biométrica")
            .setSubtitle("Usa tu huella dactilar")
            .setDescription("Coloca tu dedo en el sensor")
            .setNegativeButtonText("Cancelar")
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            .build()

        // Crear BiometricPrompt con callbacks
        biometricPrompt = BiometricPrompt(this, executor,
            object : BiometricPrompt.AuthenticationCallback() {

                override fun onAuthenticationSucceeded(
                    result: BiometricPrompt.AuthenticationResult
                ) {
                    super.onAuthenticationSucceeded(result)
                    //  Autenticación exitosa
                    pendingResult?.success(true)
                    pendingResult = null
                }

                override fun onAuthenticationError(
                    errorCode: Int,
                    errString: CharSequence
                ) {
                    super.onAuthenticationError(errorCode, errString)
                    // ❌ Error en autenticación
                    pendingResult?.success(false)
                    pendingResult = null
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    // Usuario puede reintentar
                }
            }
        )

        // Mostrar el diálogo
        biometricPrompt.authenticate(promptInfo)
    }

    /**
     * Hub compartido: un solo registro de sensores, varios clientes Flutter.
     * Pasos vía STEP_COUNTER (estable); actividad por cadencia (pasos/min).
     */
    private class AccelerometerStreamHub(
        private val sensorManager: SensorManager,
        private val accelerometer: Sensor?,
        private val stepCounter: Sensor?,
        private val stepDetector: Sensor?,
    ) {
        private val sinks = mutableSetOf<EventChannel.EventSink>()
        private var accelListener: SensorEventListener? = null
        private var stepListener: SensorEventListener? = null

        var stepCount = 0
        private var stepCounterBaseline = -1f
        private var lastMagnitude = 9.8
        private val stepCountHistory = ArrayDeque<Pair<Long, Int>>()
        private var sessionResetAt = 0L
        private val spmWarmupMs = 4_000L
        private val spmWindowMs = 3_000L
        private val spmMinWindowMs = 1_500L
        private val tickIntervalMs = 1_000L
        private val mainHandler = Handler(Looper.getMainLooper())
        private var ticking = false

        private val tickRunnable = object : Runnable {
            override fun run() {
                if (sinks.isEmpty()) {
                    ticking = false
                    return
                }
                pushUpdate()
                mainHandler.postDelayed(this, tickIntervalMs)
            }
        }

        fun addSink(sink: EventChannel.EventSink) {
            sinks.add(sink)
            if (sinks.size == 1) {
                registerSensors()
            }
            pushUpdate()
        }

        fun removeLastSink() {
            if (sinks.isEmpty()) return
            val last = sinks.last()
            sinks.remove(last)
            if (sinks.isEmpty()) {
                unregisterSensors()
            }
        }

        fun resetSteps() {
            stepCount = 0
            stepCounterBaseline = -1f
            stepCountHistory.clear()
            sessionResetAt = System.currentTimeMillis()
            pushUpdate()
        }

        private fun registerSensors() {
            startTicking()
            stepListener = object : SensorEventListener {
                override fun onSensorChanged(event: SensorEvent?) {
                    event ?: return
                    when (event.sensor.type) {
                        Sensor.TYPE_STEP_COUNTER -> {
                            val total = event.values[0]
                            if (stepCounterBaseline < 0f) {
                                stepCounterBaseline = total
                                pushUpdate()
                                return
                            }
                            val newCount = (total - stepCounterBaseline).toInt()
                                .coerceAtLeast(0)
                            if (newCount < stepCount) {
                                return
                            }
                            if (newCount != stepCount) {
                                stepCount = newCount
                                recordStepCountSnapshot()
                                pushUpdate()
                            }
                        }
                        Sensor.TYPE_STEP_DETECTOR -> {
                            stepCount++
                            recordStepCountSnapshot()
                            pushUpdate()
                        }
                    }
                }

                override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
            }

            when {
                stepCounter != null -> sensorManager.registerListener(
                    stepListener,
                    stepCounter,
                    SensorManager.SENSOR_DELAY_NORMAL
                )
                stepDetector != null -> sensorManager.registerListener(
                    stepListener,
                    stepDetector,
                    SensorManager.SENSOR_DELAY_NORMAL
                )
            }

            accelListener = object : SensorEventListener {
                override fun onSensorChanged(event: SensorEvent?) {
                    event ?: return
                    val x = event.values[0]
                    val y = event.values[1]
                    val z = event.values[2]
                    lastMagnitude = sqrt((x * x + y * y + z * z).toDouble())
                }

                override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
            }

            accelerometer?.let {
                sensorManager.registerListener(
                    accelListener,
                    it,
                    SensorManager.SENSOR_DELAY_UI
                )
            }
        }

        private fun unregisterSensors() {
            stopTicking()
            stepListener?.let { sensorManager.unregisterListener(it) }
            accelListener?.let { sensorManager.unregisterListener(it) }
            stepListener = null
            accelListener = null
        }

        private fun startTicking() {
            if (ticking) return
            ticking = true
            mainHandler.postDelayed(tickRunnable, tickIntervalMs)
        }

        private fun stopTicking() {
            mainHandler.removeCallbacks(tickRunnable)
            ticking = false
        }

        private fun recordStepCountSnapshot() {
            val now = System.currentTimeMillis()
            stepCountHistory.addLast(now to stepCount)
            while (stepCountHistory.isNotEmpty() &&
                now - stepCountHistory.first().first > 10_000
            ) {
                stepCountHistory.removeFirst()
            }
        }

        private fun stepsSince(windowMs: Long, now: Long = System.currentTimeMillis()): Int {
            val cutoff = now - windowMs
            var baseline = stepCount
            for (entry in stepCountHistory) {
                if (entry.first <= cutoff) {
                    baseline = entry.second
                }
            }
            return (stepCount - baseline).coerceAtLeast(0)
        }

        private fun computeStepsPerMinute(): Double {
            val now = System.currentTimeMillis()
            if (now - sessionResetAt < spmWarmupMs) {
                return 0.0
            }

            val recentSteps = stepsSince(spmWindowMs, now)
            if (recentSteps <= 0) {
                return 0.0
            }

            var oldestRelevantTime = now
            val cutoff = now - spmWindowMs
            for (entry in stepCountHistory) {
                if (entry.first >= cutoff) {
                    oldestRelevantTime = entry.first
                    break
                }
                oldestRelevantTime = entry.first
            }

            val elapsedMs = now - oldestRelevantTime
            if (elapsedMs < spmMinWindowMs) {
                return 0.0
            }

            return recentSteps / (elapsedMs / 60_000.0)
        }

        private fun activityFromCadence(spm: Double): String {
            return when {
                spm >= 130.0 -> "running"
                spm >= 65.0 -> "walking"
                else -> "stationary"
            }
        }

        private fun pushUpdate() {
            if (sinks.isEmpty()) return
            val spm = computeStepsPerMinute()
            val data = mapOf(
                "stepCount" to stepCount,
                "activityType" to activityFromCadence(spm),
                "magnitude" to lastMagnitude,
                "stepsPerMinute" to spm
            )
            sinks.forEach { sink ->
                sink.success(data)
            }
        }
    }

    private fun setupAccelerometerChannel(flutterEngine: FlutterEngine) {
        val sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
        val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        val stepCounter = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        val stepDetector = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)

        val hub = AccelerometerStreamHub(
            sensorManager,
            accelerometer,
            stepCounter,
            stepDetector
        )

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ACCELEROMETER_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {

            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                events?.let { hub.addSink(it) }
            }

            override fun onCancel(arguments: Any?) {
                hub.removeLastSink()
            }
        })

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "$ACCELEROMETER_CHANNEL/control"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start", "reset" -> {
                    hub.resetSteps()
                    result.success(null)
                }
                "stop" -> {
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Configurar GPS Channels (MethodChannel y EventChannel)
     */
    private fun setupGpsChannel(flutterEngine: FlutterEngine) {
        val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
        var locationListener: LocationListener? = null

        // ═══════════════════════════════════════════════════════════
        // METHOD CHANNEL - Operaciones puntuales
        // ═══════════════════════════════════════════════════════════
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            GPS_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isGpsEnabled" -> {
                    val isEnabled = locationManager.isProviderEnabled(
                        LocationManager.GPS_PROVIDER
                    )
                    result.success(isEnabled)
                }

                "requestPermissions" -> {
                    if (hasLocationPermission()) {
                        result.success(true)
                    } else {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(
                                Manifest.permission.ACCESS_FINE_LOCATION,
                                Manifest.permission.ACCESS_COARSE_LOCATION
                            ),
                            LOCATION_PERMISSION_REQUEST_CODE
                        )
                        result.success(hasLocationPermission())
                    }
                }

                "getCurrentLocation" -> {
                    if (!hasLocationPermission()) {
                        result.error("PERMISSION_DENIED", "Sin permisos", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val location = locationManager.getLastKnownLocation(
                            LocationManager.GPS_PROVIDER
                        ) ?: locationManager.getLastKnownLocation(
                            LocationManager.NETWORK_PROVIDER
                        )

                        if (location != null) {
                            result.success(locationToMap(location))
                        } else {
                            result.error("NO_LOCATION", "No disponible", null)
                        }
                    } catch (e: SecurityException) {
                        result.error("SECURITY_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        // ═══════════════════════════════════════════════════════════
        // EVENT CHANNEL - Stream de ubicaciones
        // ═══════════════════════════════════════════════════════════
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "$GPS_CHANNEL/stream"
        ).setStreamHandler(object : EventChannel.StreamHandler {

            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                if (!hasLocationPermission()) {
                    events?.error("PERMISSION_DENIED", "Sin permisos", null)
                    return
                }

                locationListener = object : LocationListener {
                    override fun onLocationChanged(location: Location) {
                        // Enviar ubicación a Flutter
                        events?.success(locationToMap(location))
                    }

                    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                    override fun onProviderEnabled(provider: String) {}
                    override fun onProviderDisabled(provider: String) {}
                }

                try {
                    // Solicitar actualizaciones
                    locationManager.requestLocationUpdates(
                        LocationManager.GPS_PROVIDER,
                        1000L,      // cada 1 segundo
                        0f,         // cualquier distancia
                        locationListener!!
                    )
                } catch (e: SecurityException) {
                    events?.error("SECURITY_ERROR", e.message, null)
                }
            }

            override fun onCancel(arguments: Any?) {
                locationListener?.let {
                    locationManager.removeUpdates(it)
                }
                locationListener = null
            }
        })
    }

    /**
     * Helper: Verifica si se tienen los permisos de ubicación
     */
    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Helper: Convierte el objeto Location de Android a un Mapa para Flutter
     */
    private fun locationToMap(location: Location): Map<String, Any> {
        return mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "altitude" to location.altitude,
            "speed" to location.speed.toDouble(),
            "accuracy" to location.accuracy.toDouble(),
            "timestamp" to location.time
        )
    }
}