"""Queue worker simulator: the third signal shape.

Emits a sawtooth queue-depth gauge, a processing counter, and structured
logs — deliberately different curves from the two web tenants so dashboards
show variety, not four copies of the same line.
"""
import json
import math
import random
import sys
import time

from prometheus_client import Counter, Gauge, start_http_server

QUEUE_DEPTH = Gauge("worker_queue_depth", "Jobs currently waiting")
PROCESSED = Counter("worker_jobs_processed_total", "Jobs processed", ["outcome"])

CYCLE_SECONDS = 300


def log(level: str, msg: str, **fields) -> None:
    print(json.dumps({"level": level, "msg": msg, "ts": time.time(), **fields}))
    sys.stdout.flush()


def main() -> None:
    start_http_server(8000)
    log("info", "queue worker started", port=8000)
    while True:
        # Sawtooth with jitter: fills over the cycle, drains sharply.
        phase = (time.time() % CYCLE_SECONDS) / CYCLE_SECONDS
        depth = int(120 * phase + random.randint(-5, 5))
        QUEUE_DEPTH.set(max(depth, 0))

        outcome = "error" if random.random() < 0.02 else "ok"
        PROCESSED.labels(outcome=outcome).inc()
        if outcome == "error":
            log("error", "job failed", queue_depth=depth)
        elif random.random() < 0.1:
            log("info", "batch processed", queue_depth=depth)

        time.sleep(random.uniform(0.5, 2.0))


if __name__ == "__main__":
    main()
