import json
import os
import re
import time
import urllib.request
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer


GENIEACS_NBI_URL = os.getenv(
    "GENIEACS_NBI_URL",
    "http://genieacs-real:7557"
).rstrip("/")

DEVICE_ID = os.getenv(
    "GENIEACS_DEVICE_ID",
    "105A95-HX141-225A154001356"
)

EXPORTER_PORT = int(os.getenv("EXPORTER_PORT", "9108"))
ONLINE_MAX_AGE = int(os.getenv("ONLINE_MAX_AGE_SECONDS", "600"))

try:
    NODE_NAMES = {
        key.upper(): value
        for key, value in json.loads(
            os.getenv("HX141_NODE_NAMES", "{}")
        ).items()
    }
except Exception:
    NODE_NAMES = {}


def get_path(obj, path):
    current = obj

    for part in path.split("."):
        if not isinstance(current, dict):
            return None

        current = current.get(part)

        if current is None:
            return None

    return current


def leaf(obj, name):
    if not isinstance(obj, dict):
        return None

    node = obj.get(name)

    if isinstance(node, dict):
        return node.get("_value")

    return None


def leaf_timestamp(obj, name):
    if not isinstance(obj, dict):
        return 0

    node = obj.get(name)

    if not isinstance(node, dict):
        return 0

    value = node.get("_timestamp")

    if not value:
        return 0

    try:
        return datetime.fromisoformat(
            str(value).replace("Z", "+00:00")
        ).timestamp()
    except Exception:
        return 0


def numeric_children(obj):
    if not isinstance(obj, dict):
        return []

    result = []

    for key, value in obj.items():
        if str(key).isdigit():
            result.append((int(key), str(key), value))

    return sorted(result, key=lambda item: item[0])


def normalize_mac(value):
    if value is None:
        return ""

    return str(value).upper().replace("-", ":")


def escape_label(value):
    if value is None:
        return ""

    return (
        str(value)
        .replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", " ")
    )


def numeric(value):
    if value is None or value == "":
        return None

    if isinstance(value, bool):
        return 1 if value else 0

    try:
        return float(value)
    except Exception:
        return None


def bandwidth_mhz(value):
    if value is None:
        return None

    match = re.search(r"([0-9]+(?:\.[0-9]+)?)", str(value))

    if not match:
        return None

    return float(match.group(1))


def add_metric(lines, name, value, labels=None):
    number = numeric(value)

    if number is None:
        return

    labels = labels or {}

    if labels:
        label_text = ",".join(
            f'{key}="{escape_label(label_value)}"'
            for key, label_value in labels.items()
        )

        lines.append(f"{name}{{{label_text}}} {number}")
    else:
        lines.append(f"{name} {number}")


def add_info(lines, name, labels):
    label_text = ",".join(
        f'{key}="{escape_label(value)}"'
        for key, value in labels.items()
    )

    lines.append(f"{name}{{{label_text}}} 1")


def fetch_device():
    url = f"{GENIEACS_NBI_URL}/devices/"

    with urllib.request.urlopen(url, timeout=10) as response:
        devices = json.loads(response.read().decode("utf-8"))

    for device in devices:
        if device.get("_id") == DEVICE_ID:
            return device

    raise RuntimeError(
        f"Dispositivo {DEVICE_ID} no encontrado en GenieACS"
    )


def parse_last_inform(value):
    if not value:
        return 0

    try:
        return datetime.fromisoformat(
            str(value).replace("Z", "+00:00")
        ).timestamp()
    except Exception:
        return 0


def build_host_map(device):
    host_map = {}

    hosts = get_path(device, "Device.Hosts.Host")

    for _, _, host in numeric_children(hosts):
        mac = normalize_mac(leaf(host, "PhysAddress"))

        if not mac:
            continue

        host_map[mac] = {
            "hostname": leaf(host, "HostName") or "",
            "ip": leaf(host, "IPAddress") or "",
            "active": leaf(host, "Active"),
            "interface": leaf(host, "InterfaceType") or "",
        }

    return host_map


