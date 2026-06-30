import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Installs privacy-preserving fatal error reporting.
///
/// Exception messages can contain user input or SDK request details, so only
/// the exception type and stack are sent. No UID, email, token, chat message or
/// custom user identifier is attached to Crashlytics reports.
Future<void> configureCrashReporting() async {
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

  FlutterError.onError = (details) {
    if (kDebugMode) FlutterError.presentError(details);
    if (!kDebugMode) {
      unawaited(
        crashlytics.recordError(
          _SanitizedCrash(details.exception),
          details.stack ?? StackTrace.empty,
          reason: 'uncaught_flutter_framework_error',
          fatal: true,
        ),
      );
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (!kDebugMode) {
      unawaited(
        crashlytics.recordError(
          _SanitizedCrash(error),
          stack,
          reason: 'uncaught_platform_error',
          fatal: true,
        ),
      );
      return true;
    }
    return false;
  };
}

class _SanitizedCrash implements Exception {
  _SanitizedCrash(Object error) : type = error.runtimeType.toString();

  final String type;

  @override
  String toString() => 'Unhandled application error ($type)';
}

@visibleForTesting
String sanitizedCrashDescription(Object error) =>
    _SanitizedCrash(error).toString();
