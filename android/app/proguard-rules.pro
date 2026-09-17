# Rhino (org.mozilla.javascript) - usado por algumas dependências
-dontwarn java.beans.**
-dontwarn javax.script.**
-keep class org.mozilla.javascript.** { *; }
-dontwarn org.mozilla.javascript.**

# Extractor & youtubedl-android (JNI, reflection & native binaries)
-keep class com.ashishpipaliya.extractor.** { *; }
-dontwarn com.ashishpipaliya.extractor.**

-keep class com.yausername.youtubedl_android.** { *; }
-dontwarn com.yausername.youtubedl_android.**

-keep class com.yausername.ffmpeg.** { *; }
-dontwarn com.yausername.ffmpeg.**

-keep class com.yausername.aria2c.** { *; }
-dontwarn com.yausername.aria2c.**

-keep class io.github.junkfood02.youtubedl_android.** { *; }
-dontwarn io.github.junkfood02.youtubedl_android.**

-keep class org.apache.commons.compress.** { *; }
-dontwarn org.apache.commons.compress.**

# Preserve native JNI methods and reflection attributes
-keepclasseswithmembernames class * {
    native <methods>;
}
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Just Audio & Audio Session
-keep class com.ryanheise.just_audio.** { *; }
-dontwarn com.ryanheise.just_audio.**
-keep class com.ryanheise.audio_session.** { *; }
-dontwarn com.ryanheise.audio_session.**

# Audio Service & Android Media / MediaSession
-keep class com.ryanheise.audioservice.** { *; }
-dontwarn com.ryanheise.audioservice.**
-keep class android.support.v4.media.** { *; }
-dontwarn android.support.v4.media.**
-keep class androidx.media.** { *; }
-dontwarn androidx.media.**
-keep class androidx.media3.** { *; }
-keep interface androidx.media3.** { *; }
-dontwarn androidx.media3.**
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