def build_metrics():
    device = fetch_device()
    lines = []

    lines.extend([
        "# TYPE genieacs_up gauge",
        "# TYPE hx141_controller_online gauge",
        "# TYPE hx141_last_inform_age_seconds gauge",
        "# TYPE easymesh_dataelements_nodes gauge",
        "# TYPE easymesh_multiap_entries gauge",
        "# TYPE easymesh_node_active gauge",
        "# TYPE easymesh_backhaul_link_rate_mbps gauge",
        "# TYPE easymesh_backhaul_signal_raw gauge",
        "# TYPE easymesh_backhaul_signal_level gauge",
        "# TYPE easymesh_radio_channel gauge",
        "# TYPE easymesh_radio_bandwidth_mhz gauge",
        "# TYPE easymesh_ap_associated_clients gauge",
        "# TYPE easymesh_client_connected gauge",
        "# TYPE easymesh_client_signal_strength gauge",
        "# TYPE easymesh_client_downlink_rate_mbps gauge",
        "# TYPE easymesh_client_uplink_rate_mbps gauge",
        "# TYPE easymesh_client_bytes_sent_total counter",
        "# TYPE easymesh_client_bytes_received_total counter",
    ])

    lines.append("genieacs_up 1")

    last_inform = parse_last_inform(device.get("_lastInform"))
    inform_age = max(0, time.time() - last_inform) if last_inform else 0

    add_metric(
        lines,
        "hx141_last_inform_age_seconds",
        inform_age
    )

    add_metric(
        lines,
        "hx141_controller_online",
        1 if last_inform and inform_age <= ONLINE_MAX_AGE else 0
    )

    dataelements_count = get_path(
        device,
        "Device.WiFi.DataElements.Network.DeviceNumberOfEntries"
    )

    multiap_count = get_path(
        device,
        "Device.WiFi.MultiAP.APDeviceNumberOfEntries"
    )

    add_metric(
        lines,
        "easymesh_dataelements_nodes",
        dataelements_count.get("_value")
        if isinstance(dataelements_count, dict)
        else None
    )

    add_metric(
        lines,
        "easymesh_multiap_entries",
        multiap_count.get("_value")
        if isinstance(multiap_count, dict)
        else None
    )

    host_map = build_host_map(device)
    node_names = {}

    ap_devices = get_path(
        device,
        "Device.WiFi.MultiAP.APDevice"
    )

    for _, instance, node in numeric_children(ap_devices):
        mac = normalize_mac(leaf(node, "MACAddress"))
        ip = leaf(node, "X_TP_IPAddress") or ""
        serial = leaf(node, "SerialNumber") or ""
        is_controller = bool(leaf(node, "X_TP_IsController"))

        default_name = (
            "CONTROLLER"
            if is_controller
            else f"AGENTE-{instance}"
        )

        node_name = NODE_NAMES.get(mac, default_name)
        node_names[mac] = node_name

        active = leaf(node, "X_TP_Active")
        backhaul_type = leaf(node, "BackhaulLinkType") or ""
        parent_mac = normalize_mac(
            leaf(node, "BackhaulMACAddress")
        )

        base_labels = {
            "node": node_name,
            "instance": instance,
            "mac": mac,
            "ip": ip,
            "role": "controller" if is_controller else "agent",
        }

        add_info(
            lines,
            "easymesh_node_info",
            {
                **base_labels,
                "serial": serial,
                "backhaul_type": backhaul_type,
                "parent_mac": parent_mac,
            }
        )

        add_metric(
            lines,
            "easymesh_node_active",
            active,
            base_labels
        )

        add_metric(
            lines,
            "easymesh_backhaul_link_rate_mbps",
            leaf(node, "X_TP_LinkRate"),
            base_labels
        )

        add_metric(
            lines,
            "easymesh_backhaul_signal_raw",
            leaf(node, "BackhaulSignalStrength"),
            base_labels
        )

        radios = node.get("Radio", {})

        for _, radio_index, radio in numeric_children(radios):
            band = leaf(radio, "OperatingFrequencyBand") or ""

            radio_labels = {
                **base_labels,
                "radio": radio_index,
                "band": band,
            }

            add_metric(
                lines,
                "easymesh_radio_channel",
                leaf(radio, "Channel"),
                radio_labels
            )

            bandwidth = (
                leaf(radio, "CurrentOperatingChannelBandwidth")
                or leaf(radio, "OperatingChannelBandwidth")
            )

            add_metric(
                lines,
                "easymesh_radio_bandwidth_mhz",
                bandwidth_mhz(bandwidth),
                radio_labels
            )

            add_metric(
                lines,
                "easymesh_backhaul_signal_level",
                leaf(radio, "X_TP_SignalStrengthLevel"),
                radio_labels
            )

            aps = radio.get("AP", {})

            for _, ap_index, ap in numeric_children(aps):
                add_metric(
                    lines,
                    "easymesh_ap_associated_clients",
                    leaf(ap, "AssociatedDeviceNumberOfEntries"),
                    {
                        **radio_labels,
                        "ap": ap_index,
                    }
                )

    # Selección de la instancia más reciente de cada cliente.
    candidates = {}

    data_devices = get_path(
        device,
        "Device.WiFi.DataElements.Network.Device"
    )

    for _, device_index, data_node in numeric_children(data_devices):
        node_mac = normalize_mac(
            leaf(data_node, "ID")
            or leaf(data_node, "MACAddress")
        )

        node_name = NODE_NAMES.get(
            node_mac,
            node_names.get(node_mac, f"DEVICE-{device_index}")
        )

        radios = data_node.get("Radio", {})

        for _, radio_index, radio in numeric_children(radios):
            bsses = radio.get("BSS", {})

            for _, bss_index, bss in numeric_children(bsses):
                stas = bss.get("STA", {})

                for _, sta_index, sta in numeric_children(stas):
                    client_mac = normalize_mac(
                        leaf(sta, "MACAddress")
                    )

                    if not client_mac:
                        continue

                    timestamp = max(
                        leaf_timestamp(sta, "MACAddress"),
                        leaf_timestamp(sta, "SignalStrength"),
                        leaf_timestamp(sta, "BytesSent"),
                        leaf_timestamp(sta, "BytesReceived"),
                        leaf_timestamp(sta, "LastDataDownlinkRate"),
                        leaf_timestamp(sta, "LastDataUplinkRate"),
                    )

                    candidate = {
                        "timestamp": timestamp,
                        "node": node_name,
                        "node_mac": node_mac,
                        "device_index": device_index,
                        "radio_index": radio_index,
                        "bss_index": bss_index,
                        "sta_index": sta_index,
                        "client_mac": client_mac,
                        "signal": leaf(sta, "SignalStrength"),
                        "downlink": leaf(sta, "LastDataDownlinkRate"),
                        "uplink": leaf(sta, "LastDataUplinkRate"),
                        "bytes_sent": leaf(sta, "BytesSent"),
                        "bytes_received": leaf(sta, "BytesReceived"),
                    }

                    previous = candidates.get(client_mac)

                    if (
                        previous is None
                        or candidate["timestamp"] >= previous["timestamp"]
                    ):
                        candidates[client_mac] = candidate

    for client_mac, client in candidates.items():
        host = host_map.get(client_mac, {})

        labels = {
            "client_mac": client_mac,
            "hostname": host.get("hostname", ""),
            "ip": host.get("ip", ""),
            "node": client["node"],
            "node_mac": client["node_mac"],
            "radio": client["radio_index"],
            "bss": client["bss_index"],
        }

        add_metric(
            lines,
            "easymesh_client_connected",
            1,
            labels
        )

        add_metric(
            lines,
            "easymesh_client_signal_strength",
            client["signal"],
            labels
        )

        add_metric(
            lines,
            "easymesh_client_downlink_rate_mbps",
            client["downlink"],
            labels
        )

        add_metric(
            lines,
            "easymesh_client_uplink_rate_mbps",
            client["uplink"],
            labels
        )

        add_metric(
            lines,
            "easymesh_client_bytes_sent_total",
            client["bytes_sent"],
            labels
        )

        add_metric(
            lines,
            "easymesh_client_bytes_received_total",
            client["bytes_received"],
            labels
        )

    add_metric(
        lines,
        "easymesh_exporter_scrape_timestamp_seconds",
        int(time.time())
    )

    return "\n".join(lines) + "\n"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path not in ["/", "/metrics"]:
            self.send_response(404)
            self.end_headers()
            return

        try:
            body = build_metrics()
        except Exception as exc:
            body = (
                "# TYPE genieacs_up gauge\n"
                "genieacs_up 0\n"
                f'exporter_error_info{{message="{escape_label(exc)}"}} 1\n'
            )

        encoded = body.encode("utf-8")

        self.send_response(200)
        self.send_header(
            "Content-Type",
            "text/plain; version=0.0.4; charset=utf-8"
        )
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def log_message(self, *_):
        return


if __name__ == "__main__":
    print(f"HX141 exporter listening on :{EXPORTER_PORT}")

    HTTPServer(
        ("0.0.0.0", EXPORTER_PORT),
        Handler
    ).serve_forever()
