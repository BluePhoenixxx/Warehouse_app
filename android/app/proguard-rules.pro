# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in C:\Users\biend\AppData\Local\Android\Sdk/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.

# For more information, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Add any project specific keep options here:

# If your project uses ProGuard with any of the following packages, specify
# keep rules (e.g., -keep class com.example.package.** { *; })

# Keep rules for mobile_scanner
-keep class com.journeyapps.barcodescanner.** { *; }
-keep class com.google.zxing.** { *; }
