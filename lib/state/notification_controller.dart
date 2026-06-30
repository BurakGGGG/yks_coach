import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repositories.dart';
import '../services/notification_service.dart';
import 'profile_controller.dart';
import 'schedule_controller.dart';

/// Coordinates user preferences, Android permission, local schedules and the
/// FCM device registration. Permission is requested only from an explicit
/// switch-on action in the Notifications screen.
class NotificationController extends ChangeNotifier {
  NotificationController({
    required this.profile,
    required this.schedule,
    required this._devices,
    NotificationGateway? gateway,
  }) : _gateway = gateway {
    profile.addListener(_queueSync);
    schedule.addListener(_queueSync);
    if (gateway != null) {
      _tapSubscription = gateway.notificationTaps.listen(_onTap);
      final initial = gateway.takeInitialTarget();
      if (initial != null) _pendingTarget = initial;
      _queueSync();
    }
  }

  final ProfileController profile;
  final ScheduleController schedule;
  final DeviceRepository _devices;
  final NotificationGateway? _gateway;
  StreamSubscription<String>? _tapSubscription;

  bool busy = false;
  String? errorMessage;
  String? _pendingTarget;
  bool _syncQueued = false;

  bool get supported => _gateway?.supported ?? false;
  String get timeZone => _gateway?.timeZone ?? 'Europe/Istanbul';

  String? takePendingTarget() {
    final value = _pendingTarget;
    _pendingTarget = null;
    return value;
  }

  Future<bool> updatePreferences({
    bool? daily,
    bool? task,
    bool? motivation,
    bool? exam,
    TimeOfDay? time,
  }) async {
    if (busy) return false;
    final enabling =
        daily == true || task == true || motivation == true || exam == true;
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      if (enabling && supported) {
        final authorized =
            await _gateway!.isAuthorized() ||
            await _gateway.requestAuthorization();
        if (!authorized) {
          errorMessage =
              'Bildirim izni verilmedi. Android ayarlarından izin verebilirsin.';
          return false;
        }
      }
      if (enabling && !supported) {
        errorMessage =
            'Bildirimler şu an yalnızca Android uygulamasında destekleniyor.';
        return false;
      }
      await profile.updateNotifications(
        daily: daily,
        task: task,
        motivation: motivation,
        exam: exam,
        time: time,
      );
      await synchronize();
      return true;
    } on Object {
      errorMessage = 'Bildirim tercihleri kaydedilemedi. Tekrar dene.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> synchronize() async {
    final gateway = _gateway;
    if (gateway == null || !gateway.supported || !profile.loaded) return;
    try {
      await gateway.synchronize(
        devices: _devices,
        profile: profile.profile,
        tasks: schedule.tasks,
      );
    } on Object {
      errorMessage = 'Bildirim zamanlaması güncellenemedi.';
      notifyListeners();
    }
  }

  Future<void> deactivate() async {
    final gateway = _gateway;
    if (gateway == null || !gateway.supported) return;
    await gateway.deactivate(_devices);
  }

  void _queueSync() {
    if (_syncQueued) return;
    _syncQueued = true;
    scheduleMicrotask(() async {
      _syncQueued = false;
      await synchronize();
    });
  }

  void _onTap(String target) {
    _pendingTarget = target;
    notifyListeners();
  }

  @override
  void dispose() {
    profile.removeListener(_queueSync);
    schedule.removeListener(_queueSync);
    _tapSubscription?.cancel();
    super.dispose();
  }
}
