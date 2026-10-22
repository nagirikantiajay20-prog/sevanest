# Razorpay checkout (reflection + annotations)
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !method/inlining/*
-keepclasseswithmembers class * {
    public void onPayment*(...);
}
# Firebase / Play services ship consumer rules; keep their model classes readable in crash reports.
-keepattributes SourceFile,LineNumberTable
-dontwarn proguard.annotation.**
-dontwarn com.google.firebase.**
