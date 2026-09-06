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
