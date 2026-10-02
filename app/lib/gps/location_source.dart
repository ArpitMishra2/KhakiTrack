import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'run_analysis.dart';

enum LocationAccess { granted, denied, deniedForever, serviceOff }

/// Where GPS fixes come from; a fake replays traces in tests.
abstract class LocationSource {
  Future<LocationAccess> ensureAccess();

  /// Fixes from now on, with [TrackPoint.tMs] relative to [start].
  Stream<TrackPoint> track(DateTime start);

  Future<void> openSettings();
}

class GeolocatorSource implements LocationSource {
  const GeolocatorSource({
    required this.notificationTitle,
    required this.notificationText,
  });

  final String notificationTitle;
  final String notificationText;

  @override
  Future<LocationAccess> ensureAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceOff;
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return switch (p) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationAccess.granted,
      LocationPermission.deniedForever => LocationAccess.deniedForever,
      _ => LocationAccess.denied,
    };
  }

  @override
  Stream<TrackPoint> track(DateTime start) {
    final settings = AndroidSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      intervalDuration: const Duration(seconds: 1),
      // Keeps GPS running with the screen off or the app in the background.
      foregroundNotificationConfig: ForegroundNotificationConfig(
        notificationTitle: notificationTitle,
        notificationText: notificationText,
        enableWakeLock: true,
        setOngoing: true,
      ),
    );
    return Geolocator.getPositionStream(locationSettings: settings).map(
      (p) => TrackPoint(
        tMs: p.timestamp.difference(start).inMilliseconds.clamp(0, 1 << 31),
        lat: p.latitude,
        lon: p.longitude,
        accuracy: p.accuracy,
        mock: p.isMocked,
      ),
    );
  }

  @override
  Future<void> openSettings() => Geolocator.openAppSettings();
}
