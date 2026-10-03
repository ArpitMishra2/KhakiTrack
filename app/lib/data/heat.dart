/// True in the hours when running outdoors is risky in north Indian heat:
/// 10:00 to 17:59 from March to October. Time-based only (no weather data),
/// so it is a nudge, not a measurement.
bool isHeatHour(DateTime now) =>
    now.month >= 3 && now.month <= 10 && now.hour >= 10 && now.hour < 18;
