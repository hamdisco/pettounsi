# Keep Flutter plugin registration
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Firebase Auth pigeon + plugin classes (safe even if minify later enabled)
-keep class io.flutter.plugins.firebase.auth.** { *; }
-keep class dev.flutter.pigeon.firebase_auth_platform_interface.** { *; }

# Firebase / Google Play services
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
