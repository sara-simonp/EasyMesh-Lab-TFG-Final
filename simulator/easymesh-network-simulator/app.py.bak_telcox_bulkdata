#!/usr/bin/env python3
"""
EasyMesh realistic telemetry simulator for a TFG lab.

Scope: behaviour/telemetry simulator. It does not implement a certified Wi-Fi PHY,
IEEE 1905.1 control plane or real EasyMesh controller. It models the metrics that an
ISP/NMS/ACS would use to evaluate QoE in a residential EasyMesh topology.
"""

from __future__ import annotations

import csv
import json
import math
import os
import random
import threading
import time
import urllib.parse
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Any, Dict, List, Tuple

PORT = int(os.environ.get("SIM_PORT", "9200"))
DATA_DIR = os.environ.get("DATA_DIR", "/data")
WRITE_TR181_CSV = os.environ.get("WRITE_TR181_CSV", "1") == "1"
STATE_FILE = os.path.join(DATA_DIR, "easymesh_simulator_state.json")
CSV_FILE = os.path.join(DATA_DIR, "data_model_easymesh.csv")
SUMMARY_FILE = os.path.join(DATA_DIR, "easymesh_simulator_summary.txt")

DEVICE_ID = os.environ.get("DEVICE_ID", "535241-EasyMeshVirtualCPE-200001")
RANDOM_SEED = int(os.environ.get("RANDOM_SEED", "2526"))
random.seed(RANDOM_SEED)

LOCK = threading.Lock()
START_TIME = time.time()
STATE: Dict[str, Any] = {}
SCENARIO = os.environ.get("DEFAULT_SCENARIO", "normal")
LAST_SCENARIO = SCENARIO
MOBILE_AP = "AP_SALON"
STEERING_COUNT = 0
LAST_EVENT = {"type": "None", "from_device": "", "to_device": "", "result": "NoEvent", "reason": ""}

# Coordinates are in arbitrary house units/metres. Obstacles and interference are
# deliberately simple but create realistic trends: distance, walls, noise, congestion.
APS = {
    "AP_SALON": {
        "device_index": 1,
        "role": "gateway_agent",
        "almac": "AA:BB:CC:00:01:01",
        "mac": "AA:BB:CC:10:01:01",
        "ipv4": "172.25.0.41",
        "x": 0.0,
        "y": 0.0,
        "backhaul_type": "Ethernet",
        "base_backhaul_rssi": 0.0,
        "radios": [
            {"id": 1, "name": "wlan0", "band": "2.4GHz", "channel": 1, "freq": 2412, "width": "40MHz", "standard": "802.11n/ax", "tx_power": 18},
            {"id": 2, "name": "wlan2", "band": "5GHz", "channel": 36, "freq": 5180, "width": "80MHz", "standard": "802.11ac/ax", "tx_power": 20},
        ],
    },
    "AP_DORMITORIO": {
        "device_index": 2,
        "role": "satellite_agent",
        "almac": "AA:BB:CC:00:02:01",
        "mac": "AA:BB:CC:10:02:01",
        "ipv4": "172.25.0.42",
        "x": 10.0,
        "y": 0.0,
        "backhaul_type": "WiFi-5GHz",
        "base_backhaul_rssi": -51.0,
        "radios": [
            {"id": 1, "name": "wlan0", "band": "2.4GHz", "channel": 6, "freq": 2437, "width": "40MHz", "standard": "802.11n/ax", "tx_power": 18},
            {"id": 2, "name": "wlan2", "band": "5GHz", "channel": 149, "freq": 5745, "width": "80MHz", "standard": "802.11ac/ax", "tx_power": 20},
        ],
    },
}

BASE_CLIENTS = [
    {"name": "PORTATIL_SARA", "mac": "DE:AD:BE:EF:00:01", "ip": "192.168.1.21", "service": "video", "home_ap": "AP_SALON", "x": 1.4, "y": 1.1, "load": 0.28, "preferred_band": "5GHz"},
    {"name": "MOVIL_SARA", "mac": "DE:AD:BE:EF:00:02", "ip": "192.168.1.34", "service": "mixed", "home_ap": "AP_SALON", "x": 2.0, "y": 0.8, "load": 0.30, "preferred_band": "5GHz"},
    {"name": "TABLET", "mac": "DE:AD:BE:EF:00:03", "ip": "192.168.1.45", "service": "web", "home_ap": "AP_DORMITORIO", "x": 10.8, "y": 1.2, "load": 0.22, "preferred_band": "5GHz"},
]

VALID_SCENARIOS = ["normal", "coverage", "interference", "saturation", "roaming", "backhaul_degraded", "ap_failure", "mixed"]


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def clamp(v: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, v))


def dist_xy(a: Dict[str, float], b: Dict[str, float]) -> float:
    return math.sqrt((a["x"] - b["x"]) ** 2 + (a["y"] - b["y"]) ** 2)


def wall_penalty(ap_name: str, x: float) -> float:
    # A simple floorplan model: between salon and dormitorio there are two walls.
    if ap_name == "AP_SALON" and x > 5.2:
        return 9.0
    if ap_name == "AP_DORMITORIO" and x < 4.8:
        return 8.0
    return 0.0


