# mobile_scanner + ML Kit (release builds strip/obfuscate these without keep rules)
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.libraries.barhopper.** { *; }
-keep class com.google.photos.** { *; }

# CameraX used by mobile_scanner and camera plugin
-keep class androidx.camera.** { *; }
-keep interface androidx.camera.** { *; }

# Plugin entry points
-keep class dev.steenbakker.mobile_scanner.** { *; }

-keepclassmembers class * extends java.lang.Enum {
    <fields>;
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

-dontwarn com.google.mlkit.**
-dontwarn androidx.camera.**
