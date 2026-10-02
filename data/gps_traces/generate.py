"""Generates the synthetic GPS test traces in this folder.

Run from the repo root: python data/gps_traces/generate.py
Deterministic (fixed seed), so re-running gives identical files.
"""

import json
import math
import random
from pathlib import Path

OUT = Path(__file__).parent
# A ground near Ghatampur, Kanpur Nagar.
CENTER_LAT, CENTER_LON = 26.1530, 80.1690
M_PER_DEG_LAT = 111_320.0
M_PER_DEG_LON = 111_320.0 * math.cos(math.radians(CENTER_LAT))
LOOP_M = 400.0
RADIUS = LOOP_M / (2 * math.pi)


def loop_pos(dist_m):
    """Position after running dist_m around a circular 400 m loop."""
    a = 2 * math.pi * (dist_m % LOOP_M) / LOOP_M
    return RADIUS * math.cos(a), RADIUS * math.sin(a)


def line_pos(dist_m, start=(RADIUS, 0.0)):
    """Position along a straight road heading east from the loop."""
    return start[0] + dist_m, start[1]


class Drift:
    """Phone GPS error drifts slowly rather than jumping every second:
    an AR(1) process with the given standard deviation in metres."""

    def __init__(self, rng, sigma, rho=0.95):
        self.rng, self.sigma, self.rho = rng, sigma, rho
        self.ex = rng.gauss(0, sigma)
        self.ey = rng.gauss(0, sigma)

    def step(self):
        k = self.sigma * math.sqrt(1 - self.rho ** 2)
        self.ex = self.rho * self.ex + self.rng.gauss(0, k)
        self.ey = self.rho * self.ey + self.rng.gauss(0, k)
        return self.ex, self.ey


_drift = {}


def to_point(t_s, xy, rng, noise=3.0, acc=None, mock=False):
    drift = _drift.setdefault((id(rng), noise), Drift(rng, noise))
    ex, ey = drift.step()
    # Plus a little independent jitter on top of the drift.
    x = xy[0] + ex + rng.gauss(0, noise * 0.15)
    y = xy[1] + ey + rng.gauss(0, noise * 0.15)
    return {
        "t": int(round(t_s * 1000)),
        "lat": round(CENTER_LAT + y / M_PER_DEG_LAT, 7),
        "lon": round(CENTER_LON + x / M_PER_DEG_LON, 7),
        "acc": round(acc if acc is not None else rng.uniform(4, 10), 1),
        "mock": mock,
    }


def run(speed_at, duration_s, rng, pos=loop_pos, step_s=1.0, **kw):
    """Points every step_s seconds; speed_at(t) gives m/s at time t."""
    pts, d, t = [], 0.0, 0.0
    while t <= duration_s:
        pts.append(to_point(t, pos(d), rng, **kw))
        d += speed_at(t) * step_s
        t += step_s
    return pts


def write(name, description, points, expected, target_m=4800):
    data = {
        "description": description,
        "target_m": target_m,
        "points": points,
        "expected": expected,
    }
    (OUT / f"{name}.json").write_text(json.dumps(data, separators=(",", ":")) + "\n")


