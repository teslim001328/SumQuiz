# SumQuiz Project Backup Documentation

This file serves as a backup documentation of the project structure before major refactoring.

## Current Project Structure

```
sumquiz-flutter/
├── android/
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── models/
│   │   ├── flashcard.dart
│   │   ├── flashcard_model.dart
│   │   ├── library_item.dart
│   │   ├── quiz_model.dart
│   │   ├── quiz_question.dart
│   │   ├── summary_model.dart
│   │   └── user_model.dart
│   ├── screens/
│   │   ├── auth_gate.dart
│   │   ├── dashboard_screen.dart
│   │   └── sign_in_screen.dart
│   ├── services/
│   │   ├── ai_service.dart
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── progress_service.dart
│   │   ├── subscription_service.dart
│   │   └── upgrade_service.dart
│   ├── utils/
│   │   └── logger.dart
│   └── views/
│       ├── auth_screen.dart (DUPLICATE)
│       ├── main_screen.dart (DUPLICATE)
│       ├── theme.dart
│       ├── screens/
│       │   ├── auth_screen.dart (DUPLICATE)
│       │   ├── flashcards_screen.dart
│       │   ├── home_screen.dart
│       │   ├── library_screen.dart
│       │   ├── main_screen.dart (DUPLICATE)
│       │   ├── profile_screen.dart
│       │   ├── progress_screen.dart
│       │   ├── quiz_screen.dart
│       │   ├── subscription_screen.dart
│       │   └── summary_screen.dart
│       └── widgets/
│           └── upgrade_modal.dart
├── test/
├── web/
├── pubspec.yaml
└── README.md
```

## Duplicate Files Issue

There are duplicate implementations of key screens:
1. Two [auth_screen.dart](file://c:\sumquiz\sumquiz-flutter\lib\views\auth_screen.dart) files with different implementations
2. Two [main_screen.dart](file://c:\sumquiz\sumquiz-flutter\lib\views\main_screen.dart) files with different implementations

## Current Gradle Configuration

[gradle.properties](file://c:\sumquiz\sumquiz-flutter\android\gradle.properties):
```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true
# Network configuration to help with connection issues
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.configureondemand=true
# Connection timeout settings (increased from 60 seconds to 5 minutes)
org.gradle.internal.http.connectionTimeout=300000
org.gradle.internal.http.socketTimeout=300000
# Retry settings
org.gradle.internal.repository.max.retries=5
org.gradle.internal.repository.checksums.error-action=warn
```

[gradle-wrapper.properties](file://c:\sumquiz\sumquiz-flutter\android\gradle\wrapper\gradle-wrapper.properties):
```properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
# Using a different CDN that might be more accessible
distributionUrl=https\://downloads.gradle-dn.com/distributions/gradle-8.12-all.zip
```

This backup documentation was created before refactoring to ensure we can restore the original state if needed.