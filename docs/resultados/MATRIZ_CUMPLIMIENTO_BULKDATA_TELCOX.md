# Matriz de cumplimiento BulkData TelcoX

Este documento compara el perfil de metricas indicado en el documento "IOMetrics TelcoX - BulkData Functional Overview" con la telemetria generada por el simulador EasyMesh-Lab.

---

## 1. Objetivo

El objetivo es comprobar si el simulador genera las ramas y parametros necesarios para aproximarse al payload BulkData TelcoX.

El laboratorio actual no ejecuta un agente BulkData real sobre un CPE fisico. En su lugar, genera un CSV estructurado con parametros TR-181/DataElements que representa el payload de telemetria.

---

## 2. Alcance

La ampliacion del simulador cubre:

- Device.BulkData
- Device.BulkData.Profile.1
- Device.BulkData.Profile.1.HTTP
- Device.BulkData.Profile.1.JSONEncoding
- Device.BulkData.Profile.1.Parameter.*.Reference
- Device.DeviceInfo
- Device.WiFi.SSID
- Device.WiFi.Radio
- Device.WiFi.AccessPoint
- Device.WiFi.AccessPoint.*.AssociatedDevice
- Device.WiFi.DataElements.Network
- Device.WiFi.DataElements.Network.Device.*.Radio
- Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS
- Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA
- Device.Hosts.Host
- Device.Firewall
- Device.Ethernet.Interface
- Device.IP.Interface
- Device.X_SARA_QoE
- InternetGatewayDevice.X_SARA_EasyMesh

---

## 3. Matriz de cumplimiento

| Bloque solicitado | Estado | Implementacion en EasyMesh-Lab |
|---|---|---|
| Device.BulkData.Enable | OK | Device.BulkData.Enable = true |
| Device.BulkData.Profile.1.Alias | OK | StatusDeviceRadio |
| Device.BulkData.Profile.1.Name | OK | StatusDeviceRadio |
| Device.BulkData.Profile.1.Enable | OK | true |
| Device.BulkData.Profile.1.Protocol | OK | HTTP |
| Device.BulkData.Profile.1.EncodingType | OK | JSON |
| Device.BulkData.Profile.1.ReportingInterval | OK | 3600 |
| Device.BulkData.Profile.1.TimeReference | OK | 0001-01-01T00:00:00Z |
| Device.BulkData.Profile.1.HTTP.Method | OK simulado | POST |
| Device.BulkData.Profile.1.HTTP.URL | OK simulado | http://collector.local/bulkdata o BULKDATA_HTTP_URL |
| Device.BulkData.Profile.1.HTTP.UseDateHeader | OK | true |
| Device.BulkData.Profile.1.HTTP.Username | OK | vacio |
| Device.BulkData.Profile.1.HTTP.Password | OK | vacio |
| Device.BulkData.Profile.1.HTTP.Compression | OK | None |
| Device.BulkData.Profile.1.HTTP.CompressionsSupported | OK | None,GZIP |
| Device.BulkData.Profile.1.HTTP.MethodsSupported | OK | POST |
| Device.BulkData.Profile.1.JSONEncoding.ReportFormat | OK | NameValuePair |
| Device.BulkData.Profile.1.JSONEncoding.ReportTimestamp | OK | Unix-Epoch |
| Device.BulkData.Profile.1.Parameter.*.Reference | OK | 85 referencias |

---

## 4. Cumplimiento DeviceInfo

| Parametro | Estado | Comentario |
|---|---|---|
| Device.DeviceInfo.Description | OK | Descripcion del simulador |
| Device.RootDataModelVersion | OK | 2.20 |
| Device.DeviceInfo.Manufacturer | OK | Sara-Lab |
| Device.DeviceInfo.ManufacturerOUI | OK | 535241 |
| Device.DeviceInfo.ProductClass | OK | EasyMeshVirtualCPE |
| Device.DeviceInfo.SerialNumber | OK | 200001 |
| Device.DeviceInfo.SoftwareVersion | OK | EasyMeshNetworkSimulator |
| Device.DeviceInfo.HardwareVersion | OK | virtual-1 |
| Device.DeviceInfo.ModelName | OK | EasyMeshVirtualCPE |
| Device.DeviceInfo.UpTime | OK | uptime del simulador |
| Device.DeviceInfo.MemoryStatus.Free | OK | memoria libre simulada |
| Device.DeviceInfo.MemoryStatus.Total | OK | memoria total simulada |
| Device.DeviceInfo.ProcessStatus.CPUUsage | OK | CPU simulada |

---

## 5. Cumplimiento WiFi

