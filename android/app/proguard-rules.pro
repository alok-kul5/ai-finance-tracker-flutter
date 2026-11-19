# ML Kit ships optional recognisers for other scripts; only Latin is bundled.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# MediaPipe LLM inference is called through JNI and reflection.
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# flutter_local_notifications serialises its models with Gson.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
