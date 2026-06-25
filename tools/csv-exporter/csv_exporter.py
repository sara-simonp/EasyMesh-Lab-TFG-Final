#!/usr/bin/env python3
import csv
import glob
import os
import re
import time
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer

CSV_DIR = os.environ.get("CSV_DIR", "/csv")
PORT = int(os.environ.get("CSV_EXPORTER_PORT", "9210"))

def esc(v):
    if v is None:
        return ""
    return str(v).replace("\\", "\\\\").replace("\n", " ").replace('"', '\\"')

def numeric(v):
    try:
        if v is None or str(v).strip() == "":
            return None
        return float(str(v).strip())
    except Exception:
        return None

def latest(pattern):
    files = glob.glob(os.path.join(CSV_DIR, pattern))
    if not files:
        return None
    return max(files, key=os.path.getmtime)

def scenario_from_name(path):
    name = os.path.basename(path)
    m = re.search(r"_(normal|coverage|interference|saturation|roaming|backhaul_degraded|ap_failure|mixed)_\d{8}_\d{6}", name)
    if m:
        return m.group(1)
    return "unknown"

def ts_file(path):
    try:
        return int(os.path.getmtime(path))
    except Exception:
        return 0

def build_metrics():
    lines = []
    lines.append("# HELP easymesh_csv_exporter_up CSV exporter status")
    lines.append("# TYPE easymesh_csv_exporter_up gauge")
    lines.append("easymesh_csv_exporter_up 1")

    tr181_files = glob.glob(os.path.join(CSV_DIR, "data_model_easymesh_*.csv"))
    prom_files = glob.glob(os.path.join(CSV_DIR, "metricas_prometheus_*.csv"))

    lines.append("# HELP easymesh_csv_snapshots_total Number of CSV snapshots available")
    lines.append("# TYPE easymesh_csv_snapshots_total gauge")
    lines.append(f'easymesh_csv_snapshots_total{{kind="tr181"}} {len(tr181_files)}')
    lines.append(f'easymesh_csv_snapshots_total{{kind="prometheus_metrics"}} {len(prom_files)}')

    latest_tr181 = latest("data_model_easymesh_*.csv")
    latest_prom = latest("metricas_prometheus_*.csv")

    if latest_tr181:
        scenario = scenario_from_name(latest_tr181)
        fname = os.path.basename(latest_tr181)

        lines.append("# HELP easymesh_csv_latest_snapshot_timestamp_seconds Last TR-181 CSV snapshot timestamp")
        lines.append("# TYPE easymesh_csv_latest_snapshot_timestamp_seconds gauge")
        lines.append(
            f'easymesh_csv_latest_snapshot_timestamp_seconds{{kind="tr181",scenario="{esc(scenario)}",file="{esc(fname)}"}} {ts_file(latest_tr181)}'
        )

        with open(latest_tr181, newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for row in reader:
                param = row.get("Parameter", "")
                value = row.get("Value", "")
                vtype = row.get("Value type", "")
                n = numeric(value)

                if n is not None:
                    lines.append(
                        f'easymesh_csv_tr181_numeric_value{{scenario="{esc(scenario)}",parameter="{esc(param)}",value_type="{esc(vtype)}",file="{esc(fname)}"}} {n}'
                    )

                important_text = (
                    "ScenarioId" in param or
                    "ScenarioName" in param or
                    "Event.1.Type" in param or
                    "Event.1.Result" in param or
                    "Event.1.FromDevice" in param or
                    "Event.1.ToDevice" in param or
                    "Device.X_SARA_QoE.ConnectedAP" in param or
                    "Device.X_SARA_QoE.QoEState" in param
                )

                if important_text and value != "":
                    lines.append(
                        f'easymesh_csv_tr181_info{{scenario="{esc(scenario)}",parameter="{esc(param)}",value="{esc(value)}",file="{esc(fname)}"}} 1'
                    )

    if latest_prom:
        scenario = scenario_from_name(latest_prom)
        fname = os.path.basename(latest_prom)

        lines.append("# HELP easymesh_csv_prometheus_metric_value Latest Prometheus metric values stored in CSV snapshots")
        lines.append("# TYPE easymesh_csv_prometheus_metric_value gauge")

        with open(latest_prom, newline="", encoding="utf-8-sig") as f:
            reader = csv.DictReader(f)
            for row in reader:
                metric = row.get("metric", "")
                labels = row.get("labels", "")
                value = row.get("value", "")
                n = numeric(value)

                if n is None:
                    continue

                lines.append(
                    f'easymesh_csv_prometheus_metric_value{{scenario="{esc(scenario)}",source_metric="{esc(metric)}",source_labels="{esc(labels)}",file="{esc(fname)}"}} {n}'
                )

    return "\n".join(lines) + "\n"

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path not in ["/", "/metrics"]:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"not found\n")
            return

        body = build_metrics().encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        return

if __name__ == "__main__":
    print(f"CSV exporter listening on :{PORT}, reading {CSV_DIR}", flush=True)
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