| Parametro | Estado | Comentario |
|---|---|---|
| Device.WiFi.X_TPG_BandSteering.Enable | OK simulado | true |
| Device.WiFi.SSID.*.SSID | OK | SaraMesh-24G / SaraMesh-5G |
| Device.WiFi.SSID.*.LowerLayers | OK | Referencia a Device.WiFi.Radio |
| Device.WiFi.Radio.*.Enable | OK | true o false segun estado |
| Device.WiFi.Radio.*.Status | OK | Up o Down |
| Device.WiFi.Radio.*.Channel | OK | Canal radio simulado |
| Device.WiFi.Radio.*.OperatingChannelBandwidth | OK | 40MHz / 80MHz |
| Device.WiFi.Radio.*.OperatingFrequencyBand | OK | 2.4GHz / 5GHz |
| Device.WiFi.Radio.*.CurrentOperatingChannelBandwidth | OK | 40MHz / 80MHz |
| Device.WiFi.Radio.*.OperatingStandards | OK | 802.11n/ax o 802.11ac/ax |
| Device.WiFi.Radio.*.SupportedStandards | OK | 802.11n,802.11ac,802.11ax |
| Device.WiFi.Radio.*.TransmitPower | OK | potencia simulada |
| Device.WiFi.Radio.*.Stats.BytesSent | OK | contador simulado |
| Device.WiFi.Radio.*.Stats.BytesReceived | OK | contador simulado |
| Device.WiFi.Radio.*.Stats.ErrorsSent | OK | contador simulado |
| Device.WiFi.Radio.*.Stats.ErrorsReceived | OK | contador simulado |
| Device.WiFi.Radio.*.Stats.PacketsSent | OK | contador simulado |
| Device.WiFi.Radio.*.Stats.PacketsReceived | OK | contador simulado |

---

## 6. Cumplimiento AccessPoint y clientes asociados

| Parametro | Estado | Comentario |
|---|---|---|
| Device.WiFi.AccessPoint.*.Status | OK | Enabled / Disabled |
| Device.WiFi.AccessPoint.*.Enable | OK | true / false |
| Device.WiFi.AccessPoint.*.SSIDReference | OK | Referencia a SSID |
| Device.WiFi.AccessPoint.*.AssociatedDevice.*.MACAddress | OK | MAC cliente |
| Device.WiFi.AccessPoint.*.AssociatedDevice.*.SignalStrength | OK | RSSI cliente |
| Device.WiFi.AccessPoint.*.AssociatedDevice.*.LastDataDownlinkRate | OK | tasa bajada |
| Device.WiFi.AccessPoint.*.AssociatedDevice.*.LastDataUplinkRate | OK | tasa subida |
| Device.WiFi.AccessPoint.*.AssociatedDevice.*.OperatingStandard | OK | 802.11ax |
| Device.WiFi.AccessPoint.*.AssociatedDevice.*.Stats.RetryCount | OK | retry count estimado |

---

## 7. Cumplimiento DataElements

| Parametro | Estado | Comentario |
|---|---|---|
| Device.WiFi.DataElements.Network.Controller | OK | controlador EasyMesh |
| Device.WiFi.DataElements.Network.Device.* | OK | gateway y satelite |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.Noise | OK | ruido radio |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.Utilization | OK | utilizacion radio |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STANumberOfEntries | OK | numero de STA |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.BSSID | OK | BSSID |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.SSID | OK | SSID |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.MACAddress | OK | MAC cliente |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.BytesSent | OK | bytes enviados |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.BytesReceived | OK | bytes recibidos |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.LastConnectTime | OK | timestamp |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.LastDataDownlinkRate | OK | tasa bajada |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.LastDataUplinkRate | OK | tasa subida |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.EstMACDataRateDownlink | OK | throughput estimado |
| Device.WiFi.DataElements.Network.Device.*.Radio.*.BSS.*.STA.*.EstMACDataRateUplink | OK | throughput estimado |

---

## 8. Cumplimiento Hosts

| Parametro | Estado | Comentario |
|---|---|---|
| Device.Hosts.Host.*.PhysAddress | OK | MAC cliente |
| Device.Hosts.Host.*.IPAddress | OK | IP cliente |
| Device.Hosts.Host.*.ClientID | OK | MAC cliente |
| Device.Hosts.Host.*.HostName | OK | nombre cliente |
| Device.Hosts.Host.*.Active | OK | true / false |
| Device.Hosts.Host.*.InterfaceType | OK | Wi-Fi |

---

## 9. Cumplimiento Firewall, Ethernet e IP

