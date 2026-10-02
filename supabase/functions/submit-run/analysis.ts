// GPS run analysis and cheat detection, rules version 1.
//
// Mirrors app/lib/gps/run_analysis.dart exactly; the rules and their
// reasons are in data/gps_traces/README.md. Both are tested against the
// traces in data/gps_traces. Change both together.

export interface TrackPoint {
  t: number; // ms since run start
  lat: number;
  lon: number;
  acc: number; // horizontal accuracy, metres
  mock?: boolean;
}

export const RULES = {
  version: 1,
  maxAccuracyM: 30,
  maxDroppedFraction: 0.3,
  jitterM: 2,
  smoothRadius: 2,
  smoothWindowS: 10,
  teleportMinM: 50,
  teleportSpeed: 12,
  gapS: 20,
  gapMaxM: 200,
  gapLongS: 45,
  gapMaxFraction: 0.15,
  sprintWindowS: 30,
  sprintMaxSpeed: 9,
  vehicleWindowS: 180,
  vehicleMaxSpeed: 6,
  averageMinM: 1500,
  averageMaxSpeed: 6.2,
  minPointsPerS: 0.1,
  minDurationS: 60,
  minDistanceM: 200,
} as const;

export const REJECT_FLAGS = new Set([
  "mock_location",
  "teleport",
  "impossible_speed",
  "vehicle_like",
  "implausible_average",
]);

export interface RunAnalysis {
  verdict: "verified" | "suspicious" | "rejected";
  flags: string[];
  distanceM: number;
  durationS: number;
  finishSeconds: number | null;
  keptPoints: number;
}

export function haversineM(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const r = 6371008.8;
  const rad = (d: number) => (d * Math.PI) / 180;
  const dLat = rad(lat2 - lat1);
  const dLon = rad(lon2 - lon1);
  const a = Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * r * Math.asin(Math.min(1, Math.sqrt(a)));
}