def main():
    # 1. Steady 4.8 km in about 25 minutes (3.2 m/s), good signal.
    rng = random.Random(1)
    pts = run(lambda t: 3.2, 1560, rng)
    write("good_4800_steady", "UP Police pace 4.8 km at 3.2 m/s on a 400 m loop, 1 Hz, accuracy 4-10 m.", pts,
          {"verdict": "verified", "flags": [], "distance_m": [4800, 5250], "finish_seconds": [1380, 1510]})

    # 2. Run-walk beginner: 2 min run at 2.8 m/s, 1 min walk at 1.4 m/s, 20 min.
    rng = random.Random(2)
    pts = run(lambda t: 2.8 if (t % 180) < 120 else 1.4, 1200, rng)
    write("good_run_walk", "Beginner run-walk for 20 minutes; never reaches 4.8 km.", pts,
          {"verdict": "verified", "flags": [], "distance_m": [2700, 3100], "finish_seconds": None})

    # 3. Fast finish sprint: 4 min jog then 200 m at 7.5 m/s then jog. Must not be flagged.
    rng = random.Random(3)
    pts = run(lambda t: 7.5 if 240 <= t < 267 else 3.0, 420, rng)
    write("good_with_sprint", "Jog with a 200 m sprint at 7.5 m/s; a real effort that must stay verified.", pts,
          {"verdict": "verified", "flags": [], "distance_m": [1350, 1550], "finish_seconds": None})

    # 4. Teleport: 300 m jump in 2 s halfway.
    rng = random.Random(4)
    pts = run(lambda t: 3.2, 900, rng)
    for p in pts[450:]:
        p["lon"] = round(p["lon"] + 300 / M_PER_DEG_LON, 7)
    write("teleport", "Steady run with a 300 m position jump halfway.", pts,
          {"verdict": "rejected", "flags": ["teleport"], "distance_m": None, "finish_seconds": None})

    # 5. Bicycle: 5 min run, then 8 min at 7 m/s along a road.
    rng = random.Random(5)
    first = run(lambda t: 3.0, 300, rng)
    start = loop_pos(900)
    bike = run(lambda t: 7.0, 480, rng, pos=lambda d: line_pos(d, start))
    for p in bike:
        p["t"] += 301_000
    write("bicycle", "Runs 5 minutes, then rides at 7 m/s (25 km/h) for 8 minutes.", first + bike,
          {"verdict": "rejected", "flags": ["vehicle_like"], "distance_m": None, "finish_seconds": None})

    # 6. Motorbike burst: 40 s at 14 m/s in the middle of a run.
    rng = random.Random(6)
    pts = run(lambda t: 14.0 if 300 <= t < 340 else 3.0, 600, rng)
    write("motorbike_burst", "A 40 s ride at 14 m/s (50 km/h) in the middle of a run.", pts,
          {"verdict": "rejected", "flags": ["impossible_speed"], "distance_m": None, "finish_seconds": None})

    # 7. Mock location app.
    rng = random.Random(7)
    pts = run(lambda t: 3.2, 600, rng, mock=True)
    write("mock_location", "A run where the phone reports mocked locations.", pts,
          {"verdict": "rejected", "flags": ["mock_location"], "distance_m": None, "finish_seconds": None})

    # 8. Signal gap: 60 s with no fixes while covering about 200+ m.
    rng = random.Random(8)
    pts = [p for p in run(lambda t: 3.6, 900, rng) if not (400 <= p["t"] / 1000 < 470)]
    write("signal_gap", "Steady run with 70 s of lost signal covering about 250 m.", pts,
          {"verdict": "suspicious", "flags": ["signal_gap"], "distance_m": None, "finish_seconds": None})

    # 9. Poor signal: 40% of fixes with 50 m accuracy.
    rng = random.Random(9)
    pts = run(lambda t: 3.2, 900, rng)
    for i, p in enumerate(pts):
        if i % 5 < 2:
            p["acc"] = 50.0
    write("poor_signal", "40% of fixes report 50 m accuracy.", pts,
          {"verdict": "suspicious", "flags": ["poor_signal"], "distance_m": None, "finish_seconds": None})

    # 10. Standing still for 5 minutes with GPS noise.
    rng = random.Random(10)
    pts = run(lambda t: 0.0, 300, rng, noise=1.0)
    write("standing_still", "Phone lying still for 5 minutes; jitter must not add up to a run.", pts,
          {"verdict": "suspicious", "flags": ["too_short"], "distance_m": [0, 150], "finish_seconds": None})

    # 11. Sparse samples: one fix every 15 s.
    rng = random.Random(11)
    pts = run(lambda t: 3.2, 900, rng, step_s=15.0)
    write("sparse_samples", "One fix every 15 seconds.", pts,
          {"verdict": "suspicious", "flags": ["sparse_samples"], "distance_m": None, "finish_seconds": None})

    # 12. SSC GD 5 km at 3.6 m/s.
    rng = random.Random(12)
    pts = run(lambda t: 3.6, 1440, rng)
    write("good_5000_ssc", "SSC GD pace, 5 km at 3.6 m/s.", pts,
          {"verdict": "verified", "flags": [], "distance_m": [5000, 5450], "finish_seconds": [1290, 1400]},
          target_m=5000)


if __name__ == "__main__":
    main()
