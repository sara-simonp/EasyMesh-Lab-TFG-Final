from pathlib import Path

path = Path("simulator/easymesh-network-simulator/app.py")
text = path.read_text(encoding="utf-8")

marker = '    di = state["device_info"]\n'
insert = r'''
    # Additional root objects aligned with TelcoX BulkData payload.
    # This does not implement a real TR-232/TR-369 HTTP POST agent.
    # It exposes the BulkData profile configuration and extra TR-181 branches
    # inside the CSV payload used by the lab.
    for obj in [
        "Device.BulkData",
        "Device.BulkData.Profile",
        "Device.BulkData.Profile.1",
        "Device.BulkData.Profile.1.HTTP",
        "Device.BulkData.Profile.1.HTTP.RequestURIParameter",
        "Device.BulkData.Profile.1.JSONEncoding",
        "Device.BulkData.Profile.1.Parameter",
        "Device.ManagementServer",
        "Device.Firewall",
        "Device.WiFi.SSID",
        "Device.WiFi.Radio",
        "Device.Ethernet",
        "Device.Ethernet.Interface",
        "Device.IP",
        "Device.IP.Interface",
    ]:
        csv_write_object(rows, obj)

'''
if insert.strip() not in text:
    text = text.replace(marker, insert + marker)

marker = '    csv_write_param(rows, "Device.DeviceInfo.ProcessStatus.CPUUsage", di["cpu_usage_percent"], "xsd:unsignedInt")\n'
insert = r'''
    # Extra DeviceInfo fields expected by the TelcoX BulkData profile.
    csv_write_param(rows, "Device.DeviceInfo.Description", "EasyMesh telemetry simulator for QoE lab", "xsd:string")
    csv_write_param(rows, "Device.RootDataModelVersion", "2.20", "xsd:string")
    csv_write_param(rows, "Device.DeviceInfo.HardwareVersion", "virtual-1", "xsd:string")
    csv_write_param(rows, "Device.DeviceInfo.ModelName", "EasyMeshVirtualCPE", "xsd:string")
    csv_write_param(rows, "Device.ManagementServer.ConnectionRequestURL", "http://tr069-sim:7547/", "xsd:string")

    # Simulated BulkData global configuration and Profile.1.
    csv_write_param(rows, "Device.BulkData.Enable", "true", "xsd:boolean")
    csv_write_param(rows, "Device.BulkData.ProfileNumberOfEntries", 1, "xsd:unsignedInt")

    bulk_profile = "Device.BulkData.Profile.1"
    bulk_http = bulk_profile + ".HTTP"
    bulk_json = bulk_profile + ".JSONEncoding"

    bulkdata_values = [
        (bulk_profile + ".Alias", "StatusDeviceRadio", "xsd:string"),
        (bulk_profile + ".Name", "StatusDeviceRadio", "xsd:string"),
        (bulk_profile + ".Enable", "true", "xsd:boolean"),
        (bulk_profile + ".Protocol", "HTTP", "xsd:string"),
        (bulk_profile + ".EncodingType", "JSON", "xsd:string"),
        (bulk_profile + ".ReportingInterval", 3600, "xsd:unsignedInt"),
        (bulk_profile + ".TimeReference", "0001-01-01T00:00:00Z", "xsd:dateTime"),
        (bulk_http + ".Method", "POST", "xsd:string"),
        (bulk_http + ".URL", os.environ.get("BULKDATA_HTTP_URL", "http://collector.local/bulkdata"), "xsd:string"),
        (bulk_http + ".UseDateHeader", "true", "xsd:boolean"),
        (bulk_http + ".Username", "", "xsd:string"),
        (bulk_http + ".Password", "", "xsd:string"),
        (bulk_http + ".Compression", "None", "xsd:string"),
        (bulk_http + ".CompressionsSupported", "None,GZIP", "xsd:string"),
        (bulk_http + ".MethodsSupported", "POST", "xsd:string"),
        (bulk_json + ".ReportFormat", "NameValuePair", "xsd:string"),
        (bulk_json + ".ReportTimestamp", "Unix-Epoch", "xsd:string"),
    ]
    for p, v, t in bulkdata_values:
        csv_write_param(rows, p, v, t)

    bulk_refs = [
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
        "Device.DeviceInfo.SoftwareVersion",
    ]
    for idx, ref in enumerate(bulk_refs, start=1):
        pbase = f"Device.BulkData.Profile.1.Parameter.{idx}"
        csv_write_object(rows, pbase)
        csv_write_param(rows, f"{pbase}.Reference", ref, "xsd:string")

    # Extra generic CPE branches requested by the TelcoX BulkData profile.
    csv_write_param(rows, "Device.WiFi.X_TPG_BandSteering.Enable", "true", "xsd:boolean")
    csv_write_param(rows, "Device.Firewall.Enable", "true", "xsd:boolean")

    # Simulated SSID table.
    for ssid_i, ssid_name, lower in [
        (1, "SaraMesh-24G", "Device.WiFi.Radio.1"),
        (2, "SaraMesh-5G", "Device.WiFi.Radio.2"),
    ]:
        sbase = f"Device.WiFi.SSID.{ssid_i}"
        csv_write_object(rows, sbase)
        csv_write_param(rows, f"{sbase}.Enable", "true", "xsd:boolean")
        csv_write_param(rows, f"{sbase}.Status", "Up", "xsd:string")
        csv_write_param(rows, f"{sbase}.SSID", ssid_name, "xsd:string")
        csv_write_param(rows, f"{sbase}.LowerLayers", lower, "xsd:string")

    # Simulated Ethernet, IP and Firewall support.
    total_bytes_sent = sum(r["bytes_sent"] for ap in state["aps"].values() for r in ap["radios"])
    total_bytes_received = sum(r["bytes_received"] for ap in state["aps"].values() for r in ap["radios"])
    total_packets_sent = sum(r["packets_sent"] for ap in state["aps"].values() for r in ap["radios"])
    total_packets_received = sum(r["packets_received"] for ap in state["aps"].values() for r in ap["radios"])

    for eth_i, name, mac, upstream in [
        (1, "eth0", "AA:BB:CC:EE:00:01", "true"),
        (2, "lan0", "AA:BB:CC:EE:00:02", "false"),
    ]:
        ebase = f"Device.Ethernet.Interface.{eth_i}"
        csv_write_object(rows, ebase)
        csv_write_param(rows, f"{ebase}.Enable", "true", "xsd:boolean")
        csv_write_param(rows, f"{ebase}.Status", "Up", "xsd:string")
        csv_write_param(rows, f"{ebase}.DuplexMode", "Full", "xsd:string")
        csv_write_param(rows, f"{ebase}.MACAddress", mac, "xsd:string")
        csv_write_param(rows, f"{ebase}.Name", name, "xsd:string")
        csv_write_param(rows, f"{ebase}.Upstream", upstream, "xsd:boolean")
        csv_write_object(rows, f"{ebase}.Stats")
        csv_write_param(rows, f"{ebase}.Stats.BytesReceived", total_bytes_received, "xsd:unsignedLong")
        csv_write_param(rows, f"{ebase}.Stats.BytesSent", total_bytes_sent, "xsd:unsignedLong")
        csv_write_param(rows, f"{ebase}.Stats.ErrorsReceived", 0, "xsd:unsignedLong")
        csv_write_param(rows, f"{ebase}.Stats.ErrorsSent", 0, "xsd:unsignedLong")
        csv_write_param(rows, f"{ebase}.Stats.PacketsReceived", total_packets_received, "xsd:unsignedLong")
        csv_write_param(rows, f"{ebase}.Stats.PacketsSent", total_packets_sent, "xsd:unsignedLong")

    for ip_i, alias, lower, address, subnet in [
        (1, "lan", "Device.Ethernet.Interface.2", "192.168.1.1", "255.255.255.0"),
        (2, "management", "Device.Ethernet.Interface.1", state["controller"]["ipv4"], "255.255.255.0"),
    ]:
        ibase = f"Device.IP.Interface.{ip_i}"
        csv_write_object(rows, ibase)
        csv_write_param(rows, f"{ibase}.Alias", alias, "xsd:string")
        csv_write_param(rows, f"{ibase}.Enable", "true", "xsd:boolean")
        csv_write_param(rows, f"{ibase}.Status", "Up", "xsd:string")
        csv_write_param(rows, f"{ibase}.IPv4Enable", "true", "xsd:boolean")
        csv_write_param(rows, f"{ibase}.IPv6Enable", "false", "xsd:boolean")
        csv_write_param(rows, f"{ibase}.LowerLayers", lower, "xsd:string")
        csv_write_object(rows, f"{ibase}.IPv4Address")
        csv_write_object(rows, f"{ibase}.IPv4Address.1")
        csv_write_param(rows, f"{ibase}.IPv4Address.1.AddressingType", "Static", "xsd:string")
        csv_write_param(rows, f"{ibase}.IPv4Address.1.Enable", "true", "xsd:boolean")
        csv_write_param(rows, f"{ibase}.IPv4Address.1.IPAddress", address, "xsd:string")
        csv_write_param(rows, f"{ibase}.IPv4Address.1.Status", "Enabled", "xsd:string")
        csv_write_param(rows, f"{ibase}.IPv4Address.1.SubnetMask", subnet, "xsd:string")
        csv_write_object(rows, f"{ibase}.Stats")
        csv_write_param(rows, f"{ibase}.Stats.BytesReceived", total_bytes_received, "xsd:unsignedLong")
        csv_write_param(rows, f"{ibase}.Stats.BytesSent", total_bytes_sent, "xsd:unsignedLong")
        csv_write_param(rows, f"{ibase}.Stats.ErrorsReceived", 0, "xsd:unsignedLong")
        csv_write_param(rows, f"{ibase}.Stats.ErrorsSent", 0, "xsd:unsignedLong")
        csv_write_param(rows, f"{ibase}.Stats.PacketsReceived", total_packets_received, "xsd:unsignedLong")
        csv_write_param(rows, f"{ibase}.Stats.PacketsSent", total_packets_sent, "xsd:unsignedLong")

'''
if insert.strip() not in text:
    text = text.replace(marker, marker + insert)