def scenario_params(scenario: str, elapsed: float) -> Dict[str, Any]:
    # phase oscillates within a 180 s scenario window.
    phase = elapsed % 180.0
    wave = 0.5 + 0.5 * math.sin((phase / 180.0) * 2.0 * math.pi - math.pi / 2.0)

    if scenario == "normal":
        return {
            "description": "Cobertura estable, baja interferencia y baja carga.",
            "mobile_x": 2.0 + 0.25 * math.sin(elapsed / 23), "mobile_y": 0.8,
            "salon_interference": 0.08, "dorm_interference": 0.09,
            "traffic_multiplier": 1.0, "background_clients": 0,
            "backhaul_degradation": 0.0, "ap_failure": None,
        }
    if scenario == "coverage":
        return {
            "description": "El cliente se desplaza hasta zona de cobertura limite.",
            "mobile_x": 2.0 + 6.5 * wave, "mobile_y": 1.0,
            "salon_interference": 0.16, "dorm_interference": 0.15,
            "traffic_multiplier": 1.1, "background_clients": 0,
            "backhaul_degradation": 0.0, "ap_failure": None,
        }
    if scenario == "interference":
        return {
            "description": "Interferencia elevada en AP_SALON por canal solapado.",
            "mobile_x": 2.3, "mobile_y": 0.9,
            "salon_interference": 0.88, "dorm_interference": 0.20,
            "traffic_multiplier": 1.15, "background_clients": 1,
            "backhaul_degradation": 0.0, "ap_failure": None,
        }
    if scenario == "saturation":
        return {
            "description": "Trafico intensivo y saturacion de radio en el AP principal.",
            "mobile_x": 2.1, "mobile_y": 0.8,
            "salon_interference": 0.42, "dorm_interference": 0.32,
            "traffic_multiplier": 2.8, "background_clients": 7,
            "backhaul_degradation": 0.0, "ap_failure": None,
        }
    if scenario == "roaming":
        return {
            "description": "Movimiento de MOVIL_SARA y steering hacia el satelite.",
            "mobile_x": 1.8 + 8.6 * wave, "mobile_y": 1.0,
            "salon_interference": 0.18, "dorm_interference": 0.14,
            "traffic_multiplier": 1.25, "background_clients": 1,
            "backhaul_degradation": 0.0, "ap_failure": None,
        }
    if scenario == "backhaul_degraded":
        return {
            "description": "Backhaul WiFi del satelite degradado: peor RSSI, mas latencia y perdida.",
            "mobile_x": 9.5, "mobile_y": 0.7,
            "salon_interference": 0.15, "dorm_interference": 0.25,
            "traffic_multiplier": 1.25, "background_clients": 2,
            "backhaul_degradation": 0.85, "ap_failure": None,
        }
    if scenario == "ap_failure":
        return {
            "description": "Fallo del satelite: clientes forzados al AP principal con peor cobertura.",
            "mobile_x": 8.8, "mobile_y": 0.9,
            "salon_interference": 0.30, "dorm_interference": 1.0,
            "traffic_multiplier": 1.4, "background_clients": 2,
            "backhaul_degradation": 1.0, "ap_failure": "AP_DORMITORIO",
        }
    if scenario == "mixed":
        # four phases: normal, coverage, interference, saturation/roaming.
        slot = int((elapsed % 240) // 60)
        return scenario_params(["normal", "coverage", "interference", "roaming"][slot], elapsed)

    return scenario_params("normal", elapsed)


def estimate_rssi(ap_name: str, client: Dict[str, Any], interference: float) -> float:
    ap = APS[ap_name]
    d = max(0.4, dist_xy(ap, client))
    # Log-distance path loss. 5 GHz gets a small additional penalty when preferred.
    band_penalty = 2.0 if client.get("preferred_band") == "5GHz" else 0.0
    rssi = -35.0 - 24.0 * math.log10(d + 1.0) - wall_penalty(ap_name, client["x"]) - band_penalty - 7.0 * interference
    rssi += random.uniform(-1.8, 1.8)
    return round(clamp(rssi, -92, -34), 1)


def mcs_from_snr(snr: float) -> Tuple[str, float]:
    # Very approximate mapping used for telemetry/QoE simulation, not PHY conformance.
    if snr >= 35: return "MCS11", 1201.0
    if snr >= 30: return "MCS9", 866.0
    if snr >= 25: return "MCS7", 585.0
    if snr >= 20: return "MCS5", 300.0
    if snr >= 15: return "MCS3", 144.0
    if snr >= 10: return "MCS1", 72.0
    return "MCS0", 24.0


def radio_noise(interference: float) -> float:
    return round(-96.0 + 22.0 * interference + random.uniform(-1.5, 1.5), 1)


def compute_radio_util(client_load: float, sta_count: int, interference: float) -> float:
    util = 18.0 + 16.0 * client_load + 4.5 * sta_count + 42.0 * interference + random.uniform(-3.0, 3.0)
    return round(clamp(util, 5.0, 98.0), 1)


def rates_and_quality(signal: float, noise: float, utilization: float, traffic_load: float, backhaul_penalty: float) -> Dict[str, float]:
    snr = round(signal - noise, 1)
    mcs, phy = mcs_from_snr(snr)
    contention = clamp(1.0 - utilization / 135.0, 0.18, 1.0)
    # negotiated PHY rates and practical throughput.
    down_phy = round(phy * contention, 1)
    up_phy = round((phy * 0.62) * contention, 1)
    demand_down = 18.0 + traffic_load * 180.0
    demand_up = 5.0 + traffic_load * 65.0
    throughput_down = round(min(demand_down, down_phy * 0.68) * (1.0 - 0.22 * backhaul_penalty), 1)
    throughput_up = round(min(demand_up, up_phy * 0.62) * (1.0 - 0.18 * backhaul_penalty), 1)
    latency = round(8.0 + max(0, -signal - 62) * 1.6 + max(0, utilization - 45) * 0.38 + backhaul_penalty * 23 + random.uniform(0, 3), 1)
    jitter = round(2.0 + max(0, utilization - 55) * 0.13 + backhaul_penalty * 8 + random.uniform(0, 2.2), 1)
    pkt_loss = round(clamp(max(0, -signal - 70) * 0.60 + max(0, utilization - 78) * 0.20 + backhaul_penalty * 4.0, 0, 35), 2)
    retry = round(clamp(max(0, -signal - 58) * 1.0 + utilization * 0.10 + backhaul_penalty * 6.0, 0, 80), 1)
    return {
        "snr": snr, "mcs": mcs, "phy_down": down_phy, "phy_up": up_phy,
        "throughput_down": throughput_down, "throughput_up": throughput_up,
        "latency": latency, "jitter": jitter, "packet_loss": pkt_loss, "retry": retry,
    }


def qoe(signal: float, utilization: float, latency: float, packet_loss: float, service: str, event_type: str) -> Tuple[int, str, str]:
    score = 100.0
    reasons = []
    if signal < -60:
        score -= (-60 - signal) * 1.6
        reasons.append("RSSI bajo")
    if utilization > 55:
        score -= (utilization - 55) * 0.9
        reasons.append("radio cargada")
    if latency > 35:
        score -= (latency - 35) * 0.75
        reasons.append("latencia alta")
    if packet_loss > 1.5:
        score -= packet_loss * 4.0
        reasons.append("perdida de paquetes")
    if service in ["gaming", "voice"] and latency > 25:
        score -= 8
    if event_type in ["APFailure", "BackhaulDegraded"]:
        score -= 10
    score = int(round(clamp(score, 0, 100)))
    if score >= 80:
        state = "Buena"
    elif score >= 60:
        state = "Media"
    elif score >= 40:
        state = "Degradada"
    else:
        state = "Critica"
    return score, state, ", ".join(reasons) if reasons else "sin degradacion relevante"


def qoe_numeric(state: str) -> int:
    return {"Desconocida": 0, "Critica": 1, "Degradada": 2, "Media": 3, "Buena": 4, "Recuperada": 5}.get(state, 0)


def build_clients(params: Dict[str, Any]) -> List[Dict[str, Any]]:
    clients = [dict(c) for c in BASE_CLIENTS]
    for c in clients:
        if c["name"] == "MOVIL_SARA":
            c["x"] = params["mobile_x"]
            c["y"] = params["mobile_y"]
            c["load"] *= params["traffic_multiplier"]
    for i in range(int(params.get("background_clients", 0))):
        clients.append({
            "name": f"INVITADO_{i+1:02d}",
            "mac": f"DE:AD:BE:EF:10:{i+1:02X}",
            "ip": f"192.168.1.{80+i}",
            "service": "background",
            "home_ap": "AP_SALON" if i % 2 == 0 else "AP_DORMITORIO",
            "x": 1.5 + (i % 4) * 1.1 if i % 2 == 0 else 8.8 + (i % 3) * 0.6,
            "y": 1.2 + (i % 3) * 0.5,
            "load": 0.18 + 0.06 * (i % 3),
            "preferred_band": "5GHz" if i % 3 else "2.4GHz",
        })
    return clients


def select_ap_for_client(client: Dict[str, Any], params: Dict[str, Any], previous_mobile_ap: str) -> Tuple[str, Dict[str, float]]:
    rssi = {
        "AP_SALON": estimate_rssi("AP_SALON", client, params["salon_interference"]),
        "AP_DORMITORIO": estimate_rssi("AP_DORMITORIO", client, params["dorm_interference"]),
    }
    if params.get("ap_failure") == "AP_DORMITORIO":
        rssi["AP_DORMITORIO"] = -95.0
    if params.get("ap_failure") == "AP_SALON":
        rssi["AP_SALON"] = -95.0

    if client["name"] == "MOVIL_SARA":
        current = previous_mobile_ap
        alt = "AP_DORMITORIO" if current == "AP_SALON" else "AP_SALON"
        # Steering threshold: low current RSSI and alternative clearly better.
        if rssi[current] <= -68 and rssi[alt] >= rssi[current] + 8:
            return alt, rssi
        return current, rssi

    # Static clients normally remain at home AP unless that AP failed.
    home = client["home_ap"]
    if params.get("ap_failure") == home:
        return "AP_DORMITORIO" if home == "AP_SALON" else "AP_SALON", rssi
    return home, rssi


def build_state() -> Dict[str, Any]:
    global LAST_SCENARIO, MOBILE_AP, STEERING_COUNT, LAST_EVENT

    elapsed = time.time() - START_TIME
    params = scenario_params(SCENARIO, elapsed)
    if SCENARIO != LAST_SCENARIO:
        MOBILE_AP = "AP_SALON"
        LAST_SCENARIO = SCENARIO
        LAST_EVENT = {"type": "None", "from_device": "", "to_device": "", "result": "NoEvent", "reason": "scenario changed"}

    clients_raw = build_clients(params)
    assigned: Dict[str, List[Dict[str, Any]]] = {"AP_SALON": [], "AP_DORMITORIO": []}
    mobile_before = MOBILE_AP
    mobile_rssi_seen = {}

    for c in clients_raw:
        ap_name, rssi_map = select_ap_for_client(c, params, MOBILE_AP)
        if c["name"] == "MOVIL_SARA":
            mobile_rssi_seen = rssi_map
            if ap_name != MOBILE_AP:
                STEERING_COUNT += 1
                LAST_EVENT = {
                    "type": "ClientSteering",
                    "from_device": MOBILE_AP,
                    "to_device": ap_name,
                    "result": "Success",
                    "reason": f"target RSSI {rssi_map[ap_name]} dBm vs current {rssi_map[MOBILE_AP]} dBm",
                }
                MOBILE_AP = ap_name
            elif rssi_map[ap_name] <= -70:
                alt = "AP_DORMITORIO" if ap_name == "AP_SALON" else "AP_SALON"
                LAST_EVENT = {"type": "LowRSSI", "from_device": ap_name, "to_device": alt, "result": "CandidateForSteering", "reason": f"RSSI {rssi_map[ap_name]} dBm"}
        assigned[ap_name].append(c)

    # Scenario-specific event if no fresh roaming event takes precedence.
    if SCENARIO == "interference":
        LAST_EVENT = {"type": "HighInterference", "from_device": "AP_SALON", "to_device": "", "result": "RadioQualityDegraded", "reason": "noise floor increased"}
    elif SCENARIO == "saturation":
        LAST_EVENT = {"type": "HighUtilization", "from_device": "AP_SALON", "to_device": "", "result": "RadioSaturation", "reason": "traffic load high"}
    elif SCENARIO == "backhaul_degraded":
        LAST_EVENT = {"type": "BackhaulDegraded", "from_device": "AP_DORMITORIO", "to_device": "GW_MASTER", "result": "QoEImpact", "reason": "weak wireless backhaul"}
    elif SCENARIO == "ap_failure":
        LAST_EVENT = {"type": "APFailure", "from_device": "AP_DORMITORIO", "to_device": "", "result": "ClientsReassociated", "reason": "satellite offline"}
    elif SCENARIO == "normal" and mobile_before == MOBILE_AP:
        LAST_EVENT = {"type": "None", "from_device": "", "to_device": "", "result": "NoEvent", "reason": "stable"}

    ap_states: Dict[str, Any] = {}
    total_traffic_load = sum(float(c["load"]) for c in clients_raw)

    for ap_name, ap in APS.items():
        offline = params.get("ap_failure") == ap_name
        interference = params["salon_interference"] if ap_name == "AP_SALON" else params["dorm_interference"]
        client_load = sum(float(c["load"]) for c in assigned[ap_name])
        sta_count = len(assigned[ap_name])
        util24 = 0.0 if offline else compute_radio_util(client_load, sta_count, interference)
        util5 = 0.0 if offline else round(clamp(util24 - 7 + random.uniform(-2, 2), 3, 98), 1)
        noise = radio_noise(interference)
        backhaul_degradation = float(params.get("backhaul_degradation", 0.0)) if ap_name == "AP_DORMITORIO" else 0.0
        backhaul_rssi = ap["base_backhaul_rssi"] - 22.0 * backhaul_degradation + random.uniform(-1, 1) if ap["backhaul_type"].startswith("WiFi") else 0.0
        backhaul_rate = 1000.0 if ap["backhaul_type"] == "Ethernet" else round(clamp(780 + (backhaul_rssi + 50) * 10, 80, 850), 1)
        backhaul_latency = round(1.0 if ap["backhaul_type"] == "Ethernet" else 4.0 + backhaul_degradation * 30.0 + random.uniform(0, 2), 1)
        backhaul_loss = round(0.0 if ap["backhaul_type"] == "Ethernet" else clamp(backhaul_degradation * 6.0 + max(0, -backhaul_rssi - 72) * 0.25, 0, 25), 2)

        ap_state = {
            "name": ap_name,
            "device_index": ap["device_index"],
            "role": ap["role"],
            "status": "Offline" if offline else "Online",
            "almac": ap["almac"],
            "mac": ap["mac"],
            "ipv4": ap["ipv4"],
            "backhaul_type": ap["backhaul_type"],
            "backhaul_rssi": round(backhaul_rssi, 1),
            "backhaul_rate_mbps": backhaul_rate,
            "backhaul_latency_ms": backhaul_latency,
            "backhaul_packet_loss_percent": backhaul_loss,
            "radios": [],
            "clients": [],
        }
        for r in ap["radios"]:
            util = util24 if r["band"] == "2.4GHz" else util5
            radio_state = {
                "id": r["id"], "name": r["name"], "band": r["band"], "channel": r["channel"], "frequency_mhz": r["freq"],
                "bandwidth": r["width"], "standard": r["standard"], "tx_power_dbm": r["tx_power"],
                "status": "Down" if offline else "Up", "utilization_percent": util,
                "noise_dbm": round(noise - (2.0 if r["band"] == "5GHz" else 0.0), 1),
                "bss_number_of_entries": 1, "sta_number_of_entries": sta_count,
                "bytes_sent": int((elapsed * 100000 + client_load * 1500000 + r["id"] * 123456) % 1000000000),
                "bytes_received": int((elapsed * 140000 + client_load * 1900000 + r["id"] * 345678) % 1000000000),
                "packets_sent": int((elapsed * 900 + client_load * 12000 + r["id"] * 111) % 10000000),
                "packets_received": int((elapsed * 1100 + client_load * 15000 + r["id"] * 222) % 10000000),
                "errors_sent": int(max(0, util - 70) * 3), "errors_received": int(max(0, util - 70) * 4),
            }
            ap_state["radios"].append(radio_state)

        util_avg = (util24 + util5) / 2.0 if not offline else 0.0
        for idx, c in enumerate(assigned[ap_name], start=1):
            rssi_map = {"AP_SALON": estimate_rssi("AP_SALON", c, params["salon_interference"]), "AP_DORMITORIO": estimate_rssi("AP_DORMITORIO", c, params["dorm_interference"])}
            signal = rssi_map[ap_name] if not offline else -95.0
            band = c.get("preferred_band", "5GHz")
            n = noise - (2.0 if band == "5GHz" else 0.0)
            quality = rates_and_quality(signal, n, util_avg, c["load"], backhaul_degradation)
            score, qstate, reason = qoe(signal, util_avg, quality["latency"], quality["packet_loss"], c["service"], LAST_EVENT["type"])
            ap_state["clients"].append({
                "sta_index": idx, "hostname": c["name"], "mac": c["mac"], "ip": c["ip"], "active": not offline,
                "interface_type": "Wi-Fi", "service": c["service"], "connected_device": ap_name,
                "connected_radio": "wlan2" if band == "5GHz" else "wlan0", "connected_band": band,
                "ssid": "SaraMesh-5G" if band == "5GHz" else "SaraMesh-24G", "bssid": ap["mac"],
                "signal_strength_dbm": signal, "noise_dbm": round(n, 1), "snr_db": quality["snr"], "mcs": quality["mcs"],
                "last_data_downlink_rate_mbps": quality["phy_down"], "last_data_uplink_rate_mbps": quality["phy_up"],
                "throughput_downlink_mbps": quality["throughput_down"], "throughput_uplink_mbps": quality["throughput_up"],
                "latency_ms": quality["latency"], "jitter_ms": quality["jitter"], "packet_loss_percent": quality["packet_loss"],
                "retry_rate_percent": quality["retry"], "qoe_score": score, "qoe_state": qstate, "qoe_reason": reason,
                "bytes_sent": int((elapsed * 90000 + idx * 73412 + c["load"] * 2000000) % 1000000000),
                "bytes_received": int((elapsed * 150000 + idx * 131071 + c["load"] * 4500000) % 1000000000),
                "packets_sent": int((elapsed * 700 + idx * 333 + c["load"] * 12000) % 10000000),
                "packets_received": int((elapsed * 1100 + idx * 555 + c["load"] * 22000) % 10000000),
                "last_connect_time": utc_now(), "last_seen_seconds": 0, "roam_count": STEERING_COUNT if c["name"] == "MOVIL_SARA" else 0,
            })
        ap_states[ap_name] = ap_state

    mobile_entry = None
    for ap_name, ap in ap_states.items():
        for c in ap["clients"]:
            if c["hostname"] == "MOVIL_SARA":
                mobile_entry = dict(c)
                mobile_entry["ap"] = ap_name
                break
    if not mobile_entry:
        mobile_entry = {"hostname": "MOVIL_SARA", "ap": "UNKNOWN", "signal_strength_dbm": -95, "qoe_state": "Critica", "qoe_score": 0}

    cpu = round(clamp(12 + 7 * total_traffic_load + random.uniform(-2, 2), 3, 95), 1)
    mem_total = 256
    mem_free = round(clamp(156 - 5 * total_traffic_load - len(clients_raw) * 1.2 + random.uniform(-2, 2), 20, 230), 1)

    state = {
        "timestamp_utc": utc_now(), "uptime_seconds": int(elapsed), "scenario": SCENARIO,
        "scenario_description": params["description"], "device_id": DEVICE_ID,
        "controller": {"name": "GW_MASTER", "status": "Running", "almac": "06:8e:01:be:ef:29", "ipv4": "172.25.0.40", "agent_number": len(APS), "total_client_number": len(clients_raw)},
        "device_info": {"manufacturer": "Sara-Lab", "manufacturer_oui": "535241", "product_class": "EasyMeshVirtualCPE", "serial_number": "200001", "software_version": "EasyMeshNetworkSimulator-1.0", "cpu_usage_percent": cpu, "memory_total_mb": mem_total, "memory_free_mb": mem_free},
        "aps": ap_states,
        "event": {**LAST_EVENT, "client": "MOVIL_SARA", "client_mac": "DE:AD:BE:EF:00:02", "timestamp_utc": utc_now(), "steering_count": STEERING_COUNT},
        "mobile_summary": {"client": "MOVIL_SARA", "ap": mobile_entry.get("ap"), "signal_strength_dbm": mobile_entry.get("signal_strength_dbm"), "snr_db": mobile_entry.get("snr_db"), "latency_ms": mobile_entry.get("latency_ms"), "jitter_ms": mobile_entry.get("jitter_ms"), "packet_loss_percent": mobile_entry.get("packet_loss_percent"), "throughput_downlink_mbps": mobile_entry.get("throughput_downlink_mbps"), "throughput_uplink_mbps": mobile_entry.get("throughput_uplink_mbps"), "qoe_score": mobile_entry.get("qoe_score"), "qoe_state": mobile_entry.get("qoe_state"), "qoe_numeric": qoe_numeric(mobile_entry.get("qoe_state", "Desconocida")), "qoe_reason": mobile_entry.get("qoe_reason")},
    }
    return state


def esc(value: Any) -> str:
    return str(value if value is not None else "").replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ")


def prom_line(metric: str, labels: Dict[str, Any], value: Any) -> str:
    label_text = ",".join(f'{k}="{esc(v)}"' for k, v in labels.items())
    return f"{metric}{{{label_text}}} {value}"


def build_prometheus(state: Dict[str, Any]) -> str:
    lines: List[str] = []
    def help_type(name: str, desc: str, typ: str = "gauge"):
        lines.append(f"# HELP {name} {desc}")
        lines.append(f"# TYPE {name} {typ}")

    help_type("easymesh_simulator_up", "Whether the EasyMesh simulator is running")
    lines.append("easymesh_simulator_up 1")
    help_type("easymesh_sim_scenario_info", "Current simulation scenario")
    lines.append(prom_line("easymesh_sim_scenario_info", {"scenario": state["scenario"], "description": state["scenario_description"]}, 1))
    help_type("easymesh_sim_device_cpu_usage_percent", "Simulated CPE CPU usage")
    lines.append(f'easymesh_sim_device_cpu_usage_percent {state["device_info"]["cpu_usage_percent"]}')
    help_type("easymesh_sim_device_memory_free_mb", "Simulated free memory")
    lines.append(f'easymesh_sim_device_memory_free_mb {state["device_info"]["memory_free_mb"]}')
    help_type("easymesh_sim_agent_number", "Number of EasyMesh agents")
    lines.append(f'easymesh_sim_agent_number {state["controller"]["agent_number"]}')
    help_type("easymesh_sim_total_client_number", "Number of Wi-Fi clients")
    lines.append(f'easymesh_sim_total_client_number {state["controller"]["total_client_number"]}')
    help_type("easymesh_sim_event_info", "Current EasyMesh event")
    lines.append(prom_line("easymesh_sim_event_info", {"type": state["event"]["type"], "from_device": state["event"]["from_device"], "to_device": state["event"]["to_device"], "result": state["event"]["result"], "reason": state["event"].get("reason", "")}, 1))
    help_type("easymesh_sim_steering_count_total", "Total steering events", "counter")
    lines.append(f'easymesh_sim_steering_count_total {state["event"]["steering_count"]}')

    metrics_defined = set()
    def metric(name, desc, typ="gauge"):
        if name not in metrics_defined:
            help_type(name, desc, typ)
            metrics_defined.add(name)

    for ap_name, ap in state["aps"].items():
        metric("easymesh_sim_ap_status", "AP status: 1 online, 0 offline")
        lines.append(prom_line("easymesh_sim_ap_status", {"ap": ap_name, "role": ap["role"]}, 1 if ap["status"] == "Online" else 0))
        metric("easymesh_sim_backhaul_rssi_dbm", "Backhaul RSSI")
        lines.append(prom_line("easymesh_sim_backhaul_rssi_dbm", {"ap": ap_name, "type": ap["backhaul_type"]}, ap["backhaul_rssi"]))
        metric("easymesh_sim_backhaul_rate_mbps", "Backhaul negotiated rate")
        lines.append(prom_line("easymesh_sim_backhaul_rate_mbps", {"ap": ap_name, "type": ap["backhaul_type"]}, ap["backhaul_rate_mbps"]))
        metric("easymesh_sim_backhaul_latency_ms", "Backhaul latency")
        lines.append(prom_line("easymesh_sim_backhaul_latency_ms", {"ap": ap_name, "type": ap["backhaul_type"]}, ap["backhaul_latency_ms"]))
        metric("easymesh_sim_backhaul_packet_loss_percent", "Backhaul packet loss")
        lines.append(prom_line("easymesh_sim_backhaul_packet_loss_percent", {"ap": ap_name, "type": ap["backhaul_type"]}, ap["backhaul_packet_loss_percent"]))
        for radio in ap["radios"]:
            labels = {"ap": ap_name, "radio": radio["name"], "band": radio["band"], "channel": radio["channel"], "standard": radio["standard"]}
            metric("easymesh_sim_radio_utilization_percent", "Radio channel utilization")
            lines.append(prom_line("easymesh_sim_radio_utilization_percent", labels, radio["utilization_percent"]))
            metric("easymesh_sim_radio_noise_dbm", "Radio noise floor")
            lines.append(prom_line("easymesh_sim_radio_noise_dbm", labels, radio["noise_dbm"]))
            metric("easymesh_sim_radio_sta_count", "Associated STA count per AP radio")
            lines.append(prom_line("easymesh_sim_radio_sta_count", labels, radio["sta_number_of_entries"]))
            metric("easymesh_sim_radio_bytes_sent", "Radio bytes sent", "counter")
            lines.append(prom_line("easymesh_sim_radio_bytes_sent", labels, radio["bytes_sent"]))
            metric("easymesh_sim_radio_bytes_received", "Radio bytes received", "counter")
            lines.append(prom_line("easymesh_sim_radio_bytes_received", labels, radio["bytes_received"]))
        for c in ap["clients"]:
            labels = {"client": c["hostname"], "ap": ap_name, "band": c["connected_band"], "service": c["service"]}
            metric("easymesh_sim_client_signal_dbm", "Client RSSI / SignalStrength")
            lines.append(prom_line("easymesh_sim_client_signal_dbm", labels, c["signal_strength_dbm"]))
            metric("easymesh_sim_client_snr_db", "Client SNR")
            lines.append(prom_line("easymesh_sim_client_snr_db", labels, c["snr_db"]))
            metric("easymesh_sim_client_phy_rate_down_mbps", "Client last downlink PHY rate")
            lines.append(prom_line("easymesh_sim_client_phy_rate_down_mbps", labels, c["last_data_downlink_rate_mbps"]))
            metric("easymesh_sim_client_phy_rate_up_mbps", "Client last uplink PHY rate")
            lines.append(prom_line("easymesh_sim_client_phy_rate_up_mbps", labels, c["last_data_uplink_rate_mbps"]))
            metric("easymesh_sim_client_throughput_down_mbps", "Client downlink throughput")
            lines.append(prom_line("easymesh_sim_client_throughput_down_mbps", labels, c["throughput_downlink_mbps"]))
            metric("easymesh_sim_client_throughput_up_mbps", "Client uplink throughput")
            lines.append(prom_line("easymesh_sim_client_throughput_up_mbps", labels, c["throughput_uplink_mbps"]))
            metric("easymesh_sim_client_latency_ms", "Client service latency")
            lines.append(prom_line("easymesh_sim_client_latency_ms", labels, c["latency_ms"]))
            metric("easymesh_sim_client_jitter_ms", "Client service jitter")
            lines.append(prom_line("easymesh_sim_client_jitter_ms", labels, c["jitter_ms"]))
            metric("easymesh_sim_client_packet_loss_percent", "Client packet loss")
            lines.append(prom_line("easymesh_sim_client_packet_loss_percent", labels, c["packet_loss_percent"]))
            metric("easymesh_sim_client_retry_rate_percent", "Client retry rate")
            lines.append(prom_line("easymesh_sim_client_retry_rate_percent", labels, c["retry_rate_percent"]))
            metric("easymesh_sim_client_qoe_score", "Client QoE score 0-100")
            lines.append(prom_line("easymesh_sim_client_qoe_score", {**labels, "state": c["qoe_state"]}, c["qoe_score"]))
    mobile = state["mobile_summary"]
    metric("easymesh_sim_mobile_qoe_state", "MOVIL_SARA QoE numeric state")
    lines.append(prom_line("easymesh_sim_mobile_qoe_state", {"client": "MOVIL_SARA", "ap": mobile.get("ap"), "state": mobile.get("qoe_state"), "reason": mobile.get("qoe_reason")}, mobile.get("qoe_numeric", 0)))
    metric("easymesh_sim_last_update_timestamp_seconds", "Last simulator update timestamp")
    lines.append(f"easymesh_sim_last_update_timestamp_seconds {int(time.time())}")
    return "\n".join(lines) + "\n"


def csv_write_object(rows: List[List[str]], path: str):
    rows.append([path, "true", "false", "", ""])


def csv_write_param(rows: List[List[str]], path: str, value: Any, xtype: str):
    rows.append([path, "false", "false", "" if value is None else str(value), xtype])


def write_tr181_csv(state: Dict[str, Any]) -> None:
    os.makedirs(DATA_DIR, exist_ok=True)
    rows: List[List[str]] = []
    # Root objects
    for obj in ["InternetGatewayDevice", "InternetGatewayDevice.DeviceInfo", "InternetGatewayDevice.X_SARA_EasyMesh", "Device", "Device.DeviceInfo", "Device.WiFi", "Device.WiFi.DataElements", "Device.WiFi.DataElements.Network", "Device.WiFi.AccessPoint", "Device.Hosts", "Device.Hosts.Host", "Device.X_SARA_QoE"]:
        csv_write_object(rows, obj)

    di = state["device_info"]
    # DeviceInfo, both legacy and TR-181 style.
    for prefix in ["InternetGatewayDevice.DeviceInfo", "Device.DeviceInfo"]:
        csv_write_param(rows, f"{prefix}.Manufacturer", di["manufacturer"], "xsd:string")
        csv_write_param(rows, f"{prefix}.ManufacturerOUI", di["manufacturer_oui"], "xsd:string")
        csv_write_param(rows, f"{prefix}.ProductClass", di["product_class"], "xsd:string")
        csv_write_param(rows, f"{prefix}.SerialNumber", di["serial_number"], "xsd:string")
        csv_write_param(rows, f"{prefix}.SoftwareVersion", di["software_version"], "xsd:string")
        csv_write_param(rows, f"{prefix}.UpTime", state["uptime_seconds"], "xsd:unsignedInt")
    csv_write_object(rows, "Device.DeviceInfo.MemoryStatus")
    csv_write_param(rows, "Device.DeviceInfo.MemoryStatus.Total", di["memory_total_mb"], "xsd:unsignedInt")
    csv_write_param(rows, "Device.DeviceInfo.MemoryStatus.Free", di["memory_free_mb"], "xsd:unsignedInt")
    csv_write_object(rows, "Device.DeviceInfo.ProcessStatus")
    csv_write_param(rows, "Device.DeviceInfo.ProcessStatus.CPUUsage", di["cpu_usage_percent"], "xsd:unsignedInt")

    xs = "InternetGatewayDevice.X_SARA_EasyMesh"
    csv_write_param(rows, f"{xs}.Profile", "DynamicTelemetrySimulator", "xsd:string")
    csv_write_param(rows, f"{xs}.ScenarioId", state["scenario"], "xsd:string")
    csv_write_param(rows, f"{xs}.ScenarioName", state["scenario_description"], "xsd:string")
    csv_write_param(rows, f"{xs}.LastUpdateUTC", state["timestamp_utc"], "xsd:string")
    csv_write_param(rows, f"{xs}.Source", "easymesh_network_simulator_dynamic", "xsd:string")
    csv_write_param(rows, f"{xs}.ControllerStatus", state["controller"]["status"], "xsd:string")
    csv_write_param(rows, f"{xs}.GatewayName", state["controller"]["name"], "xsd:string")
    csv_write_param(rows, f"{xs}.GatewayMac", state["controller"]["almac"], "xsd:string")
    csv_write_param(rows, f"{xs}.RadioNumber", 2, "xsd:unsignedInt")
    csv_write_object(rows, f"{xs}.Controller")
    for p, v, t in [("Status", state["controller"]["status"], "xsd:string"), ("Name", state["controller"]["name"], "xsd:string"), ("ALMAC", state["controller"]["almac"], "xsd:string"), ("IPv4Address", state["controller"]["ipv4"], "xsd:string"), ("AgentNumber", state["controller"]["agent_number"], "xsd:unsignedInt"), ("TotalClientNumber", state["controller"]["total_client_number"], "xsd:unsignedInt"), ("LastTopologyUpdate", state["timestamp_utc"], "xsd:string")]:
        csv_write_param(rows, f"{xs}.Controller.{p}", v, t)

    de_ctrl = "Device.WiFi.DataElements.Network.Controller"
    csv_write_object(rows, de_ctrl)
    csv_write_param(rows, f"{de_ctrl}.ID", state["controller"]["almac"], "xsd:string")
    csv_write_param(rows, f"{de_ctrl}.Name", state["controller"]["name"], "xsd:string")
    csv_write_param(rows, f"{de_ctrl}.Status", state["controller"]["status"], "xsd:string")
    csv_write_param(rows, f"{de_ctrl}.AgentNumber", state["controller"]["agent_number"], "xsd:unsignedInt")
    csv_write_param(rows, f"{de_ctrl}.TotalClientNumber", state["controller"]["total_client_number"], "xsd:unsignedInt")

    csv_write_object(rows, "Device.WiFi.DataElements.Network.Device")
    host_i = 1
    ap_i = 1
    for ap_name, ap in sorted(state["aps"].items(), key=lambda kv: kv[1]["device_index"]):
        i = ap["device_index"]
        base_x = f"{xs}.Agent.{i}"
        base_de = f"Device.WiFi.DataElements.Network.Device.{i}"
        for b in [base_x, base_de]:
            csv_write_object(rows, b)
        # Legacy X_SARA agent fields
        for p, v, t in [("Name", ap_name, "xsd:string"), ("Status", ap["status"], "xsd:string"), ("ALMAC", ap["almac"], "xsd:string"), ("IPv4Address", ap["ipv4"], "xsd:string"), ("BackhaulType", ap["backhaul_type"], "xsd:string"), ("BackhaulMAC", ap["mac"], "xsd:string"), ("BackhaulRSSI", ap["backhaul_rssi"], "xsd:int"), ("BackhaulRateMbps", ap["backhaul_rate_mbps"], "xsd:unsignedInt"), ("BackhaulLatencyMs", ap["backhaul_latency_ms"], "xsd:unsignedInt"), ("BackhaulPacketLossPercent", ap["backhaul_packet_loss_percent"], "xsd:decimal"), ("RadioNumber", len(ap["radios"]), "xsd:unsignedInt"), ("ClientNumber", len(ap["clients"]), "xsd:unsignedInt")]:
            csv_write_param(rows, f"{base_x}.{p}", v, t)
        # DataElements device fields
        for p, v, t in [("Name", ap_name, "xsd:string"), ("ID", ap["almac"], "xsd:string"), ("Status", ap["status"], "xsd:string"), ("IPv4Address", ap["ipv4"], "xsd:string"), ("BackhaulType", ap["backhaul_type"], "xsd:string"), ("BackhaulMAC", ap["mac"], "xsd:string"), ("BackhaulRSSI", ap["backhaul_rssi"], "xsd:int"), ("BackhaulRateMbps", ap["backhaul_rate_mbps"], "xsd:unsignedInt"), ("BackhaulLatencyMs", ap["backhaul_latency_ms"], "xsd:unsignedInt"), ("BackhaulPacketLossPercent", ap["backhaul_packet_loss_percent"], "xsd:decimal"), ("RadioNumberOfEntries", len(ap["radios"]), "xsd:unsignedInt"), ("STANumberOfEntries", len(ap["clients"]), "xsd:unsignedInt")]:
            csv_write_param(rows, f"{base_de}.{p}", v, t)
        csv_write_object(rows, f"{base_x}.Radio")
        csv_write_object(rows, f"{base_de}.Radio")
        for radio in ap["radios"]:
            rid = radio["id"]
            for rb in [f"{base_x}.Radio.{rid}", f"{base_de}.Radio.{rid}"]:
                csv_write_object(rows, rb)
            # Common fields
            radio_params = [
                ("Name", radio["name"], "xsd:string"), ("Interface", radio["name"], "xsd:string"), ("Status", radio["status"], "xsd:string"),
                ("Band", radio["band"], "xsd:string"), ("OperatingFrequencyBand", radio["band"], "xsd:string"), ("Channel", radio["channel"], "xsd:unsignedInt"),
                ("Bandwidth", radio["bandwidth"], "xsd:string"), ("OperatingChannelBandwidth", radio["bandwidth"], "xsd:string"), ("CurrentOperatingChannelBandwidth", radio["bandwidth"], "xsd:string"),
                ("FrequencyMHz", radio["frequency_mhz"], "xsd:unsignedInt"), ("OperatingStandards", radio["standard"], "xsd:string"), ("TransmitPower", radio["tx_power_dbm"], "xsd:int"),
                ("Utilization", radio["utilization_percent"], "xsd:unsignedInt"), ("ChannelUtilization", radio["utilization_percent"], "xsd:unsignedInt"), ("Noise", radio["noise_dbm"], "xsd:int"),
                ("BSSNumberOfEntries", radio["bss_number_of_entries"], "xsd:unsignedInt"), ("STANumberOfEntries", radio["sta_number_of_entries"], "xsd:unsignedInt"),
            ]
            for p, v, t in radio_params:
                csv_write_param(rows, f"{base_de}.Radio.{rid}.{p}", v, t)
                csv_write_param(rows, f"{base_x}.Radio.{rid}.{p}", v, t)
            # Stats
            for rb in [f"{base_de}.Radio.{rid}.Stats", f"{base_x}.Radio.{rid}.Stats"]:
                csv_write_object(rows, rb)
            for p, v in [("BytesSent", radio["bytes_sent"]), ("BytesReceived", radio["bytes_received"]), ("PacketsSent", radio["packets_sent"]), ("PacketsReceived", radio["packets_received"]), ("ErrorsSent", radio["errors_sent"]), ("ErrorsReceived", radio["errors_received"])]:
                csv_write_param(rows, f"{base_de}.Radio.{rid}.Stats.{p}", v, "xsd:unsignedLong")
                csv_write_param(rows, f"{base_x}.Radio.{rid}.Stats.{p}", v, "xsd:unsignedLong")
        csv_write_object(rows, f"{base_x}.Client")
        csv_write_object(rows, f"{base_de}.STA")
        # AccessPoint object mapping
        ap_base = f"Device.WiFi.AccessPoint.{ap_i}"
        csv_write_object(rows, ap_base)
        csv_write_param(rows, f"{ap_base}.Status", "Enabled" if ap["status"] == "Online" else "Disabled", "xsd:string")
        csv_write_param(rows, f"{ap_base}.SSIDReference", "Device.WiFi.SSID.1", "xsd:string")
        csv_write_object(rows, f"{ap_base}.AssociatedDevice")
        for c in ap["clients"]:
            ci = c["sta_index"]
            for cb in [f"{base_x}.Client.{ci}", f"{base_de}.STA.{ci}", f"{ap_base}.AssociatedDevice.{ci}"]:
                csv_write_object(rows, cb)
            cparams = [
                ("Hostname", c["hostname"], "xsd:string"), ("HostName", c["hostname"], "xsd:string"), ("MACAddress", c["mac"], "xsd:string"), ("IPAddress", c["ip"], "xsd:string"),
                ("ConnectedDevice", ap_name, "xsd:string"), ("ConnectedAgent", ap_name, "xsd:string"), ("ConnectedBand", c["connected_band"], "xsd:string"), ("ConnectedRadio", c["connected_radio"], "xsd:string"),
                ("SSID", c["ssid"], "xsd:string"), ("BSSID", c["bssid"], "xsd:string"), ("SignalStrength", c["signal_strength_dbm"], "xsd:int"), ("RSSI", c["signal_strength_dbm"], "xsd:int"),
                ("Noise", c["noise_dbm"], "xsd:int"), ("SNR", c["snr_db"], "xsd:int"), ("MCS", c["mcs"], "xsd:string"),
                ("LastDataDownlinkRate", c["last_data_downlink_rate_mbps"], "xsd:unsignedInt"), ("LastDataUplinkRate", c["last_data_uplink_rate_mbps"], "xsd:unsignedInt"),
                ("ThroughputDownlinkMbps", c["throughput_downlink_mbps"], "xsd:decimal"), ("ThroughputUplinkMbps", c["throughput_uplink_mbps"], "xsd:decimal"),
                ("LatencyMs", c["latency_ms"], "xsd:decimal"), ("JitterMs", c["jitter_ms"], "xsd:decimal"), ("PacketLossPercent", c["packet_loss_percent"], "xsd:decimal"), ("RetryRatePercent", c["retry_rate_percent"], "xsd:decimal"),
                ("QoEScore", c["qoe_score"], "xsd:unsignedInt"), ("QoEState", c["qoe_state"], "xsd:string"), ("QoEReason", c["qoe_reason"], "xsd:string"),
                ("BytesSent", c["bytes_sent"], "xsd:unsignedLong"), ("BytesReceived", c["bytes_received"], "xsd:unsignedLong"), ("LastConnectTime", c["last_connect_time"], "xsd:string"), ("LastSeenSeconds", c["last_seen_seconds"], "xsd:unsignedInt"), ("RoamCount", c["roam_count"], "xsd:unsignedInt"),
            ]
            for p, v, t in cparams:
                csv_write_param(rows, f"{base_de}.STA.{ci}.{p}", v, t)
            for p, v, t in cparams:
                csv_write_param(rows, f"{base_x}.Client.{ci}.{p}", v, t)
            # AssociatedDevice subset compatible with BulkData document
            assoc_map = [
                ("MACAddress", c["mac"], "xsd:string"), ("SignalStrength", c["signal_strength_dbm"], "xsd:int"), ("LastDataDownlinkRate", c["last_data_downlink_rate_mbps"], "xsd:unsignedInt"), ("LastDataUplinkRate", c["last_data_uplink_rate_mbps"], "xsd:unsignedInt"), ("SSIDReference", "Device.WiFi.SSID.1", "xsd:string"), ("OperatingStandard", "802.11ax", "xsd:string"), ("Active", str(c["active"]).lower(), "xsd:boolean"),
            ]
            for p, v, t in assoc_map:
                csv_write_param(rows, f"{ap_base}.AssociatedDevice.{ci}.{p}", v, t)
            csv_write_object(rows, f"{ap_base}.AssociatedDevice.{ci}.Stats")
            for p, v in [("BytesSent", c["bytes_sent"]), ("BytesReceived", c["bytes_received"]), ("RetryCount", int(c["retry_rate_percent"] * 10))]:
                csv_write_param(rows, f"{ap_base}.AssociatedDevice.{ci}.Stats.{p}", v, "xsd:unsignedLong")
            # Hosts mapping
            hbase = f"Device.Hosts.Host.{host_i}"
            csv_write_object(rows, hbase)
            for p, v, t in [("HostName", c["hostname"], "xsd:string"), ("PhysAddress", c["mac"], "xsd:string"), ("IPAddress", c["ip"], "xsd:string"), ("ClientID", c["mac"], "xsd:string"), ("Active", str(c["active"]).lower(), "xsd:boolean"), ("InterfaceType", c["interface_type"], "xsd:string")]:
                csv_write_param(rows, f"{hbase}.{p}", v, t)
            host_i += 1
        ap_i += 1

    # Events and QoE summary
    for base in [f"{xs}.Event", "Device.WiFi.DataElements.Network.Event"]:
        csv_write_object(rows, base)
        csv_write_object(rows, f"{base}.1")
        e = state["event"]
        for p, v, t in [("Type", e["type"], "xsd:string"), ("ClientMAC", e["client_mac"], "xsd:string"), ("STAMACAddress", e["client_mac"], "xsd:string"), ("FromAgent", e["from_device"], "xsd:string"), ("FromDevice", e["from_device"], "xsd:string"), ("ToAgent", e["to_device"], "xsd:string"), ("ToDevice", e["to_device"], "xsd:string"), ("Result", e["result"], "xsd:string"), ("Reason", e["reason"], "xsd:string"), ("TimestampUTC", e["timestamp_utc"], "xsd:string"), ("SteeringCount", e["steering_count"], "xsd:unsignedInt")]:
            csv_write_param(rows, f"{base}.1.{p}", v, t)
    q = state["mobile_summary"]
    for p, v, t in [("Client", q["client"], "xsd:string"), ("ConnectedAP", q["ap"], "xsd:string"), ("SignalStrength", q["signal_strength_dbm"], "xsd:int"), ("LatencyMs", q["latency_ms"], "xsd:decimal"), ("PacketLossPercent", q["packet_loss_percent"], "xsd:decimal"), ("QoEScore", q["qoe_score"], "xsd:unsignedInt"), ("QoEState", q["qoe_state"], "xsd:string"), ("QoENumeric", q["qoe_numeric"], "xsd:unsignedInt"), ("Reason", q["qoe_reason"], "xsd:string")]:
        csv_write_param(rows, f"Device.X_SARA_QoE.{p}", v, t)

    tmp = CSV_FILE + ".tmp"
    with open(tmp, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["Parameter", "Object", "Writable", "Value", "Value type"])
        writer.writerows(rows)
    os.replace(tmp, CSV_FILE)
    with open(SUMMARY_FILE, "w", encoding="utf-8") as f:
        f.write(f"Scenario: {state['scenario']} - {state['scenario_description']}\n")
        f.write(f"Timestamp: {state['timestamp_utc']}\n")
        f.write(f"Mobile: {state['mobile_summary']}\n")
        f.write(f"Event: {state['event']}\n")
        f.write(f"CSV: {CSV_FILE}\n")


def simulator_loop() -> None:
    global STATE
    os.makedirs(DATA_DIR, exist_ok=True)
    while True:
        try:
            with LOCK:
                STATE = build_state()
                with open(STATE_FILE, "w", encoding="utf-8") as f:
                    json.dump(STATE, f, indent=2)
                if WRITE_TR181_CSV:
                    write_tr181_csv(STATE)
        except Exception as exc:
            print(f"[simulator] error: {exc}", flush=True)
        time.sleep(5)


class Handler(BaseHTTPRequestHandler):
    def _send(self, body: bytes, content_type: str = "text/plain; charset=utf-8", status: int = 200) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        global SCENARIO, MOBILE_AP, LAST_EVENT
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/health":
            self._send(b"OK\n")
            return
        if parsed.path == "/set":
            params = urllib.parse.parse_qs(parsed.query)
            scenario = params.get("scenario", [""])[0]
            if scenario not in VALID_SCENARIOS:
                self._send(("Invalid scenario. Valid: " + ", ".join(VALID_SCENARIOS) + "\n").encode(), status=400)
                return
            with LOCK:
                SCENARIO = scenario
                MOBILE_AP = "AP_SALON"
                LAST_EVENT = {"type": "None", "from_device": "", "to_device": "", "result": "NoEvent", "reason": "scenario changed"}
            self._send(f"Scenario set to {scenario}\n".encode())
            return
        with LOCK:
            state = STATE if STATE else build_state()
        if parsed.path in ["/", "/state"]:
            self._send(json.dumps(state, indent=2).encode("utf-8"), "application/json; charset=utf-8")
            return
        if parsed.path == "/metrics":
            self._send(build_prometheus(state).encode("utf-8"), "text/plain; version=0.0.4; charset=utf-8")
            return
        if parsed.path == "/scenarios":
            self._send(json.dumps({"valid_scenarios": VALID_SCENARIOS, "current": state["scenario"]}, indent=2).encode(), "application/json; charset=utf-8")
            return
        self._send(b"Not found\n", status=404)

    def log_message(self, fmt: str, *args: Any) -> None:
        return


if __name__ == "__main__":
    print(f"EasyMesh network simulator listening on :{PORT}", flush=True)
    print(f"TR-181 CSV output: {CSV_FILE if WRITE_TR181_CSV else 'disabled'}", flush=True)
    thread = threading.Thread(target=simulator_loop, daemon=True)
    thread.start()
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
