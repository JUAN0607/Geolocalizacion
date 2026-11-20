# Taller Movilidad: geolocalización, sensores y notificaciones

Taller práctico de Flutter del curso **Multimedia para móviles** (Universidad de San Buenaventura, Bogotá).
Profesor: Juan Sebastián Gutiérrez.
Estudiante: Juan Camilo Riaño Vergara.

La app tiene dos pestañas:

- **Parques y Mapa:** mapa de OpenStreetMap centrado en la ubicación actual, con marcadores verdes en los parques que hay a menos de 3 km. Al tocar un parque se ve su nombre.
- **Sensor y Notificación:** el giroscopio detecta cuándo se está caminando. Al empezar a caminar, el teléfono vibra y va sumando la distancia (1,2 m por segundo). Desde esta pestaña también se programa un reporte diario con la distancia recorrida, que llega como notificación a la hora elegida.

## Arquitectura modular

```
lib/
├── main.dart                          Inicio, permisos y navegación inferior
├── theme/app_theme.dart               Colores (verde institucional) y tipografía Roboto
├── services/
│   ├── park_service.dart              Consulta de parques (Overpass API, con respaldo)
│   └── notification_service.dart      Zona horaria y notificación diaria programada
├── widgets/step_counter_widget.dart   Detector de caminata (giroscopio + vibración)
└── screens/
    ├── map_screen.dart                Mapa (OpenStreetMap), ubicación y marcadores de parques
    └── tracker_screen.dart            Monitor de caminata y programación del reporte
```

## Configuración

### 1. Dependencias

```bash
flutter pub get
```

### 2. Mapa: OpenStreetMap en lugar de Google Maps

La guía usa `google_maps_flutter`, que necesita una clave de Google Cloud con la facturación activada. Para activarla, Google exige en Colombia un prepago de 98.000 COP con tarjeta. Por eso el mapa se hizo con **`flutter_map` + `latlong2`**, que muestran los mapas de OpenStreetMap: no necesitan clave, tarjeta ni configuración en Gradle o en el manifiesto.

Equivalencias con la guía:

| Guía (Google Maps) | Esta versión (OpenStreetMap) |
|---|---|
| `GoogleMap` | `FlutterMap` con `TileLayer` de OpenStreetMap |
| `GoogleMapController.animateCamera` | `MapController.move` |
| `Marker` con `BitmapDescriptor.hueGreen` | `Marker` con ícono verde `Icons.location_on` |
| `InfoWindow` (nombre + "Zona verde cercana") | Aviso inferior con el nombre y "Zona verde cercana" al tocar el parque |
| `myLocationEnabled` | Punto azul en la ubicación actual y botón "Mi ubicación" |

El resto de la app (ubicación, servicio de parques, sensores, vibración y notificaciones) sigue la guía.

### 3. Paso de Gradle para las notificaciones

`flutter_local_notifications` necesita *desugaring* para compilar. Ya está configurado en `android/app/build.gradle.kts`:

```kotlin
compileOptions {
    isCoreLibraryDesugaringEnabled = true
}
defaultConfig {
    multiDexEnabled = true
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

El `AndroidManifest.xml` también tiene los receptores `ScheduledNotificationReceiver` y `ScheduledNotificationBootReceiver`, que el paquete exige para mostrar las notificaciones programadas.

### 4. Ejecutar

```bash
flutter run
```

## Ajustes respecto a la guía

Se siguió la guía del taller. Al probarla aparecieron estos problemas, que se corrigieron así:

| Problema encontrado | Solución |
|---|---|
| La librería `timezone` usa UTC por defecto: una notificación programada a las 20:00 habría llegado a las 15:00 en Colombia. | `NotificationService.init()` toma la zona horaria real del teléfono con `flutter_timezone`. |
| Desde Android 14 las alarmas exactas vienen desactivadas, y `zonedSchedule` falla si no hay permiso. | Antes de programar se pide el permiso. Si el usuario no lo da, la notificación se programa en modo no exacto. |
| Overpass API rechazaba conexiones desde la red de pruebas, aunque desde otros países respondía. | `ParkService` intenta dos servidores espejo de Overpass y, como último recurso, Nominatim (también de OpenStreetMap). |
| Si el usuario rechaza el aviso de "Precisión de la ubicación" de Google, `getCurrentPosition()` dice que la ubicación está apagada. | La pantalla del mapa pide entonces la posición directo al GPS (`forceAndroidLocationManager`). |
| El selector de hora salía en inglés. | Se agregó `flutter_localizations` con el idioma `es-CO`. |
| En la versión final (`flutter build apk --release`), programar la notificación fallaba con "Missing type parameter", porque al comprimir el código se borraban clases que usa el paquete de notificaciones. | Se agregó `android/app/proguard-rules.pro` con las reglas de `flutter_local_notifications` y Gson, como indica el README del paquete. |
| Google Maps exige activar la facturación de Google Cloud (prepago con tarjeta). | El mapa usa OpenStreetMap con `flutter_map` (ver punto 2 de Configuración). |
| La guía no incluía el `build()` del mapa, del detector de caminata ni el final de la pantalla de seguimiento. | Se completaron: mapa con indicador de carga y contador de parques, tarjeta con el estado (Caminando / En reposo) y la distancia, y botón para programar el reporte. |

## Pruebas

### Pruebas automáticas (`flutter test`): 7 de 7 aprobadas

- Lectura de parques de Overpass y de Nominatim, incluido el nombre por defecto "Parque Público".
- Cálculo de la hora de la notificación: una hora un minuto adelante queda para hoy y una hora que ya pasó queda para mañana.
- Umbral del giroscopio: el reposo no cuenta como caminata y una rotación fuerte sí.

`flutter analyze`: sin observaciones.

### Pruebas en emulador Android (Pixel 8, Android 17, con giroscopio virtual)

| Prueba | Resultado |
|---|---|
| Permisos de ubicación y notificaciones al abrir | Se piden ambos |
| Ubicación (GPS simulado en Bogotá, 4.6583, -74.0939) | Ubica y el botón "Mi ubicación" vuelve a centrar el mapa |
| Mapa de OpenStreetMap | Se ve Bogotá centrada en la ubicación, con punto azul |
| Parques cercanos | Entre 12 y 15 parques reales en 3 km, según la respuesta del servicio |
| Tocar un parque | Muestra su nombre y "Zona verde cercana" |
| Giroscopio en reposo, luego girando (1.5, 0.8, 0.3 rad/s) | Pasa de "En reposo" a "Caminando" |
| Distancia | 19,2 m en 16 s caminando (1,2 m/s) |
| Vibración al empezar a caminar | 150 ms, registrada por el sistema (`dumpsys vibrator_manager`) |
| Notificación a 1 minuto de la hora actual | Programada a las 12:11, llegó a las 12:11:01 con "Hoy has caminado aprox. 19.2 metros." y vibración 400-200-400 ms |
| Repetición diaria | El reporte programado a las 20:00 del 19 de noviembre llegó solo a las 20:00:01 |
| Versión final (APK release) | Abre, muestra los parques, detecta la caminata y la notificación llegó a la hora exacta (17:05:00) |
| Navegación inferior | Cambia entre las dos pestañas y conserva el estado |

Las capturas y los videos están en la carpeta [`evidencias/`](evidencias/). El archivo `taller_movilidad.apk` se puede instalar directamente en un teléfono Android.

> Como recomienda la guía, conviene repetir la prueba del giroscopio y de la vibración en un teléfono Android físico conectado por USB.