| Parametro | Estado | Comentario |
|---|---|---|
| Device.Firewall.Enable | OK simulado | true |
| Device.Ethernet.Interface.*.Enable | OK simulado | true |
| Device.Ethernet.Interface.*.Status | OK simulado | Up |
| Device.Ethernet.Interface.*.DuplexMode | OK simulado | Full |
| Device.Ethernet.Interface.*.MACAddress | OK simulado | MAC virtual |
| Device.Ethernet.Interface.*.Name | OK simulado | eth0 / lan0 |
| Device.Ethernet.Interface.*.Upstream | OK simulado | true / false |
| Device.Ethernet.Interface.*.Stats.BytesReceived | OK simulado | contador agregado |
| Device.Ethernet.Interface.*.Stats.BytesSent | OK simulado | contador agregado |
| Device.Ethernet.Interface.*.Stats.ErrorsReceived | OK simulado | 0 |
| Device.Ethernet.Interface.*.Stats.ErrorsSent | OK simulado | 0 |
| Device.Ethernet.Interface.*.Stats.PacketsReceived | OK simulado | contador agregado |
| Device.Ethernet.Interface.*.Stats.PacketsSent | OK simulado | contador agregado |
| Device.IP.Interface.*.Alias | OK simulado | lan / management |
| Device.IP.Interface.*.Enable | OK simulado | true |
| Device.IP.Interface.*.Status | OK simulado | Up |
| Device.IP.Interface.*.IPv4Enable | OK simulado | true |
| Device.IP.Interface.*.IPv6Enable | OK simulado | false |
| Device.IP.Interface.*.LowerLayers | OK simulado | referencia Ethernet |
| Device.IP.Interface.*.IPv4Address.*.IPAddress | OK simulado | 192.168.1.1 / 172.25.0.40 |
| Device.IP.Interface.*.IPv4Address.*.SubnetMask | OK simulado | 255.255.255.0 |
| Device.IP.Interface.*.Stats.BytesReceived | OK simulado | contador agregado |
| Device.IP.Interface.*.Stats.BytesSent | OK simulado | contador agregado |

---

## 10. Metricas adicionales del TFG

Ademas de las metricas solicitadas por TelcoX, el simulador genera metricas especificas para el analisis de QoE en EasyMesh:

| Rama | Uso |
|---|---|
| Device.X_SARA_QoE.SignalStrength | RSSI resumido de MOVIL_SARA |
| Device.X_SARA_QoE.LatencyMs | latencia resumida |
| Device.X_SARA_QoE.PacketLossPercent | perdida resumida |
| Device.X_SARA_QoE.QoEScore | puntuacion QoE |
| Device.X_SARA_QoE.QoEState | estado QoE |
| Device.X_SARA_QoE.Reason | motivo de degradacion |
| Device.WiFi.DataElements.Network.Event.1.Type | tipo de evento |
| Device.WiFi.DataElements.Network.Event.1.ClientMAC | cliente afectado |
| Device.WiFi.DataElements.Network.Event.1.FromDevice | AP origen |
| Device.WiFi.DataElements.Network.Event.1.ToDevice | AP destino |
| Device.WiFi.DataElements.Network.Event.1.SteeringCount | numero de steerings |
| Device.WiFi.DataElements.Network.Device.*.BackhaulRSSI | RSSI backhaul |
| Device.WiFi.DataElements.Network.Device.*.BackhaulLatencyMs | latencia backhaul |
| Device.WiFi.DataElements.Network.Device.*.BackhaulPacketLossPercent | perdida backhaul |

Estas metricas son necesarias para estudiar roaming, punto ciego de visibilidad, degradacion de backhaul y experiencia de cliente.

---

## 11. Limitaciones

Aunque la matriz queda cubierta a nivel funcional, existen limitaciones:

- No se ejecuta un POST HTTP real desde un CPE fisico.
- No existe un collector BulkData real recibiendo JSON.
- El perfil Device.BulkData se representa dentro del CSV del laboratorio.
- Las metricas de Ethernet, IP y Firewall son simuladas.
- Las metricas WiFi proceden de un modelo de simulacion, no de medidas radio reales.
- En dispositivos reales habra que comprobar que el firmware expone las mismas rutas TR-181.
- Algunos fabricantes pueden usar rutas propietarias tipo X_VENDOR.

---

## 12. Conclusion

El simulador EasyMesh-Lab queda alineado funcionalmente con el payload BulkData TelcoX a nivel de modelo de datos TR-181.

El laboratorio permite validar:

- seleccion de metricas;
- estructura del payload;
- referencias BulkData;
- telemetria WiFi;
- clientes asociados;
- hosts conectados;
- radio y AP;
- interfaces IP/Ethernet;
- eventos EasyMesh;
- QoE del cliente;
- pipeline Prometheus/Grafana.

La fase con dispositivos reales debera validar el soporte real de parametros TR-181 y la recoleccion mediante HTTP/POST hacia un collector BulkData.