marker = '    host_i = 1\n    ap_i = 1\n'
replacement = '    host_i = 1\n    ap_i = 1\n    wifi_radio_i = 1\n'
if replacement not in text:
    text = text.replace(marker, replacement)

marker = '        csv_write_param(rows, f"{ap_base}.Status", "Enabled" if ap["status"] == "Online" else "Disabled", "xsd:string")\n'
insert = '        csv_write_param(rows, f"{ap_base}.Enable", "true" if ap["status"] == "Online" else "false", "xsd:boolean")\n'
if insert.strip() not in text:
    text = text.replace(marker, marker + insert)

marker = '                csv_write_param(rows, f"{base_x}.Radio.{rid}.Stats.{p}", v, "xsd:unsignedLong")\n'
insert = r'''            # Direct Device.WiFi.Radio mapping requested by the TelcoX BulkData profile.
            direct_radio = f"Device.WiFi.Radio.{wifi_radio_i}"
            csv_write_object(rows, direct_radio)
            csv_write_param(rows, f"{direct_radio}.Enable", "true" if radio["status"] == "Up" else "false", "xsd:boolean")
            csv_write_param(rows, f"{direct_radio}.Status", radio["status"], "xsd:string")
            csv_write_param(rows, f"{direct_radio}.Alias", f"{ap_name}_{radio['name']}", "xsd:string")
            csv_write_param(rows, f"{direct_radio}.Name", radio["name"], "xsd:string")
            csv_write_param(rows, f"{direct_radio}.LowerLayers", "", "xsd:string")
            csv_write_param(rows, f"{direct_radio}.Channel", radio["channel"], "xsd:unsignedInt")
            csv_write_param(rows, f"{direct_radio}.OperatingChannelBandwidth", radio["bandwidth"], "xsd:string")
            csv_write_param(rows, f"{direct_radio}.OperatingFrequencyBand", radio["band"], "xsd:string")
            csv_write_param(rows, f"{direct_radio}.CurrentOperatingChannelBandwidth", radio["bandwidth"], "xsd:string")
            csv_write_param(rows, f"{direct_radio}.OperatingStandards", radio["standard"], "xsd:string")
            csv_write_param(rows, f"{direct_radio}.SupportedStandards", "802.11n,802.11ac,802.11ax", "xsd:string")
            csv_write_param(rows, f"{direct_radio}.TransmitPower", radio["tx_power_dbm"], "xsd:int")
            csv_write_object(rows, f"{direct_radio}.Stats")
            for p2, v2 in [
                ("BytesSent", radio["bytes_sent"]),
                ("BytesReceived", radio["bytes_received"]),
                ("PacketsSent", radio["packets_sent"]),
                ("PacketsReceived", radio["packets_received"]),
                ("ErrorsSent", radio["errors_sent"]),
                ("ErrorsReceived", radio["errors_received"]),
            ]:
                csv_write_param(rows, f"{direct_radio}.Stats.{p2}", v2, "xsd:unsignedLong")
            wifi_radio_i += 1

            # DataElements BSS/STA mapping requested by the TelcoX BulkData profile.
            bss_base = f"{base_de}.Radio.{rid}.BSS.1"
            csv_write_object(rows, f"{base_de}.Radio.{rid}.BSS")
            csv_write_object(rows, bss_base)
            clients_on_radio = [client for client in ap["clients"] if client["connected_radio"] == radio["name"]]
            csv_write_param(rows, f"{bss_base}.BSSID", ap["mac"], "xsd:string")
            csv_write_param(rows, f"{bss_base}.SSID", "SaraMesh-5G" if radio["band"] == "5GHz" else "SaraMesh-24G", "xsd:string")
            csv_write_param(rows, f"{bss_base}.STANumberOfEntries", len(clients_on_radio), "xsd:unsignedInt")
            csv_write_object(rows, f"{bss_base}.STA")
            for sta_i, client in enumerate(clients_on_radio, start=1):
                sta_base = f"{bss_base}.STA.{sta_i}"
                csv_write_object(rows, sta_base)
                csv_write_param(rows, f"{sta_base}.MACAddress", client["mac"], "xsd:string")
                csv_write_param(rows, f"{sta_base}.BytesSent", client["bytes_sent"], "xsd:unsignedLong")
                csv_write_param(rows, f"{sta_base}.BytesReceived", client["bytes_received"], "xsd:unsignedLong")
                csv_write_param(rows, f"{sta_base}.LastConnectTime", client["last_connect_time"], "xsd:string")
                csv_write_param(rows, f"{sta_base}.LastDataDownlinkRate", client["last_data_downlink_rate_mbps"], "xsd:unsignedInt")
                csv_write_param(rows, f"{sta_base}.LastDataUplinkRate", client["last_data_uplink_rate_mbps"], "xsd:unsignedInt")
                csv_write_param(rows, f"{sta_base}.EstMACDataRateDownlink", client["throughput_downlink_mbps"], "xsd:decimal")
                csv_write_param(rows, f"{sta_base}.EstMACDataRateUplink", client["throughput_uplink_mbps"], "xsd:decimal")
'''
if insert.strip() not in text:
    text = text.replace(marker, marker + insert)

path.write_text(text, encoding="utf-8")
print("OK - app.py patched with TelcoX BulkData/TR-181 mappings")
