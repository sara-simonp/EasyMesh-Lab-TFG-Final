#!/usr/bin/env python3
"""
Patch TelcoX strict TR-181 export for EasyMesh Lab.

What it does:
- Keeps the simulator and Prometheus path untouched.
- Filters the TR-181 CSV used by tr069-sim/GenieACS.
- In strict mode, only Device.BulkData configuration plus the 85 TelcoX referenced
  TR-181 parameters are exported.
- Custom lab-only branches such as InternetGatewayDevice.X_SARA_EasyMesh and
  Device.X_SARA_QoE are left out of the ACS/TR-069 CSV.

Run from repository root:
  python tools/patches/patch_telcox_strict_export.py

Disable strict CSV filtering at runtime:
  TR181_EXPORT_PROFILE=lab_full
"""

from pathlib import Path
import shutil

APP = Path("simulator/easymesh-network-simulator/app.py")

TELCOX_REFS = [
    "Device.DeviceInfo.Description",
    "Device.RootDataModelVersion",
    "Device.WiFi.X_TPG_BandSteering.Enable",
    "Device.WiFi.SSID.*.SSID",
    "Device.WiFi.SSID.*.LowerLayers",
    "Device.WiFi.Radio.*.Enable",
    "Device.WiFi.Radio.*.Status",
    "Device.DeviceInfo.Manufacturer",
    "Device.DeviceInfo.UpTime",
    "Device.WiFi.Radio.*.Channel",
    "Device.WiFi.Radio.*.OperatingChannelBandwidth",
    "Device.WiFi.Radio.*.OperatingFrequencyBand",
    "Device.WiFi.Radio.*.CurrentOperatingChannelBandwidth",
    "Device.WiFi.Radio.*.OperatingStandards",
    "Device.WiFi.Radio.*.TransmitPower",
    "Device.ManagementServer.ConnectionRequestURL",
    "Device.WiFi.Radio.*.SupportedStandards",
    "Device.WiFi.DataElements.Network.Device.*.Radio.*.Noise",
    "Device.WiFi.DataElements.Network.Device.*.Radio.*.Utilization",
    "Device.WiFi.AccessPoint.*.Status",
    "Device.WiFi.AccessPoint.*.AssociatedDevice.*.Stats.RetryCount",
    "Device.WiFi.AccessPoint.*.AssociatedDevice.*.SignalStrength",
    "Device.WiFi.AccessPoint.*.SSIDReference",
    "Device.WiFi.AccessPoint.*.AssociatedDevice.*.MACAddress",
    "Device.WiFi.AccessPoint.*.AssociatedDevice.*.LastDataDownlinkRate",
    "Device.WiFi.AccessPoint.*.AssociatedDevice.*.LastDataUplinkRate",
    "Device.WiFi.AccessPoint.*.Enable",
    "Device.WiFi.AccessPoint.*.AssociatedDevice.*.OperatingStandard",
    "Device.WiFi.Radio.*.Stats.",
    "Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STANumberOfEntries",
    "Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.MACAddress",
    "Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.BSSID",
    "Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.BytesSent",
    "Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.BytesReceived",
    "Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.LastConnectTime",
    "Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.SSID",
    "Device.Hosts.Host.*.PhysAddress",
    "Device.Hosts.Host.*.IPAddress",
    "Device.Hosts.Host.*.ClientID",
    "Device.Hosts.Host.*.HostName",
    "Device.Hosts.Host.*.Active",
    "Device.Hosts.Host.*.InterfaceType",
    "Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.LastDataDownlinkRate",
    "Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.LastDataUplinkRate",
    "Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.EstMACDataRateDownlink",
    "Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.EstMACDataRateUplink",
    "Device.Firewall.Enable",
    "Device.Ethernet.Interface.*.DuplexMode",
    "Device.Ethernet.Interface.*.Enable",
    "Device.Ethernet.Interface.1.MACAddress",
    "Device.Ethernet.Interface.1.Name",
    "Device.Ethernet.Interface.*.Stats.BytesReceived",
    "Device.Ethernet.Interface.*.Stats.BytesSent",
    "Device.Ethernet.Interface.*.Stats.ErrorsReceived",
    "Device.Ethernet.Interface.*.Stats.ErrorsSent",
    "Device.Ethernet.Interface.*.Stats.PacketsReceived",
    "Device.Ethernet.Interface.*.Stats.PacketsSent",
    "Device.Ethernet.Interface.*.Status",
    "Device.Ethernet.Interface.*.Upstream",
    "Device.IP.Interface.*.Alias",
    "Device.IP.Interface.*.Enable",
    "Device.IP.Interface.*.IPv4Address.*.AddressingType",
    "Device.IP.Interface.*.IPv4Address.*.Enable",
    "Device.IP.Interface.*.IPv4Address.*.IPAddress",
    "Device.IP.Interface.*.IPv4Address.*.Status",
    "Device.IP.Interface.*.IPv4Address.*.SubnetMask",
    "Device.IP.Interface.*.IPv4Enable",
    "Device.IP.Interface.*.IPv6Enable",
    "Device.IP.Interface.*.LowerLayers",
    "Device.IP.Interface.*.Status",
    "Device.IP.Interface.*.Stats.BytesReceived",
    "Device.IP.Interface.*.Stats.BytesSent",
    "Device.IP.Interface.*.Stats.ErrorsReceived",
    "Device.IP.Interface.*.Stats.ErrorsSent",
    "Device.IP.Interface.*.Stats.PacketsReceived",
    "Device.IP.Interface.*.Stats.PacketsSent",
    "Device.DeviceInfo.MemoryStatus.Free",
    "Device.DeviceInfo.MemoryStatus.Total",
    "Device.DeviceInfo.HardwareVersion",
    "Device.DeviceInfo.ManufacturerOUI",
    "Device.DeviceInfo.ModelName",
    "Device.DeviceInfo.ProductClass",
    "Device.DeviceInfo.ProcessStatus.CPUUsage",
    "Device.DeviceInfo.SerialNumber",
    "Device.DeviceInfo.SoftwareVersion"
]

