# Manual Gradle Installation Guide

## Overview

This guide provides step-by-step instructions for manually installing Gradle to resolve network connectivity issues when building your Flutter application.

## Steps

### 1. Download Gradle Distribution

1. Visit the official Gradle distributions page: https://gradle.org/releases/
2. Find version 8.12 in the list
3. Download the "Complete" distribution (gradle-8.12-all.zip)

Alternative download locations:
- https://services.gradle.org/distributions/gradle-8.12-all.zip
- https://downloads.gradle-dn.com/distributions/gradle-8.12-all.zip

### 2. Locate Your Gradle User Home Directory

On Windows, the Gradle user home directory is typically:
```
%USERPROFILE%\.gradle
```

To find your exact location, you can run:
```cmd
echo %USERPROFILE%\.gradle
```

### 3. Create the Required Directory Structure

Create the following directory structure:
```
%USERPROFILE%\.gradle\wrapper\dists\gradle-8.12-all\
```

You can create these directories using File Explorer or Command Prompt:
```cmd
mkdir "%USERPROFILE%\.gradle\wrapper\dists\gradle-8.12-all"
```

### 4. Extract the Gradle Distribution

1. Extract the downloaded gradle-8.12-all.zip file
2. Copy the entire contents to:
```
%USERPROFILE%\.gradle\wrapper\dists\gradle-8.12-all\
```

After extraction, your directory structure should look like:
```
%USERPROFILE%\.gradle\wrapper\dists\gradle-8.12-all\
    ├── gradle-8.12\
    │   ├── bin\
    │   ├── lib\
    │   ├── LICENSE
    │   ├── NOTICE
    │   └── ...
    └── gradle-8.12-all.zip (original zip file)
```

### 5. Verify Installation

To verify that Gradle is properly installed, you can run:
```cmd
gradle --version
```

If Gradle is properly installed and added to your PATH, you should see version information.

### 6. Retry Building Your Flutter App

After manually installing Gradle, navigate to your Flutter project directory and try building again:
```cmd
cd c:\sumquiz\sumquiz-flutter
flutter clean
flutter pub get
flutter run
```

## Alternative Solutions

### Using Offline Mode

If you continue to experience network issues, you can try running Flutter in offline mode:
```cmd
flutter run --offline
```

Note: This will only work if all dependencies have been previously downloaded.

### Configuring Proxy Settings

If you're behind a corporate firewall or proxy, you may need to configure Gradle to use your proxy settings. Add the following lines to your [gradle.properties](file://c:\sumquiz\sumquiz-flutter\android\gradle.properties) file:
```properties
systemProp.http.proxyHost=your.proxy.host
systemProp.http.proxyPort=8080
systemProp.https.proxyHost=your.proxy.host
systemProp.https.proxyPort=8080
```

Replace `your.proxy.host` and `8080` with your actual proxy settings.

### Increasing JVM Memory

If you're experiencing memory issues during the build process, you can increase the JVM memory allocation in [gradle.properties](file://c:\sumquiz\sumquiz-flutter\android\gradle.properties):
```properties
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Make sure you have write permissions to the .gradle directory
2. **Path Too Long**: Windows has a 260-character path limit which can cause issues with Gradle. Enable long path support in Windows or move your project to a shorter path
3. **Antivirus Interference**: Some antivirus software may interfere with Gradle downloads. Temporarily disable real-time scanning if needed

### Additional Verification Steps

1. Check that your JAVA_HOME environment variable is set correctly:
   ```cmd
   echo %JAVA_HOME%
   ```

2. Verify your Android SDK path in [local.properties](file://c:\sumquiz\sumquiz-flutter\android\local.properties):
   ```properties
   sdk.dir=C:\\Users\\YourUsername\\AppData\\Local\\Android\\Sdk
   ```

3. Ensure your Flutter SDK path is correct in [local.properties](file://c:\sumquiz\sumquiz-flutter\android\local.properties):
   ```properties
   flutter.sdk=C:\\path\\to\\flutter
   ```

## Need More Help?

If you continue to experience issues after following these steps:

1. Check the Flutter community forums: https://flutter.dev/community
2. Review the Flutter troubleshooting guide: https://flutter.dev/docs/testing/debugging
3. File an issue on the Flutter GitHub repository if you believe you've found a bug: https://github.com/flutter/flutter/issues