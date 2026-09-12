# Firebase Crashlytics — stack traces legíveis no release com R8.
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Flutter embedding + plugins (R8 não remove classes JNI usadas em runtime).
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Google Mobile Ads (AdMob SDK).
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# Play Services / billing (plugins futuros ou transitivos).
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# AndroidX Startup — AdMob/WorkManager inicializam via InitializationProvider.
-keep class androidx.startup.** { *; }
-keep class * implements androidx.startup.Initializer { *; }

# WorkManager — dependência transitiva do AdMob; R8 quebrava WorkDatabase no boot.
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.InputMerger
-keep class * extends androidx.work.ListenableWorker
-keep class androidx.work.** { *; }
-keepclassmembers class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keepclassmembers class androidx.work.impl.** { *; }
-dontwarn androidx.work.**

# Room — WorkDatabase estende RoomDatabase; sem estas regras o release crasha ao abrir.
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-keepclassmembers class * {
    @androidx.room.* <methods>;
}
-keep class androidx.room.** { *; }
-dontwarn androidx.room.paging.**