HELPER = r"""
TELCOX_BULKDATA_REFERENCES = """ + repr(TELCOX_REFS) + r"""

def _telcox_normalize_path(path: str) -> str:
    parts = path.split(".")
    return ".".join("*" if p.isdigit() else p for p in parts)

def _telcox_allowed_param(path: str) -> bool:
    # Always keep BulkData profile configuration itself. It declares what is collected.
    if path == "Device.BulkData" or path.startswith("Device.BulkData."):
        return True

    n = _telcox_normalize_path(path)
    for ref in TELCOX_BULKDATA_REFERENCES:
        r = ref.rstrip(".")
        if ref.endswith("."):
            if n == r or n.startswith(r + "."):
                return True
        elif n == ref:
            return True
    return False

def _telcox_allowed_object(path: str) -> bool:
    # Keep object rows needed to reach allowed parameters.
    if path == "Device" or path.startswith("Device.BulkData"):
        return True

    n = _telcox_normalize_path(path)
    for ref in TELCOX_BULKDATA_REFERENCES:
        r = ref.rstrip(".")
        if n == r or r.startswith(n + ".") or n.startswith(r + "."):
            return True
    return False

def filter_telcox_strict_rows(rows: List[List[str]]) -> List[List[str]]:
    profile = os.environ.get("TR181_EXPORT_PROFILE", "telcox_strict").lower()
    if profile not in ("telcox", "telcox_strict", "strict"):
        return rows

    filtered: List[List[str]] = []
    for row in rows:
        path = row[0]
        is_object = row[1] == "true"
        if is_object:
            if _telcox_allowed_object(path):
                filtered.append(row)
        else:
            if _telcox_allowed_param(path):
                filtered.append(row)
    return filtered

"""

def main() -> None:
    if not APP.exists():
        raise SystemExit(f"No existe {APP}. Ejecuta este script desde C:\\EasyMesh-Lab")

    text = APP.read_text(encoding="utf-8")

    if "TELCOX_BULKDATA_REFERENCES" not in text:
        marker = "def write_tr181_csv(state: Dict[str, Any]) -> None:\n"
        if marker not in text:
            raise SystemExit("No se encontro el marcador write_tr181_csv.")
        text = text.replace(marker, HELPER + "\n\n" + marker, 1)

    if "rows = filter_telcox_strict_rows(rows)" not in text:
        marker = "    tmp = CSV_FILE + \".tmp\"\n"
        if marker not in text:
            raise SystemExit("No se encontro el marcador de escritura CSV.")
        text = text.replace(marker, "    rows = filter_telcox_strict_rows(rows)\n\n" + marker, 1)

    backup = APP.with_suffix(".py.bak_telcox_strict")
    if not backup.exists():
        shutil.copy2(APP, backup)

    APP.write_text(text, encoding="utf-8")
    print("OK: app.py parcheado en modo TelcoX estricto.")
    print(f"Backup: {backup}")
    print("TR-069/GenieACS recibira solo Device.BulkData + parametros TelcoX permitidos.")
    print("Para desactivar temporalmente: TR181_EXPORT_PROFILE=lab_full")

if __name__ == "__main__":
    main()