export function analyseRun(input: TrackPoint[], targetM: number | null = null): RunAnalysis {
  const flags = new Set<string>();

  // 1. Sort, drop repeated timestamps.
  const sorted = [...input].sort((a, b) => a.t - b.t);
  const pts: TrackPoint[] = [];
  for (const p of sorted) if (pts.length === 0 || p.t !== pts[pts.length - 1].t) pts.push(p);

  // 2. Mock locations.
  if (pts.some((p) => p.mock)) flags.add("mock_location");

  // 3. Accuracy.
  const accurate = pts.filter((p) => p.acc <= RULES.maxAccuracyM);
  if (pts.length > 0 && (pts.length - accurate.length) / pts.length > RULES.maxDroppedFraction) {
    flags.add("poor_signal");
  }

  const durationS = pts.length < 2 ? 0 : (pts[pts.length - 1].t - pts[0].t) / 1000;

  // 4 and 6. Teleports and gaps on the raw accurate points.
  const teleportBefore = new Array<boolean>(accurate.length).fill(false);
  const breakBefore = new Array<boolean>(accurate.length).fill(false);
  let gapTime = 0;
  for (let i = 1; i < accurate.length; i++) {
    const a = accurate[i - 1], b = accurate[i];
    const d = haversineM(a.lat, a.lon, b.lat, b.lon);
    const dt = (b.t - a.t) / 1000;
    if (d > RULES.teleportMinM && d / dt > RULES.teleportSpeed) {
      flags.add("teleport");
      teleportBefore[i] = true;
      breakBefore[i] = true;
    }
    if (dt > RULES.gapS) {
      gapTime += dt;
      breakBefore[i] = true;
      if (d > RULES.gapMaxM || dt > RULES.gapLongS) flags.add("signal_gap");
    }
  }
  if (durationS > 0 && gapTime / durationS > RULES.gapMaxFraction) flags.add("signal_gap");

  // 5. Symmetric smoothing within unbroken stretches.
  const reach = (i: number, dir: -1 | 1) => {
    let k = 0;
    while (k < RULES.smoothRadius) {
      const j = i + dir * (k + 1);
      if (j < 0 || j >= accurate.length) break;
      if (breakBefore[dir < 0 ? j + 1 : j]) break;
      if (Math.abs(accurate[j].t - accurate[i].t) / 1000 > RULES.smoothWindowS) break;
      k++;
    }
    return k;
  };
  const sLat = new Array<number>(accurate.length).fill(0);
  const sLon = new Array<number>(accurate.length).fill(0);
  for (let i = 0; i < accurate.length; i++) {
    const m = Math.min(reach(i, -1), reach(i, 1));
    let lat = 0, lon = 0;
    for (let j = i - m; j <= i + m; j++) {
      lat += accurate[j].lat;
      lon += accurate[j].lon;
    }
    sLat[i] = lat / (2 * m + 1);
    sLon[i] = lon / (2 * m + 1);
  }

  // Jitter: keep a point once it is 2 m from the last kept one.
  const kept: TrackPoint[] = [];
  const cum: number[] = [];
  let lastKept = -1;
  for (let i = 0; i < accurate.length; i++) {
    if (lastKept < 0) {
      lastKept = i;
      kept.push(accurate[i]);
      cum.push(0);
      continue;
    }
    const d = haversineM(sLat[lastKept], sLon[lastKept], sLat[i], sLon[i]);
    let teleported = false;
    for (let k = lastKept + 1; k <= i; k++) teleported ||= teleportBefore[k];
    if (d < RULES.jitterM && !breakBefore[i]) continue;
    kept.push(accurate[i]);
    cum.push(cum[cum.length - 1] + (teleported ? 0 : d));
    lastKept = i;
  }

  // 7-8. Window speeds.
  const windowCheck = (windowS: number, maxSpeed: number, flag: string) => {
    let start = 0;
    for (let end = 1; end < kept.length; end++) {
      while (start < end && (kept[end].t - kept[start].t) / 1000 > windowS) start++;
      const span = (kept[end].t - kept[start].t) / 1000;
      if (span >= windowS / 2 && (cum[end] - cum[start]) / span > maxSpeed) {
        flags.add(flag);
        return;
      }
    }
  };
  windowCheck(RULES.sprintWindowS, RULES.sprintMaxSpeed, "impossible_speed");
  windowCheck(RULES.vehicleWindowS, RULES.vehicleMaxSpeed, "vehicle_like");

  const distanceM = cum.length === 0 ? 0 : cum[cum.length - 1];
  // 9. Average.
  if (distanceM >= RULES.averageMinM && durationS > 0 && distanceM / durationS > RULES.averageMaxSpeed) {
    flags.add("implausible_average");
  }
  // 10. Sampling.
  if (durationS > 0 && accurate.length / durationS < RULES.minPointsPerS) flags.add("sparse_samples");
  // 11. Too short.
  if (durationS < RULES.minDurationS || distanceM < RULES.minDistanceM) flags.add("too_short");

  // 12. Finish time.
  let finish: number | null = null;
  if (targetM != null && kept.length > 0) {
    const t0 = pts[0].t;
    for (let i = 1; i < kept.length; i++) {
      if (cum[i] >= targetM && cum[i] > cum[i - 1]) {
        const frac = (targetM - cum[i - 1]) / (cum[i] - cum[i - 1]);
        const ta = (kept[i - 1].t - t0) / 1000;
        const tb = (kept[i].t - t0) / 1000;
        finish = ta + frac * (tb - ta);
        break;
      }
    }
  }

  const ordered = [...flags].sort();
  return {
    verdict: ordered.some((f) => REJECT_FLAGS.has(f))
      ? "rejected"
      : ordered.length === 0
      ? "verified"
      : "suspicious",
    flags: ordered,
    distanceM,
    durationS,
    finishSeconds: finish,
    keptPoints: kept.length,
  };
}
