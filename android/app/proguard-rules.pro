# Reglas para la versión final (release). Sin ellas, al comprimir el código
# flutter_local_notifications falla con "Missing type parameter" al programar
# la notificación. Fuente: README de flutter_local_notifications y reglas de Gson.

## flutter_local_notifications
-keep class com.dexterous.** { *; }

## Gson (lo usa flutter_local_notifications para guardar las notificaciones)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken
