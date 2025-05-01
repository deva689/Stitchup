# --- Keep all androidx.window related classes and interfaces ---
-keep class androidx.window.** { *; }
-keep interface androidx.window.** { *; }
-keep class com.arthenica.** { *; }
-keep class org.pytorch.** { *; }
-keepattributes SourceFile,LineNumberTable
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.internal.firebase-perf.** { *; }


# --- Don't warn about missing optional window-related classes ---
-dontwarn androidx.window.**

# --- Keep window extensions and sidecar classes ---
-keep class androidx.window.sidecar.** { *; }
-keep class androidx.window.extensions.** { *; }
-keep class androidx.window.layout.** { *; }
-keep class androidx.window.area.** { *; }
-keep class androidx.window.extensions.area.** { *; }
-keep class androidx.window.extensions.embedding.** { *; }
-keep class androidx.window.extensions.layout.** { *; }

# --- Keep class members accessed via reflection or dynamic loading ---
-keepclassmembers class * {
    @androidx.window.extensions.* <methods>;
    @androidx.window.sidecar.* <methods>;
}

# --- Keep classes used in dynamic class loading (optional but safe) ---
-keepnames class androidx.window.**
-keepnames interface androidx.window.**

# --- Optional: Helps debugging obfuscated stack traces ---
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable
