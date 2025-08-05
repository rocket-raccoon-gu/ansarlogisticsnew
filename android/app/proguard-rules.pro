# Flutter URL Launcher plugin
-keep class io.flutter.plugins.urllauncher.** { *; }
-dontwarn io.flutter.plugins.urllauncher.**

# Keep Intent handling and URL schemes
-keep class android.content.Intent { *; }
-keep class android.net.Uri { *; }
-keep class android.webkit.URLUtil { *; }
-keep class android.content.pm.PackageManager { *; }
-keep class android.content.pm.ResolveInfo { *; }
-keep class android.content.pm.ActivityInfo { *; }

# Keep Flutter platform channel communication
-keep class io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class io.flutter.plugin.common.MethodCall { *; }

# Prevent stripping of browser package handling
-keep class android.content.pm.ResolveInfo { *; }
-keep class android.content.pm.PackageManager { *; }

# Keep Flutter engine and plugin registry
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.plugin.** { *; }
