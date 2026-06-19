# MEGA RETO — Justificación técnica

## 1. Elección de `sensors_plus` vs `activity_recognition_flutter`

| Criterio | `sensors_plus` | `activity_recognition_flutter` |
|---|---|---|
| Datos devueltos | Acelerómetro crudo `(x, y, z)` en m/s² | Actividades pre-clasificadas por el SO |
| Procesamiento propio | Clasificación, debounce y caídas | Debounce y TTS; caídas requieren otro sensor |
| Detección de caídas | Mismo stream | No soportada; obliga a un segundo plugin |
| Android | Plugin Plus, sin depender de Play Services | Activity Recognition API / Play Services |
| Control y justificación | Umbrales y algoritmos propios documentables | Caja negra del sistema operativo |

**Decisión:** `sensors_plus`.

**Motivo:** el enunciado exige acelerómetro crudo para caídas. Un solo stream alimenta clasificación de actividad, debounce, TTS y detector de caídas, evitando desincronización entre dos fuentes.

## 2. Clasificación de actividad

### Magnitud

```
magnitud = sqrt(x² + y² + z²)
```

### Suavizado

Promedio móvil de **10 muestras** para reducir ruido de alta frecuencia del acelerómetro.

### Umbrales (m/s²)

| Rango | Actividad |
|---|---|
| `< 10.5` | Quieto (`stationary`) |
| `10.5 – 13.5` | Caminando (`walking`) |
| `> 13.5` | Corriendo (`running`) |

**Justificación:** en reposo la magnitud ≈ 9.8 m/s² (gravedad). Al caminar o correr, la aceleración dinámica eleva la magnitud resultante. Los umbrales 10.5 y 13.5 provienen de la lógica ya validada en `MainActivity.kt` del taller anterior.

### Confianza interna

Se requieren **3 lecturas consecutivas** del mismo candidato antes de emitir un estado clasificado, filtrando cambios instantáneos por ruido.

## 3. Detección de caídas

Algoritmo en **tres fases + cooldown**:

1. **Caída libre:** magnitud `< 4.0 m/s²` durante ≥ 150 ms.
2. **Impacto:** magnitud `> 27 m/s²` dentro de 600 ms tras la caída libre.
3. **Post-impacto:** 1 s con variación consecutiva `< 1.5 m/s²` (inmovilidad).
4. **Cooldown:** 45 s sin nuevas alertas.

**Umbral de impacto 27 m/s² (~2.75 g):** la literatura de detección de caídas usa picos de 2.5–3.5 g. Valores de caminata normal (~12–15 m/s²) quedan por debajo, reduciendo falsos positivos.

**Anti-falsos positivos adicionales:**

- Ventana temporal caída libre → impacto.
- Confirmación de quietud post-impacto.
- Cooldown entre alertas.
- Ignorar detección si la actividad es `running` con magnitud sostenida > 16 m/s².

## 4. Debounce de actividad (4 segundos)

**Qué es:** mecanismo que espera a que un valor se mantenga estable antes de ejecutar una acción (en este caso, anunciar por voz).

**Implementación:** al cambiar el candidato de actividad, se reinicia un temporizador de **4 segundos**. Solo si el candidato no cambia en ese intervalo y es distinto al último estado anunciado, se dispara el TTS.

**Justificación de 4 s:**

- Las transiciones humanas reales tardan 2–4 s.
- Una frase TTS dura ~2 s; intervalos menores generan frases superpuestas.
- Más de 6 s se percibe lento para el usuario.

## 5. Síntesis de voz — `flutter_tts`

**Por qué `flutter_tts`:**

- Mantenido y ampliamente usado en Flutter.
- Usa el motor TTS del sistema (respeta idioma del dispositivo).
- API simple: `setLanguage`, `speak`.
- Sin assets de audio pregrabados.

**Idioma:** se intenta `Platform.localeName`; fallback a `es-ES`, `es-MX` o `en-US`.

**Mensajes:**

- Primera detección: "Estás caminando", "Estás corriendo", "Has dejado de moverte".
- Cambio: "Cambiaste a caminata", "Cambiaste a carrera", "Te detuviste".
- Caída: "¿Estás bien? Parece que te has caído".

## 6. Permisos Android

Declarados en `AndroidManifest.xml`:

- `ACTIVITY_RECOGNITION` — reconocimiento de actividad física (Android 10+).
- `BODY_SENSORS` — sensores corporales/de movimiento.
- `HIGH_SAMPLING_RATE_SENSORS` — Android 12+ para muestreo alto (declarado por precaución).

Solicitados en runtime con `permission_handler` **antes** de suscribirse al acelerómetro.

**Si se deniegan:** el stream no entrega datos útiles y no siempre muestra un error visible; la UI informa "Permisos de sensores denegados".

## 7. Diálogo de caída

- Aparece inmediatamente al detectar caída.
- Botones: "Estoy bien" / "Necesito ayuda".
- Tras **15 s** sin respuesta: mensaje reforzado en rojo pidiendo confirmación.

## 8. Limitaciones conocidas

- **Emulador:** acelerómetro y caídas no son realistas; probar en dispositivo físico.
- **TTS en emulador:** puede no tener voz española instalada.
- **Falsos positivos:** sacudir bruscamente el teléfono puede simular impacto; el cooldown y las fases mitigan pero no eliminan el riesgo.
- **Batería:** stream continuo del acelerómetro consume más que APIs de reconocimiento del SO.

## 9. Arquitectura

Feature vertical `lib/features/activity_monitor/`:

- **Domain:** entidades, `ActivityClassifier`, `ActivityDebouncer`, `FallDetector`, `MonitorActivityUseCase` (Dart puro).
- **Data:** `sensors_plus`, `flutter_tts`, permisos.
- **Presentation:** `ActivityMonitorBloc`, widgets, diálogo de caída.

Auth, GPS y contador de pasos del taller anterior permanecen con Platform Channels sin modificarse.
